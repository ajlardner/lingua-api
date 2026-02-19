FactoryBot.define do
  factory :conversation do
    association :user
    title { nil }
    deck { nil }
  end
end
