FactoryBot.define do
  factory :list_project do
    association :list
    association :project
    name { "Sample Project" }
    description { "A sample project description" }
    category { "Category" }
    sub_category { nil }
  end
end
