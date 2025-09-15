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
end