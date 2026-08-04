require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get topics_url
    assert_response :success
  end

  test "should get show" do
    topic = Topic.create!(
      slug: 'test-topic',
      name: 'Test Topic',
      github_count: 100
    )
    get topic_url(topic)
    assert_response :success
  end

  test "show redirects to canonical when extra params present" do
    topic = Topic.create!(slug: 'redir-topic', name: 'Redir', github_count: 100)
    get topic_url(topic, keyword: 'foo')
    assert_redirected_to topic_path(topic)
    assert_equal 301, response.status
  end

  test "show preserves page param on canonical redirect" do
    topic = Topic.create!(slug: 'redir-topic-2', name: 'Redir', github_count: 100)
    get topic_url(topic, keyword: 'foo', page: 2)
    assert_redirected_to topic_path(topic, page: 2)
  end

  test "show does not redirect with only page param" do
    topic = Topic.create!(slug: 'paged-topic', name: 'Paged', github_count: 100)
    get topic_url(topic, page: 1)
    assert_response :success
  end

  test "should handle show with no projects" do
    topic = Topic.create!(
      slug: 'empty-topic',
      name: 'Empty Topic',
      github_count: 0
    )
    get topic_url(topic)
    assert_response :success
  end
end
