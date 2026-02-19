FactoryBot.define do
  factory :flashcard do
    sequence(:front_text) { |n| "Question #{n}" }
    sequence(:back_text) { |n| "Answer #{n}" }
    association :deck
  end
end
