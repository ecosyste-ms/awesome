require 'test_helper'
require 'rake'

class TopicsTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('topics:load_from_github')
    Topic.stubs(:sleep)
    Resolv.stubs(:getaddresses).with('explore-feed.github.com').returns(['93.184.216.34'])
    Resolv.stubs(:getaddresses).with('github.com').returns(['93.184.216.34'])
  end

  test 'imports valid topics while skipping unsafe URLs and redirects' do
    topics = [
      { topic_name: 'private', url: 'http://127.0.0.1/private' },
      { topic_name: 'lookalike', url: 'https://github.com.evil.example/topics/lookalike' },
      { topic_name: 'script', url: 'javascript:alert(1)' },
      { topic_name: 'redirect', url: 'https://github.com/topics/redirect' },
      { topic_name: 'ruby', display_name: 'Ruby', url: 'https://github.com/topics/ruby', content: '<p>Ruby</p>' }
    ]
    stub_request(:get, 'https://explore-feed.github.com/feed.json').to_return(status: 200, body: { topics: topics }.to_json)
    stub_request(:get, 'https://github.com/topics/redirect')
      .to_return(status: 302, headers: { 'Location' => 'https://127.0.0.1/private' })
    stub_request(:get, 'https://github.com/topics/ruby')
      .to_return(status: 200, body: '<span class="h3 color-fg-muted">1,234 repositories</span>')

    Rake::Task['topics:load_from_github'].reenable
    Rake::Task['topics:load_from_github'].invoke

    assert_equal ['ruby'], Topic.pluck(:slug)
    assert_equal 1234, Topic.find_by!(slug: 'ruby').github_count
    assert_not_requested :get, 'http://127.0.0.1/private'
    assert_not_requested :get, 'https://127.0.0.1/private'
    assert_not_requested :get, 'https://github.com.evil.example/topics/lookalike'
  end
end
