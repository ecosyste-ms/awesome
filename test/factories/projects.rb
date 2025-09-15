FactoryBot.define do
  factory :project do
    sequence(:url) { |n| "https://github.com/user/project#{n}" }
    repository { {} }
    readme { nil }
    last_synced_at { nil }
    keywords { [] }
    stars { 0 }
    list { false }
    owner { nil }
  end
end