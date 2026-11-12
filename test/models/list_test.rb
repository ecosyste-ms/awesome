require 'test_helper'

class ListTest < ActiveSupport::TestCase
  test 'detects the natural language of the README' do
    list = List.new(url: 'https://github.com/example/awesome-python-cn', readme: <<~README)
      # 精选 Python 资源

      一个精选的 Python 框架、库、软件和资源列表，帮助开发者快速找到需要的工具。

      ## Web 框架

      - [Django](https://github.com/django/django) - 一个高级的 Python Web 框架，鼓励快速开发和干净实用的设计。
      - [Flask](https://github.com/pallets/flask) - 一个轻量级的 Python Web 应用框架，易于上手并且可以扩展。
    README

    assert_equal 'zh', list.detect_natural_language
    assert_equal Encoding::UTF_8, list.detect_natural_language.encoding
  end

  test 'ignores code and URLs when detecting the natural language' do
    list = List.new(url: 'https://github.com/example/awesome-ruby-pt', readme: <<~README)
      # Ruby incrível

      Uma lista de bibliotecas e ferramentas para quem trabalha com Ruby.

      - [Rails](https://github.com/rails/rails) - Um framework web completo. Documentação: https://guides.rubyonrails.org/getting_started_with_rails_for_people_who_write_english_words.html

      ```ruby
      # Install the gem and then require it at the top of the file before using any of the helpers
      puts 'This is an English example that only contains code and should be ignored by the detection'
      ```

      Run `gem install rails --pre and then read the official getting started guide`.
    README

    assert_equal 'pt', list.detect_natural_language
  end

  test 'falls back to the description when the README has no prose' do
    list = List.new(url: 'https://github.com/example/awesome', readme: "```\nnpm install\n```\n", description: 'Список полезных ресурсов и инструментов для разработчиков')

    assert_equal 'ru', list.detect_natural_language
  end

  test 'does not guess the natural language without any prose' do
    assert_nil List.new(url: 'https://github.com/example/awesome', readme: "1234\n\n![badge](https://example.com/badge.svg)").detect_natural_language
    assert_nil List.new(url: 'https://github.com/example/awesome').detect_natural_language
  end

  test 'filters lists by natural language regardless of letter case' do
    traditional = create(:list, natural_language: 'zh-TW')
    create(:list, natural_language: 'zh')
    create(:list, natural_language: nil)

    assert_equal [traditional], List.natural_language('ZH-tw').to_a
  end
end
