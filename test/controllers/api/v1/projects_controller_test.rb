require 'test_helper'

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = create(:list)
    @repository_project = create(:project, repository: { 'name' => 'Library' }, last_synced_at: Time.current, keywords: ['ruby'])
    @website = create(:project, repository: nil, last_synced_at: Time.current, keywords: ['ruby'])
    awesome_list = create(:list)
    @awesome_project = create(:project, url: awesome_list.url, repository: { 'name' => 'Awesome list' }, last_synced_at: Time.current, keywords: ['ruby'])
    [@awesome_project, @website, @repository_project].each do |project|
      create(:list_project, list: @list, project: project)
    end
  end

  test 'list projects includes repositories websites and lists by default' do
    get api_v1_list_projects_path(@list)

    assert_response :success
    assert_equal [@repository_project.id, @website.id, @awesome_project.id], response.parsed_body.pluck('id')
  end

  test 'list projects filters projects with repository data' do
    get api_v1_list_projects_path(@list), params: { with_repository: 'true' }

    assert_response :success
    assert_equal [@repository_project.id, @awesome_project.id], response.parsed_body.pluck('id')
  end

  test 'list projects filters awesome lists' do
    get api_v1_list_projects_path(@list), params: { not_list: 'true' }

    assert_response :success
    assert_equal [@repository_project.id, @website.id], response.parsed_body.pluck('id')
  end

  test 'list project filters combine with keyword and visibility scopes' do
    unsynced = create(:project, keywords: ['ruby'])
    hidden = create(:project, owner_record: create(:owner, :hidden), last_synced_at: Time.current, keywords: ['ruby'])
    other_keyword = create(:project, last_synced_at: Time.current, keywords: ['python'])
    [unsynced, hidden, other_keyword].each { |project| create(:list_project, list: @list, project: project) }
    create(:project, last_synced_at: Time.current, keywords: ['ruby'])

    get api_v1_list_projects_path(@list), params: { with_repository: 'true', not_list: 'true', keyword: 'ruby' }

    assert_response :success
    assert_equal [@repository_project.id], response.parsed_body.pluck('id')
  end

  test 'false filter values do not exclude projects' do
    get api_v1_list_projects_path(@list), params: { with_repository: 'false', not_list: 'false' }

    assert_response :success
    assert_equal [@repository_project.id, @website.id, @awesome_project.id], response.parsed_body.pluck('id')
  end

  test 'list projects are paginated in project id order' do
    [@repository_project, @website, @awesome_project].each.with_index(1) do |project, page|
      get api_v1_list_projects_path(@list), params: { page: page, per_page: 1 }

      assert_response :success
      assert_equal [project.id], response.parsed_body.pluck('id')
    end
  end

  test 'numeric list redirects preserve filters and pagination' do
    params = { with_repository: 'true', not_list: 'true', keyword: 'ruby', page: '1', per_page: '1' }
    get api_v1_list_projects_path(@list.id), params: params

    assert_redirected_to api_v1_list_projects_url(@list, params)
    follow_redirect!

    assert_response :success
    assert_equal [@repository_project.id], response.parsed_body.pluck('id')
  end
end
