require 'test_helper'

class Api::V1::TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @topic = Topic.create!(slug: 'ruby', name: 'Ruby', github_count: 100)
  end

  test 'show finds a topic by slug' do
    get api_v1_topic_url('ruby')

    assert_response :success
    assert_equal @topic.id, response.parsed_body['id']
  end

  test 'show accepts topic slugs regardless of letter case' do
    %w[Ruby RUBY rUbY].each do |slug|
      get api_v1_topic_url(slug)

      assert_response :success
      assert_equal @topic.id, response.parsed_body['id']
    end
  end

  test 'show returns not found for an unknown topic' do
    get api_v1_topic_url('missing')

    assert_response :not_found
  end
end
