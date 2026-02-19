class User < ApplicationRecord
  has_secure_password
  has_many :decks
  has_many :flashcards, through: :decks
  has_many :conversations

  validates :email, presence: true, uniqueness: true
end
