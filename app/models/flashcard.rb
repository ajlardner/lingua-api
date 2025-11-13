class Flashcard < ApplicationRecord
  belongs_to :deck
  has_one :user, through: :deck

  validates :front_text, :back_text, :deck, presence: true
end
