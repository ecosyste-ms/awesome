require "test_helper"

class TopicTest < ActiveSupport::TestCase
  test "categories aggregates list_project categories across matching lists in one query" do
    topic = Topic.create!(slug: 'agg-topic', name: 'Agg', github_count: 100)

    list1 = create(:list, keywords: ['agg-topic']).tap { |l| l.update_column(:displayable, true) }
    list2 = create(:list, keywords: ['agg-topic']).tap { |l| l.update_column(:displayable, true) }
    hidden = create(:list, keywords: ['agg-topic']).tap { |l| l.update_column(:displayable, false) }
    other = create(:list, keywords: ['other']).tap { |l| l.update_column(:displayable, true) }

    create(:list_project, list: list1, category: 'Tools')
    create(:list_project, list: list1, category: 'Tools')
    create(:list_project, list: list2, category: 'Tools')
    create(:list_project, list: list2, category: 'Libs')
    create(:list_project, list: hidden, category: 'Hidden')
    create(:list_project, list: other, category: 'Other')
    create(:list_project, list: list1, category: nil)

    Rails.cache.delete("topic_categories/agg-topic")
    result = topic.categories

    assert_equal [['Tools', 3], ['Libs', 1]], result
  end

  test "categories fetches through cache keyed on slug" do
    topic = Topic.create!(slug: 'cache-topic', name: 'Cache', github_count: 100)
    Rails.cache.expects(:fetch).with("topic_categories/cache-topic", expires_in: 1.day).returns([['Cached', 99]])
    assert_equal [['Cached', 99]], topic.categories
  end
end
