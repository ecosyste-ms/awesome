require 'test_helper'

class ListMarkdownTest < ActionDispatch::IntegrationTest
  test 'excludes templates and generated repositories while accepting missing metadata' do
    [{ 'template' => true }, { 'template_full_name' => 'owner/template' }].each_with_index do |metadata, index|
      list = markdown_list("template-#{index}", metadata: metadata)
      assert_not list.reload.displayable?
      list.update_column(:displayable, true)
    end
    [{}, { 'template' => false, 'template_full_name' => nil }, { 'template_full_name' => '' }].each_with_index do |metadata, index|
      markdown_list("source-#{index}", metadata: metadata)
    end

    get '/lists/markdown'

    assert_response :success
    assert_not_includes response.body, '[template-'
    3.times { |index| assert_includes response.body, "[source-#{index}]" }
  end

  test 'orders each section by star band and case insensitive name with a URL tie breaker' do
    [true, false].each do |list_of_lists|
      owner = list_of_lists ? 'collections' : 'lists'
      markdown_list('zebra', stars: 1000, owner: owner, list_of_lists: list_of_lists)
      alpha = markdown_list('Alpha', stars: 100, owner: owner, list_of_lists: list_of_lists)
      beta = markdown_list('beta', stars: 999, owner: owner, list_of_lists: list_of_lists)
      markdown_list('low', stars: 9, owner: owner, list_of_lists: list_of_lists)
      markdown_list('none', stars: nil, owner: owner, list_of_lists: list_of_lists)

      get '/lists/markdown'
      lines = response.body.lines.select { |line| line.include?("github.com/#{owner}/") }
      assert_equal %w[zebra Alpha beta low none], lines.map { |line| line[/\[([^\]]+)\]/, 1] }

      alpha.update!(repository: alpha.repository.merge('stargazers_count' => 998))
      beta.update!(repository: beta.repository.merge('stargazers_count' => 101))
      get '/lists/markdown'
      assert_equal lines, response.body.lines.select { |line| line.include?("github.com/#{owner}/") }
    end

    markdown_list('same', stars: 100, owner: 'z-owner')
    markdown_list('same', stars: 999, owner: 'a-owner')
    get '/lists/markdown'
    assert_operator response.body.index('github.com/a-owner/same'), :<, response.body.index('github.com/z-owner/same')
  end

  test 'keeps language headings and anchors stable when star rankings change' do
    ruby = markdown_list('ruby', language: 'Ruby', stars: 999)
    markdown_list('python', language: 'Python', stars: 100)
    get '/lists/markdown'
    headings = response.body.lines.grep(/^### /)
    assert_equal ["### Python Lists\n", "### Ruby Lists\n"], headings

    ruby.update!(repository: ruby.repository.merge('stargazers_count' => 10))
    get '/lists/markdown'
    assert_equal headings, response.body.lines.grep(/^### /)
  end

  test 'groups lists by recognized topics without duplicates and keeps unmatched lists' do
    Topic.create!(slug: 'machine-learning', name: 'Machine Learning')
    Topic.create!(slug: 'data-science', name: 'Data Science')
    Topic.create!(slug: 'awesome', name: 'Awesome Lists')
    Topic.create!(slug: 'hacktoberfest', name: 'Hacktoberfest')
    markdown_list('awesome-machine-learning', metadata: { 'topics' => %w[data-science Machine-Learning awesome] })
    markdown_list('analysis', metadata: { 'topics' => %w[machine-learning data-science] })
    markdown_list('python', language: 'Python', metadata: { 'topics' => ['machine-learning'] })
    markdown_list('collections', list_of_lists: true, metadata: { 'topics' => ['machine-learning'] })
    markdown_list('unmatched', metadata: { 'topics' => %w[unknown awesome hacktoberfest] })
    markdown_list('no-topics')

    get '/lists/markdown'

    assert_response :success
    assert_includes response.body, '[Machine Learning Topic Lists](#machine-learning-topic-lists)'
    sections = response.body.split(/(?=^##)/).to_h { |section| [section.lines.first.strip, section] }
    assert_includes sections.fetch('### Data Science Topic Lists'), '[analysis]'
    assert_includes sections.fetch('### Machine Learning Topic Lists'), '[awesome-machine-learning]'
    assert_includes sections.fetch('### Python Lists'), '[python]'
    assert_includes sections.fetch('## Lists of Lists'), '[collections]'
    assert_includes sections.fetch('## Other Lists'), '[no-topics]'
    assert_includes sections.fetch('## Other Lists'), '[unmatched]'
    %w[awesome-machine-learning analysis python collections unmatched no-topics].each do |name|
      assert_equal 1, response.body.scan("[#{name}](https://github.com/example/#{name})").length
    end
    assert_not_includes response.body, '### Awesome Lists Topic Lists'
    assert_not_includes response.body, '### Hacktoberfest Topic Lists'
  end

  test 'normalizes description whitespace and punctuation without changing stored descriptions' do
    descriptions = {
      "  useful\nresources  " => 'Useful resources.',
      'useful resources!' => 'Useful resources!',
      'useful resources?' => 'Useful resources?',
      'useful resources...' => 'Useful resources.',
      'useful resources https://example.com' => 'Useful resources.',
      'github and javascript resources' => 'GitHub and JavaScript resources.',
      'macOS resources' => 'macOS resources.'
    }
    lists = descriptions.each_with_index.map do |(source, expected), index|
      [markdown_list("description-#{index}", description: source), source, expected]
    end

    get '/lists/markdown'

    assert_response :success
    lists.each do |list, source, expected|
      assert_includes response.body, "- [#{list.name}](#{list.url}) - #{expected}\n"
      assert_equal source, list.reload.description
    end
  end

  test 'invalidates cached markdown when topic names change' do
    topic = Topic.create!(slug: 'machine-learning', name: 'Machine Learning')
    markdown_list('awesome-machine-learning', metadata: { 'topics' => [topic.slug] })
    get '/lists/markdown'
    etag = response.headers['ETag']

    get '/lists/markdown', headers: { 'If-None-Match' => etag }
    assert_response :not_modified

    topic.update!(name: 'Machine learning resources')
    get '/lists/markdown', headers: { 'If-None-Match' => etag }
    assert_response :success
    assert_includes response.body, '### Machine learning resources Topic Lists'
  end

  test 'topic table of contents disambiguates names with the same heading anchor' do
    Topic.create!(slug: 'csharp', name: 'C#')
    Topic.create!(slug: 'cplusplus', name: 'C++')
    markdown_list('sharp', metadata: { 'topics' => ['csharp'] })
    markdown_list('plus', metadata: { 'topics' => ['cplusplus'] })

    get '/lists/markdown'

    assert_response :success
    assert_includes response.body, '[C++ Topic Lists](#c-topic-lists)'
    assert_includes response.body, '[C# Topic Lists](#c-topic-lists-1)'
  end

  def markdown_list(name, stars: 100, owner: 'example', language: nil, list_of_lists: false, description: 'Useful resources', metadata: {})
    create(:list, url: "https://github.com/#{owner}/#{name}", projects_count: 40,
      primary_language: language, list_of_lists: list_of_lists,
      repository: { 'fork' => false, 'archived' => false, 'description' => description,
                    'stargazers_count' => stars }.merge(metadata))
  end
end
