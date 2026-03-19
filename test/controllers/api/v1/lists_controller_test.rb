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
end
