require 'test_helper'
require 'rake'

class ProjectsTaskTest < ActiveSupport::TestCase
  setup do
    Resolv.stubs(:getaddresses).with('github.com').returns(['93.184.216.34'])
    Rails.application.load_tasks unless Rake::Task.task_defined?('projects:sync')
    SyncProjectWorker.clear
  end

  teardown do
    SyncProjectWorker.clear
  end

  ['new', 'previously synced'].each do |state|
    test "sync task waits an hour before retrying a #{state} project" do
      freeze_time
      last_synced_at = state == 'new' ? nil : 2.days.ago
      cached_repository = { 'full_name' => 'user/repo', 'description' => 'Old description' }
      project = create(:project, repository: cached_repository, last_synced_at: last_synced_at)
      repository = cached_repository.merge('description' => 'Updated description', 'host' => { 'name' => 'GitHub' })
      stub_request(:get, project.url).to_return(status: 200)
      lookup = stub_request(:get, project.repos_api_url)
        .to_return(status: 503)
        .then.to_return(status: 200, body: repository.to_json)
      stub_request(:get, 'https://repos.ecosyste.ms/api/v1/hosts/GitHub/repositories/user/repo/ping')
        .to_return(status: 200, body: '{}')

      enqueue_projects
      assert_equal [project.id], SyncProjectWorker.jobs.map { |job| job['args'].first }
      SyncProjectWorker.drain
      assert_equal cached_repository, project.reload.repository
      if last_synced_at
        assert_equal last_synced_at, project.last_synced_at
      else
        assert_nil project.last_synced_at
      end
      assert_equal Time.current, project.last_sync_attempt_at

      enqueue_projects
      assert_empty SyncProjectWorker.jobs
      travel 1.hour - 1.second
      enqueue_projects
      assert_empty SyncProjectWorker.jobs

      travel 1.second
      enqueue_projects
      assert_equal [project.id], SyncProjectWorker.jobs.map { |job| job['args'].first }
      SyncProjectWorker.drain
      assert_equal repository, project.reload.repository
      assert_equal Time.current, project.last_synced_at
      assert_nil project.last_sync_attempt_at
      assert_requested lookup, times: 2

      enqueue_projects
      assert_empty SyncProjectWorker.jobs
    end
  end

  def enqueue_projects
    Rake::Task['projects:sync'].reenable
    Rake::Task['projects:sync'].invoke
  end
end
