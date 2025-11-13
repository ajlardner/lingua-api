require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
  test "should be valid" do
    flashcard = create(:flashcard)
    assert flashcard.valid?
  end

  test "should have front text" do
    flashcard = build(:flashcard, front_text: nil)
    assert_not flashcard.valid?
  end

  test "should have back text" do
    flashcard = build(:flashcard, back_text: nil)
    assert_not flashcard.valid?
  end

  test "should belong to a deck" do
    flashcard = build(:flashcard, deck: nil)
    assert_not flashcard.valid?
  end

  test "should have a user through deck" do
    flashcard = create(:flashcard)
    deck = flashcard.deck
    user = deck.user
    assert_equal user, flashcard.user
  end

  # Edge case tests
  test "front and back text can be very long" do
    flashcard = build(:flashcard,
                      front_text: "A" * 1000,
                      back_text: "B" * 1000)
    assert flashcard.valid?
  end

  test "front and back text with special characters is valid" do
    flashcard = build(:flashcard,
                      front_text: "Math: What is 2 + 2?",
                      back_text: "Answer: 4")
    assert flashcard.valid?
  end

  test "flashcard with unicode characters is valid" do
    flashcard = build(:flashcard,
                      front_text: "日本語: こんにちは",
                      back_text: "English: Hello")
    assert flashcard.valid?
  end

  test "multiple flashcards can belong to same deck" do
    deck = create(:deck)
    create(:flashcard, deck: deck)
    create(:flashcard, deck: deck)
    assert_equal 2, deck.flashcards.count
  end

  test "flashcard user matches deck user" do
    user = create(:user)
    deck = create(:deck, user: user)
    flashcard = create(:flashcard, deck: deck)
    assert_equal user, flashcard.user
  end
end
