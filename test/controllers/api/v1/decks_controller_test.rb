require "test_helper"

class Api::V1::DecksControllerTest < ActionDispatch::IntegrationTest
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
      next_review_at: Date.current
    )
  end

  # Index Tests
  test "should get all decks for user" do
    get api_v1_decks_url, headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 1, json["decks"].length
    assert_equal "Spanish Basics", json["decks"][0]["name"]
  end

  test "should include stats in deck list" do
    get api_v1_decks_url, headers: @headers
    
    json = JSON.parse(response.body)
    stats = json["decks"][0]["stats"]
    
    assert_includes stats.keys, "total_cards"
    assert_includes stats.keys, "due_today"
    assert_includes stats.keys, "new_cards"
  end

  test "should not get decks without auth" do
    get api_v1_decks_url
    assert_response :unauthorized
  end

  test "should not show other users decks" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_deck = Deck.create!(name: "Private Deck", user: other_user)
    
    get api_v1_decks_url, headers: @headers
    
    json = JSON.parse(response.body)
    deck_ids = json["decks"].map { |d| d["id"] }
    assert_not_includes deck_ids, other_deck.id
  end

  # Show Tests
  test "should show deck with flashcards" do
    get api_v1_deck_url(@deck), headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal "Spanish Basics", json["deck"]["name"]
    assert_includes json["deck"].keys, "flashcards"
    assert_equal 1, json["deck"]["flashcards"].length
  end

  test "should not show other users deck" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_deck = Deck.create!(name: "Private Deck", user: other_user)
    
    get api_v1_deck_url(other_deck), headers: @headers
    assert_response :not_found
  end

  # Create Tests
  test "should create deck" do
    assert_difference "Deck.count", 1 do
      post api_v1_decks_url,
           params: { name: "French Basics" },
           headers: @headers
    end
    assert_response :created
    
    json = JSON.parse(response.body)
    assert_equal "French Basics", json["deck"]["name"]
  end

  test "should not create deck without name" do
    post api_v1_decks_url,
         params: { name: "" },
         headers: @headers
    assert_response :unprocessable_entity
  end

  # Update Tests
  test "should update deck name" do
    patch api_v1_deck_url(@deck),
          params: { name: "Updated Name" },
          headers: @headers
    assert_response :success
    
    @deck.reload
    assert_equal "Updated Name", @deck.name
  end

  # Delete Tests
  test "should delete deck" do
    assert_difference "Deck.count", -1 do
      delete api_v1_deck_url(@deck), headers: @headers
    end
    assert_response :no_content
  end

  test "should delete associated flashcards when deck deleted" do
    assert_difference "Flashcard.count", -1 do
      delete api_v1_deck_url(@deck), headers: @headers
    end
  end
end
