require 'test_helper'

class CacheHeadersTest < ActionDispatch::IntegrationTest
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

  test 'html pages set browser max-age to 5 minutes' do
    get '/'
    assert_response :success
    assert_match /max-age=#{5.minutes.to_i}/, response.headers['Cache-Control']
  end

  test 'html pages set public cache control' do
    get '/'
    assert_response :success
    assert_match /public/, response.headers['Cache-Control']
  end

  test 'html pages set browser stale-while-revalidate' do
    get '/'
    assert_response :success
    assert_match /stale-while-revalidate=#{1.hour.to_i}/, response.headers['Cache-Control']
  end

  test 'html pages set CDN-Cache-Control with 4 hour max-age' do
    get '/'
    assert_response :success
    assert_match /max-age=#{4.hours.to_i}/, response.headers['CDN-Cache-Control']
  end

  test 'html pages set CDN-Cache-Control with 1 day stale-while-revalidate' do
    get '/'
    assert_response :success
    assert_match /stale-while-revalidate=#{1.day.to_i}/, response.headers['CDN-Cache-Control']
  end

  test 'api endpoints set CDN-Cache-Control with 1 hour max-age' do
    get api_v1_topics_path(format: :json)
    assert_response :success
    assert_match /max-age=#{1.hour.to_i}/, response.headers['CDN-Cache-Control']
  end

  test 'api endpoints set CDN-Cache-Control with 4 hour stale-while-revalidate' do
    get api_v1_topics_path(format: :json)
    assert_response :success
    assert_match /stale-while-revalidate=#{4.hours.to_i}/, response.headers['CDN-Cache-Control']
  end

  test 'api endpoints set shorter browser stale-while-revalidate' do
    get api_v1_topics_path(format: :json)
    assert_response :success
    assert_match /stale-while-revalidate=#{30.minutes.to_i}/, response.headers['Cache-Control']
  end

  test 'POST requests do not set CDN-Cache-Control' do
    post lookup_projects_path, params: { url: 'https://github.com/test/repo' }
    assert_nil response.headers['CDN-Cache-Control']
  end

  test 'show pages set CDN-Cache-Control' do
    get list_url(@list)
    assert_response :success
    assert_match /max-age=#{4.hours.to_i}/, response.headers['CDN-Cache-Control']
  end
end
