require "test_helper"

class FlashcardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @deck = create(:deck)
    @flashcard = create(:flashcard, deck: @deck)
  end

  # === Index ===
  
  test "should get index" do
    get deck_flashcards_url(@deck)
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  # === Due ===

  test "should get due flashcards" do
    due_card = create(:flashcard, deck: @deck, next_review_at: Date.current)
    future_card = create(:flashcard, deck: @deck, next_review_at: Date.current + 5.days)

    get due_deck_flashcards_url(@deck)
    assert_response :success

    json = JSON.parse(response.body)
    ids = json.map { |f| f["id"] }
    
    assert_includes ids, due_card.id
    assert_includes ids, @flashcard.id  # default is today
    assert_not_includes ids, future_card.id
  end

  # === Show ===

  test "should show flashcard" do
    get deck_flashcard_url(@deck, @flashcard)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @flashcard.id, json["id"]
    assert_equal @flashcard.front_text, json["front_text"]
  end

  # === Create ===

  test "should create flashcard" do
    assert_difference("Flashcard.count") do
      post deck_flashcards_url(@deck), params: {
        flashcard: { front_text: "Hello", back_text: "Hola" }
      }
    end

    assert_response :created
    
    json = JSON.parse(response.body)
    assert_equal "Hello", json["front_text"]
    assert_equal "Hola", json["back_text"]
  end

  test "should not create flashcard without front_text" do
    assert_no_difference("Flashcard.count") do
      post deck_flashcards_url(@deck), params: {
        flashcard: { front_text: nil, back_text: "Hola" }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Update ===

  test "should update flashcard" do
    patch deck_flashcard_url(@deck, @flashcard), params: {
      flashcard: { front_text: "Updated front" }
    }
    
    assert_response :success
    @flashcard.reload
    assert_equal "Updated front", @flashcard.front_text
  end

  # === Destroy ===

  test "should destroy flashcard" do
    assert_difference("Flashcard.count", -1) do
      delete deck_flashcard_url(@deck, @flashcard)
    end

    assert_response :no_content
  end

  # === Review ===

  test "should record review with valid quality" do
    post review_deck_flashcard_url(@deck, @flashcard), params: { quality: 4 }
    
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 1, json["flashcard"]["review_count"]
    assert_equal 1, json["interval"]
  end

  test "should fail review with invalid quality" do
    post review_deck_flashcard_url(@deck, @flashcard), params: { quality: 6 }
    
    assert_response :unprocessable_entity
    
    json = JSON.parse(response.body)
    assert_match(/Quality must be 0-5/, json["error"])
  end

  test "review updates next_review_at" do
    original_date = @flashcard.next_review_at
    
    post review_deck_flashcard_url(@deck, @flashcard), params: { quality: 5 }
    
    assert_response :success
    @flashcard.reload
    assert @flashcard.next_review_at > original_date
  end

  test "failed review resets interval" do
    @flashcard.update!(interval: 10, review_count: 5)
    
    post review_deck_flashcard_url(@deck, @flashcard), params: { quality: 1 }
    
    assert_response :success
    @flashcard.reload
    assert_equal 0, @flashcard.interval
    assert_equal Date.current, @flashcard.next_review_at
  end
end
