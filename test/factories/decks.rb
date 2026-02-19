FactoryBot.define do
  factory :deck do
    sequence(:name) { |n| "Deck #{n}" }
    association :user
  end
end
