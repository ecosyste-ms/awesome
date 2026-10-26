require 'test_helper'

class ReadmeParserTest < ActiveSupport::TestCase
  def setup
    @readme = <<-README
## Category 1
### Sub-Category 1
- [Link 1](http://example.com/1) - Description 1
### Sub-Category 2
- [Link 2](http://example.com/2) - Description 2
## Category 2
### Sub-Category 3
- [Link 3](http://example.com/3) - Description 3
  README
    @parser = ReadmeParser.new(@readme)
  end
  
  def test_parse_links
    expected_links = {
      'Category 1' => {
        'Sub-Category 1' => [
          { name: 'Link 1', url: 'http://example.com/1', description: 'Description 1' }
        ],
        'Sub-Category 2' => [
          { name: 'Link 2', url: 'http://example.com/2', description: 'Description 2' }
        ]
      },
      'Category 2' => {
        'Sub-Category 3' => [
          { name: 'Link 3', url: 'http://example.com/3', description: 'Description 3' }
        ]
      }
    }
    assert_equal expected_links, @parser.parse_links
  end

  def test_parse_links_with_no_links
    parser = ReadmeParser.new('No links here')
    assert_equal({}, parser.parse_links)
  end

  def test_readme_with_no_categories
    readme = <<-README
- [Link 1](http://example.com/1) - Description 1
  - [Link 2](http://example.com/2) - Description 2
    README
    parser = ReadmeParser.new(readme)
    expected_links = {
      'Uncategorized' => {
        'Uncategorized' => [
          { name: 'Link 1', url: 'http://example.com/1', description: 'Description 1' },
          { name: 'Link 2', url: 'http://example.com/2', description: 'Description 2' }
        ]
      }
    }
    assert_equal expected_links, parser.parse_links
  end

  test 'table descriptions come from their own column and preserve hyphens and inline links' do
    markdown = <<~'MARKDOWN'
      ## APIs
      | API | Auth | Description | HTTPS |
      | --- | --- | --- | --- |
      | [Bug Bounty](https://example.com/bugs) | No | Write-ups and [guides](https://example.com/a_(b)). | Yes |
      | [Animals](https://example.com/animals) | No | Cats \| dogs | Yes |
    MARKDOWN
    entries = ReadmeParser.new(markdown).parse_links.fetch('APIs').fetch(nil)
    assert_equal ['Bug Bounty', 'Animals'], entries.map { |entry| entry[:name] }
    assert_match(/\AWrite-ups and \[guides\]/, entries.first[:description])
    assert_equal 'Cats | dogs', entries.last[:description]
  end

  test 'resets subcategories and excludes code blocks badges prose and license entries' do
    markdown = <<~MARKDOWN
      ## Software
      ### Wikis
      - [Wiki](https://example.com/wiki) - A wiki
      ```markdown
      - [Fake](https://example.com/fake) - Example code
      ```
      [Analytics](https://example.com/analytics) is a subject.
      - [![Badge](https://example.com/badge.svg)](https://example.com/badge)
      ## External Links
      - [Forum](https://example.com/forum) - A forum
      ## List of Licenses
      - [MIT](https://example.com/license)
      ## More
      - [Next](https://example.com/next)
    MARKDOWN
    links = ReadmeParser.new(markdown).parse_links
    assert_equal ['Wiki'], links.fetch('Software').fetch('Wikis').map { |entry| entry[:name] }
    assert_equal [nil], links.fetch('External Links').keys
    assert_not links.key?('List of Licenses')
    assert_equal 'Next', links.fetch('More').fetch(nil).first[:name]
  end

  test 'resolves reference links and preserves description markup and parentheses in URLs' do
    markdown = <<~MARKDOWN
      - **[Example][project]** - Read the [source][source] and use `MIT`.

      [project]: https://example.com/a_(b)
      [source]: https://example.com/source
    MARKDOWN
    entry = ReadmeParser.new(markdown).parse_links.fetch('Uncategorized').fetch('Uncategorized').first
    assert_equal 'Example', entry[:name]
    assert_equal 'https://example.com/a_(b)', entry[:url]
    assert_equal 'Read the [source](https://example.com/source) and use `MIT`.', entry[:description]
  end
end
