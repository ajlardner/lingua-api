require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid" do
    user = create(:user)
    assert user.valid?
  end

  test "should have an email" do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test "should have a unique email" do
    user1 = create(:user)
    user2 = build(:user, email: user1.email)
    assert_not user2.valid?
  end

  # Association tests
  test "has many decks" do
    user = create(:user)
    assert_respond_to user, :decks
  end

  test "has many conversations" do
    user = create(:user)
    assert_respond_to user, :conversations
  end

  test "has many flashcards through decks" do
    user = create(:user)
    deck = create(:deck, user: user)
    flashcard = create(:flashcard, deck: deck)
    assert user.flashcards.include?(flashcard)
  end

  # Edge case tests
  test "email with special characters is valid" do
    user = build(:user, email: "user+tag@example.co.uk")
    assert user.valid?
  end

  test "password confirmation must match" do
    user = build(:user, password: "password123", password_confirmation: "different")
    assert_not user.valid?
  end
end
