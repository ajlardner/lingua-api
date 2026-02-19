require "test_helper"

class FlashcardTest < ActiveSupport::TestCase
  # === Basic Validations ===
  
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
    assert_equal flashcard.deck.user, flashcard.user
  end

  test "ease_factor cannot be less than 1.3" do
    flashcard = build(:flashcard, ease_factor: 1.2)
    assert_not flashcard.valid?
  end

  test "interval cannot be negative" do
    flashcard = build(:flashcard, interval: -1)
    assert_not flashcard.valid?
  end

  # === SM-2 Algorithm Tests ===

  test "new flashcard has default SM-2 values" do
    flashcard = create(:flashcard)
    assert_equal 2.5, flashcard.ease_factor
    assert_equal 0, flashcard.interval
    assert_equal 0, flashcard.review_count
    assert_equal Date.current, flashcard.next_review_at
  end

  test "record_review with quality 5 (perfect)" do
    flashcard = create(:flashcard)
    flashcard.record_review(5)

    assert_equal 1, flashcard.review_count
    assert_equal 1, flashcard.interval # First review = 1 day
    assert_equal Date.current + 1.day, flashcard.next_review_at
    assert_in_delta 2.6, flashcard.ease_factor, 0.01 # EF increases
  end

  test "record_review with quality 3 (barely correct)" do
    flashcard = create(:flashcard)
    flashcard.record_review(3)

    assert_equal 1, flashcard.review_count
    assert_equal 1, flashcard.interval
    assert_in_delta 2.36, flashcard.ease_factor, 0.01 # EF decreases
  end

  test "record_review with quality 2 (failed) resets interval" do
    flashcard = create(:flashcard, interval: 10, review_count: 5)
    flashcard.record_review(2)

    assert_equal 6, flashcard.review_count
    assert_equal 0, flashcard.interval # Reset!
    assert_equal Date.current, flashcard.next_review_at # Review again today
  end

  test "record_review with quality 0 (blackout) resets interval" do
    flashcard = create(:flashcard, interval: 30)
    flashcard.record_review(0)

    assert_equal 0, flashcard.interval
    assert_equal Date.current, flashcard.next_review_at
  end

  test "second successful review sets interval to 6 days" do
    flashcard = create(:flashcard, review_count: 1, interval: 1)
    flashcard.record_review(4)

    assert_equal 2, flashcard.review_count
    assert_equal 6, flashcard.interval
  end

  test "third+ review multiplies interval by ease factor" do
    flashcard = create(:flashcard, review_count: 2, interval: 6, ease_factor: 2.5)
    flashcard.record_review(4)

    assert_equal 3, flashcard.review_count
    assert_equal 15, flashcard.interval # 6 * 2.5 = 15
  end

  test "ease factor never drops below 1.3" do
    flashcard = create(:flashcard, ease_factor: 1.4)
    # Quality 0 gives maximum penalty
    flashcard.record_review(0)
    
    assert_equal 1.3, flashcard.ease_factor
  end

  test "record_review raises error for invalid quality" do
    flashcard = create(:flashcard)
    
    assert_raises(ArgumentError) { flashcard.record_review(-1) }
    assert_raises(ArgumentError) { flashcard.record_review(6) }
    assert_raises(ArgumentError) { flashcard.record_review("high") }
  end

  test "record_review sets last_reviewed_at" do
    flashcard = create(:flashcard)
    assert_nil flashcard.last_reviewed_at

    flashcard.record_review(4)
    assert_not_nil flashcard.last_reviewed_at
    assert_in_delta Time.current, flashcard.last_reviewed_at, 2.seconds
  end

  # === Due Date Methods ===

  test "due? returns true when next_review_at is today or past" do
    flashcard = create(:flashcard, next_review_at: Date.current)
    assert flashcard.due?

    flashcard.update!(next_review_at: Date.current - 1.day)
    assert flashcard.due?
  end

  test "due? returns false when next_review_at is future" do
    flashcard = create(:flashcard, next_review_at: Date.current + 1.day)
    assert_not flashcard.due?
  end

  test "due_today? returns true only for today" do
    flashcard = create(:flashcard, next_review_at: Date.current)
    assert flashcard.due_today?

    flashcard.update!(next_review_at: Date.current - 1.day)
    assert_not flashcard.due_today?
  end

  test "overdue? returns true for past dates" do
    flashcard = create(:flashcard, next_review_at: Date.current - 1.day)
    assert flashcard.overdue?

    flashcard.update!(next_review_at: Date.current)
    assert_not flashcard.overdue?
  end

  test "days_until_review calculates correctly" do
    flashcard = create(:flashcard, next_review_at: Date.current + 5.days)
    assert_equal 5, flashcard.days_until_review

    flashcard.update!(next_review_at: Date.current - 2.days)
    assert_equal(-2, flashcard.days_until_review)
  end

  # === Scopes ===

  test "due scope returns cards due for review" do
    due_card = create(:flashcard, next_review_at: Date.current)
    overdue_card = create(:flashcard, next_review_at: Date.current - 3.days)
    future_card = create(:flashcard, next_review_at: Date.current + 1.day)

    due_cards = Flashcard.due
    assert_includes due_cards, due_card
    assert_includes due_cards, overdue_card
    assert_not_includes due_cards, future_card
  end

  test "due_today scope returns only today's cards" do
    today_card = create(:flashcard, next_review_at: Date.current)
    overdue_card = create(:flashcard, next_review_at: Date.current - 1.day)

    assert_includes Flashcard.due_today, today_card
    assert_not_includes Flashcard.due_today, overdue_card
  end

  test "overdue scope returns only past-due cards" do
    overdue_card = create(:flashcard, next_review_at: Date.current - 1.day)
    today_card = create(:flashcard, next_review_at: Date.current)

    assert_includes Flashcard.overdue, overdue_card
    assert_not_includes Flashcard.overdue, today_card
  end

  # === Edge Cases ===

  test "front and back text can be very long" do
    flashcard = build(:flashcard,
                      front_text: "A" * 1000,
                      back_text: "B" * 1000)
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
end
