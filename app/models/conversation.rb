class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy
  belongs_to :user
  belongs_to :deck, optional: true

  validate :deck_belongs_to_user, if: :deck_id?

  private

  def deck_belongs_to_user
    errors.add(:deck, "must belong to you") unless deck&.user_id == user_id
  end
end
