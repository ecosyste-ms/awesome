require 'test_helper'

class Api::V1::ListProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = create(:list)
    @platforms = create(:list_project, list: @list, project: create(:project, last_synced_at: Time.current),
                        category: 'Platforms', sub_category: 'Web')
    @tools = create(:list_project, list: @list, project: create(:project, last_synced_at: Time.current),
                    category: 'Tools')
  end

  test 'renders list projects by slug' do
    get api_v1_list_list_projects_url(@list)

    assert_response :success
    assert_equal [@platforms.id, @tools.id].sort, response.parsed_body.pluck('id').sort
  end

  test 'includes pagination headers' do
    get api_v1_list_list_projects_url(@list), params: { per_page: 1 }

    assert_response :success
    assert_equal '1', response.headers['page-items']
    assert_match(/rel="next"/, response.headers['link'])
  end

  test 'numeric list redirects preserve filters and pagination' do
    params = { category: 'Platforms', sub_category: 'Web', page: '2', per_page: '1' }

    get api_v1_list_list_projects_url(@list.id), params: params

    assert_redirected_to api_v1_list_list_projects_url(@list, params)
    follow_redirect!

    assert_response :success
  end

  test 'numeric list redirects keep category filter when following redirect' do
    get api_v1_list_list_projects_url(@list.id), params: { category: 'Platforms' }
    follow_redirect!

    assert_response :success
    assert_equal [@platforms.id], response.parsed_body.pluck('id')
  end
end
