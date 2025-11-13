require "test_helper"

class DeckTest < ActiveSupport::TestCase
  test "should be valid" do
    deck = create(:deck)
    assert deck.valid?
  end

  test "should have a name" do
    deck = build(:deck, name: nil)
    assert_not deck.valid?
  end

  test "should belong to a user" do
    deck = build(:deck, user: nil)
    assert_not deck.valid?
  end

  # Association tests
  test "has many flashcards" do
    deck = create(:deck)
    assert_respond_to deck, :flashcards
  end

  test "destroying deck destroys flashcards" do
    deck = create(:deck)
    flashcard = create(:flashcard, deck: deck)
    assert_equal deck.id, flashcard.deck_id
    assert_difference("Flashcard.count", -1) do
      deck.destroy
    end
  end

  # Edge case tests
  test "deck name can be very long" do
    long_name = "A" * 255
    deck = build(:deck, name: long_name)
    assert deck.valid?
  end

  test "deck name with special characters is valid" do
    deck = build(:deck, name: "Spanish 101 - ¡Hola! ¿Cómo estás?")
    assert deck.valid?
  end

  test "multiple decks can belong to same user" do
    user = create(:user)
    create(:deck, user: user)
    create(:deck, user: user)
    assert_equal 2, user.decks.count
  end
end
