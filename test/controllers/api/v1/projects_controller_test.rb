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

  test 'lookup ignores integer funding metadata' do
    @repository_project.update!(repository: { 'metadata' => { 'funding' => 123 } })

    get lookup_api_v1_projects_path, params: { url: @repository_project.url }

    assert_response :success
    assert_equal @repository_project.id, response.parsed_body['id']
    assert_equal [], response.parsed_body['funding_links']
  end

  test 'lookup preserves README funding links with non-hash funding metadata' do
    [nil, 'invalid', 123, 1.5, true, false, ['invalid']].each do |funding|
      @repository_project.update!(repository: { 'metadata' => { 'funding' => funding } },
                                  readme: 'Support: https://github.com/sponsors/example')

      get lookup_api_v1_projects_path, params: { url: @repository_project.url }

      assert_response :success
      assert_equal ['https://github.com/sponsors/example'], response.parsed_body['funding_links']
    end
  end

  test 'lookup includes links from valid funding metadata' do
    @repository_project.update!(repository: { 'metadata' => { 'funding' => {
      'github' => ['example'], 'open_collective' => 'example'
    } } })

    get lookup_api_v1_projects_path, params: { url: @repository_project.url }

    assert_response :success
    assert_equal ['https://github.com/sponsors/example', 'https://opencollective.com/example'],
                 response.parsed_body['funding_links']
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

  test 'numeric project id redirects to the API project url' do
    get api_v1_project_path(@repository_project.id)

    assert_redirected_to api_v1_project_url(@repository_project)
    follow_redirect!

    assert_response :success
    assert_equal 'application/json', response.media_type
    assert_equal @repository_project.id, response.parsed_body['id']
  end

  test 'list slugs ending in projects render the list' do
    list = create(:list, url: 'https://github.com/owner/projects')

    get '/api/v1/lists/owner/projects'

    assert_response :success
    assert_equal list.id, response.parsed_body['id']
  end

  test 'returns not modified for a cached list slug ending in projects' do
    create(:list, url: 'https://github.com/owner/projects')
    get '/api/v1/lists/owner/projects'

    get '/api/v1/lists/owner/projects', headers: { 'If-None-Match' => response.headers['ETag'] }

    assert_response :not_modified
  end

  test 'list projects return not found when neither list exists' do
    get '/api/v1/lists/missing/projects'

    assert_response :not_found
  end

  test 'project slugs ending in ping render the project without syncing' do
    project = create(:project, url: 'https://github.com/owner/ping')
    Project.any_instance.expects(:sync_async).never

    get '/api/v1/projects/github.com/owner/ping'

    assert_response :success
    assert_equal project.id, response.parsed_body['id']
  end

  test 'project slugs ending in ping return not found when the topic is blocked' do
    Project.stubs(:blocked_topics).returns(['blocked'])
    create(:project, url: 'https://github.com/owner/ping', keywords: ['blocked'])

    get '/api/v1/projects/github.com/owner/ping'

    assert_response :not_found
  end

  test 'ping syncs a project by slug' do
    Project.any_instance.expects(:sync_async).once

    get "/api/v1/projects/#{@repository_project.slug}/ping"

    assert_response :success
    assert_equal 'pong', response.parsed_body['message']
  end

  test 'ping syncs a project by numeric id' do
    Project.any_instance.expects(:sync_async).once

    get "/api/v1/projects/#{@repository_project.id}/ping"

    assert_response :success
    assert_equal 'pong', response.parsed_body['message']
  end

  test 'ping returns not found when the owner is hidden' do
    hidden = create(:project, owner_record: create(:owner, :hidden), last_synced_at: Time.current)
    Project.any_instance.expects(:sync_async).never

    get "/api/v1/projects/#{hidden.slug}/ping"
    assert_response :not_found

    get "/api/v1/projects/#{hidden.id}/ping"
    assert_response :not_found
  end

  test 'ping returns not found for an unknown project' do
    get '/api/v1/projects/github.com/missing/project/ping'

    assert_response :not_found
  end

  test 'numeric project id returns 404 when the owner is hidden' do
    hidden = create(:project, owner_record: create(:owner, :hidden), last_synced_at: Time.current)

    get api_v1_project_path(hidden.id)

    assert_response :not_found
  end
end
