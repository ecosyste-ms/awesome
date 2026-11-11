require 'test_helper'
require 'rake'

class ListsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('lists:clean_up')
  end

  test 'clean_up removes lists that have never resolved to a repository' do
    unresolved = create(:list, unresolved_attributes)
    join = create(:list_project, list: unresolved)
    kept = {
      'recently created' => create(:list, unresolved_attributes.merge(created_at: 29.days.ago)),
      'never attempted' => create(:list, unresolved_attributes.merge(last_sync_attempt_at: nil)),
      'repository fetched' => create(:list, unresolved_attributes.merge(repository: { 'full_name' => 'example/awesome' })),
      'previously synced' => create(:list, unresolved_attributes.merge(last_synced_at: 40.days.ago))
    }

    output, = capture_io { Rake::Task['lists:clean_up'].execute }

    assert_not List.exists?(unresolved.id)
    assert_not ListProject.exists?(join.id)
    assert Project.exists?(join.project_id)
    kept.each { |state, list| assert List.exists?(list.id), "expected #{state} list to be kept" }
    assert_includes output, 'removed 1 unresolved lists'
  end

  def unresolved_attributes
    { repository: nil, readme: nil, last_synced_at: nil, last_sync_attempt_at: 1.hour.ago, created_at: 31.days.ago }
  end
end
