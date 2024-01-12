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
end