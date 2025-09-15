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
end