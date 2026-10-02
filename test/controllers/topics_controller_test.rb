require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  test 'show sanitizes imported HTML and rejects unsafe link schemes' do
    topic = Topic.create!(slug: 'unsafe-topic', name: 'Unsafe topic',
      content: '<p><strong>Safe content</strong></p><script id="injected">alert(1)</script><img id="untrusted" src="x" onerror="alert(1)"><a href="javascript:alert(1)">Unsafe link</a>',
      url: 'javascript:alert(1)', wikipedia_url: 'data:text/html,unsafe', github_url: 'javascript:alert(2)')

    get topic_url(topic)

    assert_response :success
    assert_select 'strong', text: 'Safe content'
    assert_select 'script#injected', count: 0
    assert_select 'img#untrusted[onerror]', count: 0
    assert_select 'a[href^="javascript:"]', count: 0
    assert_select 'a[href^="data:"]', count: 0
    assert_select 'script[src*="cdnjs.cloudflare.com"]', count: 0
  end

  test 'show preserves HTTP and HTTPS topic links and escapes unsafe URL text' do
    topic = Topic.create!(slug: 'safe-topic', name: 'Safe topic', url: 'https://github.com/topics/ruby',
      wikipedia_url: 'http://en.wikipedia.org/wiki/Ruby', github_url: '\"><img id="injected" src=x>')

    get topic_url(topic)

    assert_response :success
    assert_select 'a[href="https://github.com/topics/ruby"]', count: 1
    assert_select 'a[href="http://en.wikipedia.org/wiki/Ruby"]', count: 1
    assert_select 'img#injected', count: 0
  end

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
