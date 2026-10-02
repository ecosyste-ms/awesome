require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test "github_pages_to_repo_url" do
    project = Project.new
    repo_url = project.github_pages_to_repo_url('https://foo.github.io/bar')
    assert_equal 'https://github.com/foo/bar', repo_url
  end

  test "github_pages_to_repo_url with trailing slash" do
    project = Project.new(url: 'https://foo.github.io/bar/')
    repo_url = project.repository_url
    assert_equal 'https://github.com/foo/bar', repo_url
  end

  test "check_url deletes project when url returns 404" do
    project = create(:project, url: 'https://github.com/user/nonexistent')
    
    stub_request(:get, 'https://github.com/user/nonexistent')
      .to_return(status: 404, body: 'Not Found')
    
    assert_difference 'Project.count', -1 do
      project.check_url
    end
    
    assert_raises(ActiveRecord::RecordNotFound) do
      Project.find(project.id)
    end
  end

  test "check_url updates url on successful redirect" do
    project = create(:project, url: 'https://github.com/old/repo')
    
    stub_request(:get, 'https://github.com/old/repo')
      .to_return(status: 301, headers: { 'Location' => 'https://github.com/new/repo' })
    
    stub_request(:get, 'https://github.com/new/repo')
      .to_return(status: 200, body: 'Success')
    
    project.check_url
    project.reload
    
    assert_equal 'https://github.com/new/repo', project.url
  end

  test "check_url handles duplicate url error by deleting project" do
    existing_project = create(:project, url: 'https://github.com/user/existing')
    project = create(:project, url: 'https://github.com/user/different')
    
    stub_request(:get, 'https://github.com/user/different')
      .to_return(status: 301, headers: { 'Location' => 'https://github.com/user/existing' })
    
    stub_request(:get, 'https://github.com/user/existing')
      .to_return(status: 200, body: 'Success')
    
    assert_difference 'Project.count', -1 do
      project.check_url
    end
    
    assert Project.exists?(existing_project.id)
    assert_not Project.exists?(project.id)
  end

  test "check_url handles general errors gracefully" do
    project = create(:project, url: 'https://github.com/user/repo')

    stub_request(:get, 'https://github.com/user/repo')
      .to_raise(Faraday::ConnectionFailed.new('Connection failed'))

    assert_no_difference 'Project.count' do
      project.check_url
    end

    assert Project.exists?(project.id)
  end

  test "owner_hidden? returns true when owner is hidden" do
    owner = Owner.create!(name: "hidden-owner", hidden: true)
    project = create(:project, owner_record: owner)

    assert project.owner_hidden?
  end

  test "owner_hidden? returns false when owner is visible" do
    owner = Owner.create!(name: "visible-owner", hidden: false)
    project = create(:project, owner_record: owner)

    assert_not project.owner_hidden?
  end

  test "owner_hidden? returns false when no owner_record" do
    project = create(:project, owner_record: nil)

    assert_not project.owner_hidden?
  end

  test "visible_owners scope excludes projects with hidden owners" do
    hidden_owner = Owner.create!(name: "hidden-owner", hidden: true)
    visible_owner = Owner.create!(name: "visible-owner", hidden: false)

    Rails.cache.clear

    hidden_project = create(:project, owner_record: hidden_owner)
    visible_project = create(:project, owner_record: visible_owner)
    no_owner_project = create(:project, owner_record: nil)

    visible_projects = Project.visible_owners

    assert_includes visible_projects, visible_project
    assert_includes visible_projects, no_owner_project
    assert_not_includes visible_projects, hidden_project
  end

  test "set_owner creates owner_record when repository has owner" do
    project = build(:project)
    project.repository = { "owner" => "test-owner" }

    assert_difference 'Owner.count', 1 do
      project.set_owner
    end

    assert_equal "test-owner", project.owner
    assert_equal "test-owner", project.owner_record.name
  end

  test "set_owner finds existing owner_record" do
    existing_owner = Owner.create!(name: "existing-owner")
    project = build(:project)
    project.repository = { "owner" => "existing-owner" }

    assert_no_difference 'Owner.count' do
      project.set_owner
    end

    assert_equal existing_owner, project.owner_record
  end

  test "set_owner lowercases owner name when creating owner_record" do
    project = build(:project)
    project.repository = { "owner" => "TestOwner" }

    assert_difference 'Owner.count', 1 do
      project.set_owner
    end

    assert_equal "TestOwner", project.owner
    assert_equal "testowner", project.owner_record.name
  end

  test "set_owner finds existing owner_record with different case" do
    existing_owner = Owner.create!(name: "testowner")
    project = build(:project)
    project.repository = { "owner" => "TestOwner" }

    assert_no_difference 'Owner.count' do
      project.set_owner
    end

    assert_equal "TestOwner", project.owner
    assert_equal existing_owner, project.owner_record
  end

  test "fetch_readme truncates contents to README_MAX_BYTES" do
    project = build(:project)
    project.stubs(:readme_file_name).returns("README.md")
    project.stubs(:download_url).returns("https://example.com/archive.tar.gz")
    project.stubs(:archive_url).returns("https://example.com/readme")
    project.stubs(:save).returns(true)

    big = "a" * (Project::README_MAX_BYTES + 5000)
    Project.stubs(:ecosystems_api_get).returns({ "contents" => big })

    project.fetch_readme

    assert_equal Project::README_MAX_BYTES, project.readme.bytesize
  end

  test "fetch_readme keeps short contents intact" do
    project = build(:project)
    project.stubs(:readme_file_name).returns("README.md")
    project.stubs(:download_url).returns("https://example.com/archive.tar.gz")
    project.stubs(:archive_url).returns("https://example.com/readme")
    project.stubs(:save).returns(true)

    Project.stubs(:ecosystems_api_get).returns({ "contents" => "hello" })

    project.fetch_readme

    assert_equal "hello", project.readme
  end

  test "sync preserves cached repository when repository refresh returns nil" do
    project = create(:project, repository: { "full_name" => "user/repo" }, last_synced_at: 2.days.ago)
    previous_last_synced_at = project.reload.last_synced_at
    stub_request(:get, project.url).to_return(status: 200)
    stub_request(:get, project.repos_api_url).to_return(status: 503)

    SyncProjectWorker.new.perform(project.id)
    project.reload

    assert_equal({ "full_name" => "user/repo" }, project.repository)
    assert_equal previous_last_synced_at, project.last_synced_at
    assert_in_delta Time.current, project.last_sync_attempt_at, 1.second
  end

  test "sync preserves cached repository when repository refresh returns an empty response" do
    project = create(:project, repository: { "full_name" => "user/repo" }, last_synced_at: nil)
    project.stubs(:check_url)
    Project.stubs(:ecosystems_api_get).returns({})
    project.expects(:fetch_readme).never

    project.sync
    project.reload

    assert_equal({ "full_name" => "user/repo" }, project.repository)
    assert_nil project.last_synced_at
    assert_in_delta Time.current, project.last_sync_attempt_at, 1.second
  end

  test "sync preserves cached repository when repository refresh raises" do
    project = create(:project, repository: { "full_name" => "user/repo" }, last_synced_at: nil)
    project.stubs(:check_url)
    Project.stubs(:ecosystems_api_get).raises(Faraday::ConnectionFailed.new("Connection failed"))
    project.expects(:fetch_readme).never

    project.sync
    project.reload

    assert_equal({ "full_name" => "user/repo" }, project.repository)
    assert_nil project.last_synced_at
    assert_in_delta Time.current, project.last_sync_attempt_at, 1.second
  end

  test "sync skips hidden owners" do
    owner = create(:owner, name: 'gone', hidden: true)
    project = create(:project, url: 'https://github.com/gone/thing', owner: 'gone', owner_record: owner, last_synced_at: nil)

    project.expects(:check_url).never
    project.sync
  end

  test "sync clears the retry marker after a successful repository refresh" do
    project = create(:project, last_synced_at: 2.days.ago, last_sync_attempt_at: 1.hour.ago)
    project.stubs(:check_url)
    Project.stubs(:ecosystems_api_get).returns({ "full_name" => "user/repo", "topics" => [] })
    project.stubs(:fetch_readme)
    project.stubs(:sync_list)
    project.stubs(:ping)

    project.sync
    project.reload

    assert_in_delta Time.current, project.last_synced_at, 1.second
    assert_nil project.last_sync_attempt_at
  end

  test "sync scheduler reserves capacity for first attempts and retries" do
    retry_projects = create_list(:project, 50, last_synced_at: nil, last_sync_attempt_at: 1.hour.ago)
    first_attempt_projects = create_list(:project, 50, last_synced_at: nil, last_sync_attempt_at: nil)
    queued_jobs = nil
    SyncProjectWorker.expects(:perform_bulk).with do |jobs|
      queued_jobs = jobs
      true
    end

    Project.sync_least_recently_synced

    queued_ids = queued_jobs.flatten
    assert_equal Project::SYNC_BATCH_SIZE, queued_ids.length
    assert_equal Project::SYNC_RETRY_BATCH_SIZE, (queued_ids & retry_projects.map(&:id)).length
    assert_equal Project::SYNC_BATCH_SIZE - Project::SYNC_RETRY_BATCH_SIZE,
                 (queued_ids & first_attempt_projects.map(&:id)).length
  end
end
