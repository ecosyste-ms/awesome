require 'test_helper'

class Api::V1::ListsControllerTest < ActionDispatch::IntegrationTest
    setup do
        @list = create(:list,
            projects_count: 50,
            repository: {
                'fork' => false,
                'archived' => false,
                'description' => 'Test list',
                'topics' => ['test']
            }
        )
    end

    test 'renders index' do
        get api_v1_lists_url
        assert_response :success
    end

    test 'renders only displayable lists that contain the project' do
        project = create(:project)
        create(:list_project, project: project, list: @list)
        create(:list_project, project: project, list: create(:list, projects_count: 1))
        create(:list, projects_count: 50)

        get api_v1_project_lists_url(project)
        assert_response :success
        assert_equal [@list.id], response.parsed_body.pluck('id')
    end

    test 'limits pagination to 10000 pages' do
        get api_v1_lists_url, params: { page: 10_000 }
        assert_response :success

        get api_v1_lists_url, params: { page: 10_001 }
        assert_response :bad_request

        get api_v1_lists_url, params: { page: '99999999999999999999' }
        assert_response :bad_request
    end

    test 'renders show' do
        get api_v1_list_url(@list)
        assert_response :success
    end

    test 'lookup returns existing list' do
        List.any_instance.stubs(:sync_async)
        get lookup_api_v1_lists_url, params: { url: @list.url }
        assert_response :success
    end

    test 'lookup creates new list when not found' do
        List.any_instance.stubs(:sync_async)
        get lookup_api_v1_lists_url, params: { url: 'https://github.com/new/list' }
        assert_response :success
        assert List.find_by(url: 'https://github.com/new/list')
    end

    test 'lookup returns bad request without url' do
        get lookup_api_v1_lists_url
        assert_response :bad_request
    end

    test 'numeric project redirects preserve filters and pagination' do
        project = create(:project)
        create(:list_project, project: project, list: @list)
        params = { topic: 'test', language: 'Ruby', natural_language: 'en', sort: 'projects_count', order: 'asc', page: '1', per_page: '1' }

        get api_v1_project_lists_url(project.id), params: params
        assert_redirected_to api_v1_project_lists_url(project, params)
        follow_redirect!

        assert_response :success
    end

    test 'project lists return not found when the owner is hidden' do
        project = create(:project, owner_record: create(:owner, :hidden))
        create(:list_project, project: project, list: @list)

        get api_v1_project_lists_url(project)
        assert_response :not_found

        get api_v1_project_lists_url(project.id)
        assert_response :not_found
    end

    test 'renders the natural language of a list' do
        @list.update!(natural_language: 'zh')

        get api_v1_list_url(@list)
        assert_equal 'zh', response.parsed_body['natural_language']
    end

    test 'filters lists by natural language' do
        @list.update!(natural_language: 'zh')
        other = create(:list, projects_count: 50, natural_language: 'en')

        get api_v1_lists_url, params: { natural_language: 'ZH' }
        assert_response :success
        assert_equal [@list.id], response.parsed_body.pluck('id')

        get api_v1_lists_url, params: { natural_language: 'en' }
        assert_equal [other.id], response.parsed_body.pluck('id')
    end
end
