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
