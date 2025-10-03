require 'test_helper'

class ListsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @list = create(:list)
  end

  test 'renders index' do
    get '/'
    assert_response :success
    assert_template 'lists/index'
  end

  test 'renders show' do
    get list_url(@list)
    assert_response :success
    assert_template 'lists/show'
  end

  test 'renders show with list projects' do
    list = create(:list,
      displayable: true,
      repository: {
        'description' => 'Test list description',
        'stargazers_count' => 500
      }
    )
    project = create(:project,
      last_synced_at: 1.hour.ago,
      repository: { 'name' => 'test-project' }
    )
    list_project = create(:list_project,
      list: list,
      project: project,
      name: 'Test Project',
      description: 'A test project',
      category: 'Testing'
    )

    get list_url(list)
    assert_response :success
    assert_includes response.body, 'Test list description'
    assert_includes response.body, 'Test Project'
    assert_includes response.body, 'Testing'
  end

  test 'renders markdown' do
    get '/lists/markdown'
    assert_response :success
    assert_template 'lists/markdown'
  end

  test 'renders rss' do
    # Make additional lists for RSS content - ensure it's the newest by setting created_at
    list1 = create(:list, description: 'Description One', created_at: 1.second.from_now)

    get '/lists.rss'

    # Assert response success and correct template
    assert_response :success
    assert_equal 'application/rss+xml; charset=utf-8', @response.content_type
    assert_template 'lists/index'

    # Validate RSS feed content
    assert_includes @response.body, list1.name
    # assert_includes @response.body, list1.description

    # Validate structure of RSS feed
    assert_includes @response.body, '<rss version="2.0">'
    assert_includes @response.body, '<channel>'
    assert_includes @response.body, '<item>'
    assert_includes @response.body, "<title>#{list1.name}</title>"
  end
end