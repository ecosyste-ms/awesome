FactoryBot.define do
  factory :owner do
    sequence(:name) { |n| "owner-#{n}" }
    hidden { false }

    trait :hidden do
      hidden { true }
    end
  end
end