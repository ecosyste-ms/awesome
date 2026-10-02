require 'test_helper'

class ListSyncTest < ActionDispatch::IntegrationTest
  setup do
    Resolv.stubs(:getaddresses).with('github.com').returns(['93.184.216.34'])
    @list = create(:list, projects_count: 0, readme: nil, repository: {
      'html_url' => 'https://github.com/example/awesome',
      'default_branch' => 'main',
      'host' => { 'name' => 'GitHub' },
      'full_name' => 'example/awesome'
    })
    stub_request(:get, @list.url).to_return(status: 200)
    stub_request(:get, @list.repos_api_url).to_return(status: 200, body: @list.repository.to_json)
    stub_request(:get, @list.repos_ping_url).to_return(status: 200, body: '{}')
    @readme_url = @list.raw_url('README.md')
  end

  teardown do
    SyncProjectWorker.clear
    SyncListWorker.clear
  end

  test 'sync removes obsolete joins while retaining projects and other lists' do
    retained = create(:project, last_synced_at: Time.current)
    removed = create(:project, last_synced_at: Time.current)
    other_join = create(:list_project, project: removed)
    stub_request(:get, @readme_url).to_return(body: <<~README)
      ## Tools
      - [Retained](#{retained.url}) - Original description
      - [Removed](#{removed.url}) - Removed description
    README
    SyncListWorker.new.perform(@list.id)
    retained_join = @list.list_projects.find_by!(project: retained)
    assert_equal 2, @list.reload.projects_count
    assert_equal 2, @list.list_projects.count

    stub_request(:get, @readme_url).to_return(body: <<~README)
      ## Software
      ### Analysis
      - [Renamed](#{retained.url}#usage) - Updated description
      - [Added](https://github.com/example/new-project) - New description
    README
    SyncListWorker.new.perform(@list.id)

    assert_equal [retained.url, 'https://github.com/example/new-project'].sort, @list.projects.pluck(:url).sort
    assert_equal 2, @list.reload.projects_count
    assert_equal 2, @list.list_projects.count
    assert_equal ['Renamed', 'Updated description', 'Software', 'Analysis'],
      retained_join.reload.attributes.values_at('name', 'description', 'category', 'sub_category')
    assert Project.exists?(removed.id)
    assert ListProject.exists?(other_join.id)

    SyncListWorker.new.perform(@list.id)
    assert_equal 2, @list.list_projects.count
  end

  ['# Empty list', ''].each do |readme|
    test "sync removes all joins for a successfully fetched README #{readme.inspect}" do
      project = create(:project, last_synced_at: Time.current)
      create(:list_project, list: @list, project: project)
      stub_request(:get, @readme_url).to_return(body: readme)

      SyncListWorker.new.perform(@list.id)

      assert_empty @list.list_projects.reload
      assert_equal 0, @list.reload.projects_count
      assert Project.exists?(project.id)
    end
  end

  test 'sync preserves joins when no README is available' do
    join = create(:list_project, list: @list)
    stub_request(:get, @readme_url).to_return(status: 503)

    SyncListWorker.new.perform(@list.id)

    assert ListProject.exists?(join.id)
    assert_nil @list.reload.readme
  end

  test 'sync preserves current joins when the README fetch fails' do
    join = create(:list_project, list: @list, project: create(:project, last_synced_at: Time.current))
    @list.update!(readme: "- [Existing](#{join.project.url})\n", projects_count: 1)
    stub_request(:get, @readme_url).to_return(status: 503)

    SyncListWorker.new.perform(@list.id)

    assert_equal [join.id], @list.list_projects.pluck(:id)
    assert_equal 1, @list.reload.projects_count
  end

  test 'sync rolls back join changes if an update fails' do
    retained = create(:list_project, list: @list, project: create(:project, last_synced_at: Time.current))
    removed = create(:list_project, list: @list)
    stub_request(:get, @readme_url).to_return(body: <<~README)
      - [Retained](#{retained.project.url})
      - [Added](https://github.com/example/new-project)
    README
    ListProject.expects(:upsert_all).raises(ActiveRecord::StatementInvalid)

    SyncListWorker.new.perform(@list.id)

    assert_equal [retained.id, removed.id].sort, @list.list_projects.pluck(:id).sort
  end
end
