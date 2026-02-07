require "test_helper"

class Api::V1::FlashcardsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @token = @user.generate_jwt
    @headers = { "Authorization" => "Bearer #{@token}" }
    
    @deck = Deck.create!(name: "Spanish Basics", user: @user)
    @flashcard = Flashcard.create!(
      front_text: "Hello",
      back_text: "Hola",
      user: @user,
      deck: @deck,
      ease_factor: 2.5,
      interval: 0,
      review_count: 0,
      next_review_at: Date.current
    )
  end

  # Index Tests
  test "should get flashcards for deck" do
    get api_v1_deck_flashcards_url(@deck), headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 1, json["flashcards"].length
  end

  test "should not get flashcards without auth" do
    get api_v1_deck_flashcards_url(@deck)
    assert_response :unauthorized
  end

  # Show Tests
  test "should show flashcard" do
    get api_v1_flashcard_url(@flashcard), headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal "Hello", json["flashcard"]["front_text"]
    assert_equal "Hola", json["flashcard"]["back_text"]
  end

  test "should not show other users flashcard" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_deck = Deck.create!(name: "Other Deck", user: other_user)
    other_flashcard = Flashcard.create!(
      front_text: "Goodbye",
      back_text: "Adiós",
      user: other_user,
      deck: other_deck
    )
    
    get api_v1_flashcard_url(other_flashcard), headers: @headers
    assert_response :not_found
  end

  # Create Tests
  test "should create flashcard" do
    assert_difference "Flashcard.count", 1 do
      post api_v1_deck_flashcards_url(@deck), 
           params: { front_text: "Goodbye", back_text: "Adiós" },
           headers: @headers
    end
    assert_response :created
  end

  test "should not create flashcard without front_text" do
    post api_v1_deck_flashcards_url(@deck),
         params: { back_text: "Adiós" },
         headers: @headers
    assert_response :unprocessable_entity
  end

  test "should not create flashcard without back_text" do
    post api_v1_deck_flashcards_url(@deck),
         params: { front_text: "Goodbye" },
         headers: @headers
    assert_response :unprocessable_entity
  end

  # Update Tests
  test "should update flashcard" do
    patch api_v1_flashcard_url(@flashcard),
          params: { front_text: "Hi" },
          headers: @headers
    assert_response :success
    
    @flashcard.reload
    assert_equal "Hi", @flashcard.front_text
  end

  # Delete Tests
  test "should delete flashcard" do
    assert_difference "Flashcard.count", -1 do
      delete api_v1_flashcard_url(@flashcard), headers: @headers
    end
    assert_response :no_content
  end

  # Review Tests
  test "should get review cards" do
    get review_api_v1_flashcards_url, headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_includes json.keys, "flashcards"
    assert_includes json.keys, "total_due"
  end

  test "should not include future cards in review" do
    @flashcard.update!(next_review_at: Date.current + 7.days)
    
    get review_api_v1_flashcards_url, headers: @headers
    json = JSON.parse(response.body)
    
    assert_equal 0, json["flashcards"].length
  end

  # Answer Tests
  test "should process correct answer" do
    post answer_api_v1_flashcard_url(@flashcard),
         params: { quality: 4 },
         headers: @headers
    assert_response :success
    
    @flashcard.reload
    assert_equal 1, @flashcard.review_count
    assert_equal 1, @flashcard.interval
  end

  test "should process incorrect answer" do
    # First get to interval 6
    @flashcard.update!(review_count: 1, interval: 6)
    
    post answer_api_v1_flashcard_url(@flashcard),
         params: { quality: 1 },
         headers: @headers
    assert_response :success
    
    @flashcard.reload
    assert_equal 1, @flashcard.interval # Reset to 1
  end

  test "should reject invalid quality" do
    post answer_api_v1_flashcard_url(@flashcard),
         params: { quality: 6 },
         headers: @headers
    assert_response :unprocessable_entity
  end

  test "should reject negative quality" do
    post answer_api_v1_flashcard_url(@flashcard),
         params: { quality: -1 },
         headers: @headers
    assert_response :unprocessable_entity
  end

  test "answer returns feedback message" do
    post answer_api_v1_flashcard_url(@flashcard),
         params: { quality: 5 },
         headers: @headers
    
    json = JSON.parse(response.body)
    assert_includes json.keys, "message"
    assert_match /excellent/i, json["message"]
  end
end
