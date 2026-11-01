require 'test_helper'

class BlockedProjectsTest < ActionDispatch::IntegrationTest
  setup do
    @original_blocked_topics = ENV['BLOCKED_TOPICS']
    ENV['BLOCKED_TOPICS'] = ' CrossFire, another-topic, , '
    @blocked = create(:project, keywords: %w[ruby crossfire], last_synced_at: Time.current,
      repository: { 'name' => 'Blocked project' })
    @mixed_case = create(:project, keywords: %w[ruby CrossFire], last_synced_at: Time.current,
      repository: { 'name' => 'Mixed case project' })
    @visible = create(:project, keywords: %w[ruby crossfire-tools], last_synced_at: Time.current,
      repository: { 'name' => 'Visible project' })
    @list = create(:list, projects_count: 40,
      repository: { 'description' => 'Useful software', 'fork' => false, 'archived' => false })
    [@blocked, @mixed_case, @visible].each do |project|
      create(:list_project, list: @list, project: project, name: project.repository['name'])
    end
  end

  teardown do
    ENV['BLOCKED_TOPICS'] = @original_blocked_topics
  end

  test 'HTML listings exclude blocked projects before pagination' do
    [{}, { keyword: 'ruby' }, { owner: 'example' }, { language: 'Ruby' }].each do |params|
      [@blocked, @mixed_case, @visible].each do |project|
        project.update!(owner: 'example', repository: project.repository.merge('language' => 'Ruby'))
      end
      get projects_path, params: params

      assert_response :success
      assert_select "#project_#{@visible.id}", count: 1
      assert_select "#project_#{@blocked.id}, #project_#{@mixed_case.id}", count: 0
    end

    get projects_path, params: { keyword: 'crossfire' }
    assert_response :not_found
  end

  test 'API listings exclude blocked projects including nested list projects' do
    [api_v1_projects_path, api_v1_list_projects_path(@list)].each do |path|
      get path, params: { keyword: 'ruby', per_page: 1 }
      assert_response :success
      assert_equal [@visible.id], response.parsed_body.pluck('id')

      get path, params: { keyword: 'crossfire' }
      assert_response :success
      assert_empty response.parsed_body
    end
  end

  test 'direct HTML and API requests reject both slugs and numeric ids' do
    [@blocked, @mixed_case].each do |project|
      [project, project.id].each do |identifier|
        [project_path(identifier), api_v1_project_path(identifier), api_v1_project_lists_path(identifier)].each do |path|
          get path
          assert_response :not_found
        end
      end
    end
  end

  test 'lookups and ping cannot expose or enqueue blocked projects' do
    SyncProjectWorker.expects(:perform_async).never

    post lookup_projects_path, params: { url: @blocked.url }
    assert_response :not_found
    get lookup_api_v1_projects_path, params: { url: @mixed_case.url }
    assert_response :not_found
    get ping_api_v1_project_path(@blocked.id)
    assert_response :not_found
  end

  test 'list pages and list entry API omit blocked entries' do
    get list_path(@list)
    assert_response :success
    assert_select '#list-entries li', count: 1
    assert_select '#list-entries li', text: /Visible project/

    get api_v1_list_list_projects_path(@list)
    assert_response :success
    assert_equal [@visible.id], response.parsed_body.pluck('project_id')
  end

  test 'topic pages omit blocked projects even under another topic' do
    topic = Topic.create!(slug: 'ruby', name: 'Ruby')
    get topic_path(topic)

    assert_response :success
    assert_select "#project_#{@visible.id}", count: 1
    assert_select "#project_#{@blocked.id}, #project_#{@mixed_case.id}", count: 0
  end

  test 'unset and empty configuration leave projects visible' do
    [nil, '', ' , '].each do |value|
      ENV['BLOCKED_TOPICS'] = value
      get api_v1_projects_path, params: { keyword: 'crossfire' }

      assert_response :success
      assert_equal [@blocked.id], response.parsed_body.pluck('id')
      assert_not @blocked.has_blocked_topic?
    end
  end

  test 'matching is exact and accepts missing keywords and multiple blocked topics' do
    missing = create(:project, keywords: nil, last_synced_at: Time.current)
    empty = create(:project, keywords: [], last_synced_at: Time.current)
    other = create(:project, keywords: ['Another-Topic'], last_synced_at: Time.current)

    get api_v1_projects_path

    assert_response :success
    assert_equal [@visible.id, missing.id, empty.id].sort, response.parsed_body.pluck('id').sort
    assert @blocked.has_blocked_topic?
    assert @mixed_case.has_blocked_topic?
    assert other.has_blocked_topic?
    assert_not @visible.has_blocked_topic?
    assert_not missing.has_blocked_topic?
    assert_not empty.has_blocked_topic?
  end

  test 'blocking takes effect for existing records and conditional requests' do
    ENV.delete('BLOCKED_TOPICS')
    get api_v1_projects_path
    etag = response.headers['ETag']

    ENV['BLOCKED_TOPICS'] = 'crossfire'
    get api_v1_projects_path, headers: { 'If-None-Match' => etag }

    assert_response :success
    assert_equal [@visible.id], response.parsed_body.pluck('id')
    assert Project.exists?(@blocked.id)
  end
end
