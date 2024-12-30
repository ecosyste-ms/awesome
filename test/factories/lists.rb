FactoryBot.define do
  factory :list do
    sequence(:url) { |n| "https://github.com/lists/#{n}" }
    sequence(:name) { |n| "Sample List #{n}" }
    description { "This is a sample description for a list." }
    projects_count { rand(1..100) }
    last_synced_at { rand(1..30).days.ago }
    repository { { github: "https://github.com/example/repo" } }
    readme { "## Sample Readme Content\nThis is a sample readme." }
    created_at { Time.current }
    updated_at { Time.current }
    primary_language { %w[Ruby Python JavaScript].sample }
    list_of_lists { [true, false].sample }
    displayable { true }
    keywords { %w[open-source awesome example] }
    stars { rand(0..5000) }
  end
end