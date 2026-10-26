require 'test_helper'

class ListPagesTest < ActionDispatch::IntegrationTest
  setup do
    @list = create(:list, projects_count: 40, primary_language: nil, list_of_lists: false,
      repository: { 'description' => 'Useful software', 'fork' => false, 'archived' => false })
  end

  test 'renders inline Markdown and safe links without bullets on headings or empty sidebar cards' do
    entry('Tool', description: 'See the [source](https://example.com/source), **details** and `MIT`. <script>alert(1)</script> [unsafe](javascript:alert(1))')

    get list_path(@list)

    assert_response :success
    assert_select '#list-entries a[href="https://example.com/source"]', text: 'source'
    assert_select '#list-entries strong', text: 'details'
    assert_select '#list-entries code', text: 'MIT'
    assert_select '#list-entries script', count: 0
    assert_select '#list-entries a[href^="javascript:"]', count: 0
    assert_select 'li h2, li h3', count: 0
    assert_select 'aside .card-header', text: 'Subcategories', count: 0
    assert_select 'h3', text: '', count: 0
  end

  test 'category links load entries beyond the first page and clear pagination' do
    201.times { |index| entry("Animal #{index}", category: 'Animals') }
    entry('Developer tool', category: 'Development', sub_category: 'Testing')

    get list_path(@list)
    assert_select '#list-entries', text: /Developer tool/, count: 0
    link = css_select('aside a').find { |element| element.text.include?('Development') }
    assert link
    get link['href'].split('#').first

    assert_response :success
    assert_select '#list-entries h2', text: 'Development'
    assert_select '#list-entries', text: /Developer tool/
    assert_select '#list-entries', text: /Animal 0/, count: 0
    assert_select 'aside a.active', text: /Development/
  end

  test 'language topic category and subcategory filters combine case insensitively' do
    entry('Match', language: 'Go', topics: ['Security'], category: 'APIs', sub_category: 'Testing')
    entry('Wrong language', language: 'Ruby', topics: ['Security'], category: 'APIs', sub_category: 'Testing')
    entry('Wrong topic', language: 'Go', topics: ['Tools'], category: 'APIs', sub_category: 'Testing')
    entry('Wrong category', language: 'Go', topics: ['Security'], category: 'Software', sub_category: 'Testing')
    entry('Wrong subcategory', language: 'Go', topics: ['Security'], category: 'APIs', sub_category: 'Other')

    get list_path(@list), params: { language: 'go', topic: 'security', category: 'apis', sub_category: 'testing' }

    assert_response :success
    assert_select '#list-entries li', count: 1
    assert_select '#list-entries li', text: /Match/
    assert_select 'a', text: 'Clear filters'
    assert_select 'aside a.active', count: 4
  end

  test 'filter links preserve selections and reset page and subordinate categories' do
    entry('Tool', language: 'Go', topics: ['Tools'], category: 'Software', sub_category: 'Testing')
    get list_path(@list), params: { language: 'Go', sub_category: 'Testing', page: 2 }
    category_link = css_select('aside a').find { |element| element.text.strip.start_with?('Software') }
    query = Rack::Utils.parse_query(URI.parse(category_link['href']).query)
    assert_equal({ 'language' => 'Go', 'category' => 'Software' }, query)
  end

  test 'conditional responses and fragments vary by filters and page' do
    entry('Go tool', language: 'Go')
    entry('Ruby tool', language: 'Ruby')
    get list_path(@list)
    etag = response.headers['ETag']
    get list_path(@list), params: { language: 'Go' }, headers: { 'If-None-Match' => etag }
    assert_response :success
    assert_select '#list-entries li', count: 1
    go_etag = response.headers['ETag']
    get list_path(@list), params: { language: 'Go' }, headers: { 'If-None-Match' => go_etag }
    assert_response :not_modified
    get list_path(@list), params: { page: 2 }, headers: { 'If-None-Match' => go_etag }
    assert_response :success
    assert_select '#list-entries', text: /No projects match/
  end

  test 'numeric redirects preserve filters and pagination' do
    get "/lists/#{@list.id}", params: { language: 'Go', category: 'APIs', page: 2 }
    assert_redirected_to list_path(@list, language: 'Go', category: 'APIs', page: 2)
  end

  test 'removes unsafe schemes images attributes and raw HTML from descriptions' do
    entry('Unsafe', description: <<~MARKDOWN)
      [unsafe](javascript:alert%281%29) [data](data:text/html;base64,PHNjcmlwdD4=)
      <a href="javascript:alert(1)" onclick="alert(1)">raw link</a>
      <img src="https://example.com/tracker" onerror="alert(1)">
      ![remote](https://example.com/image.svg)
      [safe](https://example.com/safe?x=1&y=2)
    MARKDOWN
    get list_path(@list)

    assert_response :success
    assert_select '#list-entries img, #list-entries script, #list-entries iframe', count: 0
    assert_select '#list-entries [onclick], #list-entries [onerror], #list-entries [style]', count: 0
    assert_select '#list-entries a[href^="javascript:"], #list-entries a[href^="data:"]', count: 0
    assert_select '#list-entries a[href="https://example.com/safe?x=1&y=2"]', count: 1
  end

  test 'renders deeply nested descriptions as escaped text rather than failing the page' do
    entry('Deep', description: ('> ' * 1100) + '<script>alert(1)</script>')
    get list_path(@list)

    assert_response :success
    assert_select '#list-entries script', count: 0
    assert_includes response.body, '&lt;script&gt;alert(1)&lt;/script&gt;'
  end

  test 'filter values cannot alter SQL or inject HTML' do
    entry('Tool', category: 'Software')
    get list_path(@list), params: { category: "' OR 1=1 --", topic: '<script>alert(1)</script>' }

    assert_response :success
    assert_select '#list-entries li', count: 0
    assert_select 'script', text: 'alert(1)', count: 0
  end

  test 'database query count does not grow with the number of entries' do
    entry('First', language: 'Go', topics: ['tools'])
    small_count = count_selects { get list_path(@list) }
    50.times { |index| entry("Tool #{index}", language: 'Go', topics: ['tools']) }
    large_count = count_selects { get list_path(@list) }

    assert_response :success
    assert_operator large_count, :<=, small_count + 1
  end

  test 'cached fragments do not leak entries or active filters between requests' do
    entry('Go tool', language: 'Go')
    entry('Ruby tool', language: 'Ruby')
    original_caching = ActionController::Base.perform_caching
    original_cache = ActionController::Base.cache_store
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new

    get list_path(@list), params: { language: 'Go' }
    get list_path(@list), params: { language: 'Ruby' }
    assert_response :success
    assert_select '#list-entries', text: /Ruby tool/
    assert_select '#list-entries', text: /Go tool/, count: 0
    assert_select 'aside a.active', text: /Ruby/
    assert_select 'aside a.active', text: /Go/, count: 0
  ensure
    ActionController::Base.perform_caching = original_caching
    ActionController::Base.cache_store = original_cache
  end

  def count_selects
    queries = []
    subscriber = ->(*args) { payload = args.last; queries << payload[:sql] if payload[:sql].start_with?('SELECT') && payload[:name] != 'SCHEMA' }
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { yield }
    queries.length
  end

  def entry(name, description: 'Useful software', category: 'Software', sub_category: nil, language: nil, topics: [])
    project = create(:project, last_synced_at: Time.current, repository: { 'language' => language }, keywords: topics)
    create(:list_project, list: @list, project: project, name: name, description: description, category: category, sub_category: sub_category)
  end
end
