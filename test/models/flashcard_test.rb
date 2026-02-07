require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @deck = Deck.create!(name: "Test Deck", user: @user)
    @flashcard = Flashcard.new(
      front_text: "Hello",
      back_text: "Hola",
      user: @user,
      deck: @deck,
      ease_factor: 2.5,
      interval: 0,
      review_count: 0
    )
  end

  test "should be valid with valid attributes" do
    assert @flashcard.valid?
  end

  test "should require front_text" do
    @flashcard.front_text = nil
    assert_not @flashcard.valid?
  end

  test "should require back_text" do
    @flashcard.back_text = nil
    assert_not @flashcard.valid?
  end

  test "should belong to user" do
    assert_respond_to @flashcard, :user
  end

  test "should belong to deck" do
    assert_respond_to @flashcard, :deck
  end

  # SM-2 Algorithm Tests
  test "first correct review sets interval to 1 day" do
    @flashcard.save!
    @flashcard.process_review(4) # Correct with hesitation
    assert_equal 1, @flashcard.interval
    assert_equal 1, @flashcard.review_count
  end

  test "second correct review sets interval to 6 days" do
    @flashcard.save!
    @flashcard.process_review(4)
    @flashcard.process_review(4)
    assert_equal 6, @flashcard.interval
    assert_equal 2, @flashcard.review_count
  end

  test "third correct review multiplies interval by ease factor" do
    @flashcard.save!
    @flashcard.process_review(4)
    @flashcard.process_review(4)
    @flashcard.process_review(4)
    # interval should be 6 * ease_factor (approximately)
    assert @flashcard.interval > 6
    assert_equal 3, @flashcard.review_count
  end

  test "incorrect review resets interval to 1" do
    @flashcard.save!
    @flashcard.process_review(4)
    @flashcard.process_review(4)
    assert_equal 6, @flashcard.interval
    @flashcard.process_review(1) # Wrong answer
    assert_equal 1, @flashcard.interval
  end

  test "ease factor increases with perfect answers" do
    @flashcard.save!
    original_ease = @flashcard.ease_factor
    @flashcard.process_review(5) # Perfect
    assert @flashcard.ease_factor > original_ease
  end

  test "ease factor decreases with difficult answers" do
    @flashcard.save!
    original_ease = @flashcard.ease_factor
    @flashcard.process_review(3) # Correct with difficulty
    assert @flashcard.ease_factor < original_ease
  end

  test "ease factor minimum is 1.3" do
    @flashcard.ease_factor = 1.3
    @flashcard.save!
    @flashcard.process_review(0) # Complete blackout
    assert @flashcard.ease_factor >= 1.3
  end

  test "sets next_review_at after review" do
    @flashcard.save!
    @flashcard.process_review(4)
    assert_not_nil @flashcard.next_review_at
    assert_equal Date.current + 1.day, @flashcard.next_review_at
  end

  test "sets last_reviewed_at after review" do
    @flashcard.save!
    @flashcard.process_review(4)
    assert_not_nil @flashcard.last_reviewed_at
  end

  # Status Tests
  test "new cards have status :new" do
    @flashcard.save!
    assert_equal :new, @flashcard.status
  end

  test "cards with short interval have status :learning" do
    @flashcard.save!
    @flashcard.update!(review_count: 5, interval: 10)
    assert_equal :learning, @flashcard.status
  end

  test "cards with long interval have status :mature" do
    @flashcard.save!
    @flashcard.update!(review_count: 10, interval: 30)
    assert_equal :mature, @flashcard.status
  end

  # Scope Tests
  test "due_today scope returns cards due for review" do
    @flashcard.save!
    @flashcard.update!(next_review_at: Date.current)
    assert_includes Flashcard.due_today, @flashcard
  end

  test "new_cards scope returns unreviewed cards" do
    @flashcard.save!
    assert_includes Flashcard.new_cards, @flashcard
  end

  # Mastery percentage
  test "mastery_percentage returns 0-100" do
    @flashcard.save!
    mastery = @flashcard.mastery_percentage
    assert mastery >= 0
    assert mastery <= 100
  end
end
