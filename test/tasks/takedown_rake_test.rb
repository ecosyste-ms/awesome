require "test_helper"
require "rake"

class TakedownRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("takedown:hide_user")
  end

  teardown do
    ENV.delete('LOGIN')
  end

  test "hide_user marks owner hidden and destroys projects" do
    owner = create(:owner, name: 'someuser')
    project = create(:project, url: 'https://github.com/someuser/thing', owner: 'someuser', owner_record: owner)
    other = create(:project, url: 'https://github.com/other/thing', owner: 'other')

    ENV['LOGIN'] = 'someuser'
    capture_io { Rake::Task["takedown:hide_user"].execute }

    assert owner.reload.hidden?
    assert_nil Project.find_by(id: project.id)
    refute_nil Project.find_by(id: other.id)
  end

  test "hide_user creates a hidden owner when none exists" do
    ENV['LOGIN'] = 'NewUser'
    capture_io { Rake::Task["takedown:hide_user"].execute }

    owner = Owner.find_by(name: 'newuser')
    refute_nil owner
    assert owner.hidden?
  end

  test "hide_user aborts without LOGIN" do
    assert_raises(SystemExit) do
      capture_io { Rake::Task["takedown:hide_user"].execute }
    end
  end
end
