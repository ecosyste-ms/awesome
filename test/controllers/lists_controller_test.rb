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

  test 'renders markdown' do
    get '/lists/markdown'
    assert_response :success
    assert_template 'lists/markdown'
  end

  test 'renders rss' do
    # Make additional lists for RSS content
    list1 = create(:list, name: 'List One', description: 'Description One')
  
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