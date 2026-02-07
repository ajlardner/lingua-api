require "test_helper"

class DeckTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @deck = Deck.new(name: "Spanish Basics", user: @user)
  end

  test "should be valid with valid attributes" do
    assert @deck.valid?
  end

  test "should require name" do
    @deck.name = nil
    assert_not @deck.valid?
  end

  test "should belong to user" do
    assert_respond_to @deck, :user
  end

  test "should have many flashcards" do
    assert_respond_to @deck, :flashcards
  end

  test "should destroy flashcards when destroyed" do
    @deck.save!
    Flashcard.create!(
      front_text: "Hello",
      back_text: "Hola",
      user: @user,
      deck: @deck
    )
    
    assert_difference "Flashcard.count", -1 do
      @deck.destroy
    end
  end

  # Progress percentage tests
  test "progress_percentage returns 0 for empty deck" do
    @deck.save!
    assert_equal 0, @deck.progress_percentage
  end

  test "progress_percentage calculates average mastery" do
    @deck.save!
    # Create cards with known mastery values
    Flashcard.create!(
      front_text: "Hello",
      back_text: "Hola",
      user: @user,
      deck: @deck,
      ease_factor: 2.5,
      interval: 30
    )
    
    progress = @deck.progress_percentage
    assert progress >= 0
    assert progress <= 100
  end

  # Estimated study time tests
  test "estimated_study_minutes returns reasonable value" do
    @deck.save!
    5.times do |i|
      Flashcard.create!(
        front_text: "Word #{i}",
        back_text: "Palabra #{i}",
        user: @user,
        deck: @deck,
        next_review_at: Date.current
      )
    end
    
    minutes = @deck.estimated_study_minutes
    assert minutes > 0
    assert minutes < 60 # Reasonable for 5 cards
  end

  test "estimated_study_minutes caps new cards at 10" do
    @deck.save!
    20.times do |i|
      Flashcard.create!(
        front_text: "Word #{i}",
        back_text: "Palabra #{i}",
        user: @user,
        deck: @deck,
        review_count: 0
      )
    end
    
    # 20 new cards but capped at 10, so ~5 minutes
    minutes = @deck.estimated_study_minutes
    assert minutes <= 10
  end
end
