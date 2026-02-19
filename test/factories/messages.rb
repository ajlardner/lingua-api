FactoryBot.define do
  factory :message do
    sequence(:content) { |n| "Message content #{n}" }
    role { "user" }
    association :conversation
  end
end
