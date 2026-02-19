require "test_helper"

class DecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @deck = create(:deck, user: @user)
    @headers = auth_headers(@user)
  end

  # === Index ===

  test "should get index" do
    get decks_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |d| d["id"] == @deck.id }
  end

  test "should only show current users decks" do
    other_user = create(:user)
    other_deck = create(:deck, user: other_user)

    get decks_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    ids = json.map { |d| d["id"] }
    
    assert_includes ids, @deck.id
    assert_not_includes ids, other_deck.id
  end

  test "should require auth for index" do
    get decks_url
    assert_response :unauthorized
  end

  # === Show ===

  test "should show deck" do
    get deck_url(@deck), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @deck.id, json["id"]
    assert_equal @deck.name, json["name"]
  end

  test "show includes flashcards" do
    create(:flashcard, deck: @deck)
    create(:flashcard, deck: @deck)

    get deck_url(@deck), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["flashcards"].length
  end

  test "should not show other users deck" do
    other_user = create(:user)
    other_deck = create(:deck, user: other_user)

    get deck_url(other_deck), headers: @headers
    assert_response :not_found
  end

  # === Create ===

  test "should create deck" do
    assert_difference("Deck.count") do
      post decks_url, params: {
        deck: { name: "Spanish Vocab" }
      }, headers: @headers
    end

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "Spanish Vocab", json["name"]
  end

  test "created deck belongs to current user" do
    post decks_url, params: {
      deck: { name: "My Deck" }
    }, headers: @headers

    assert_response :created
    
    deck = Deck.last
    assert_equal @user.id, deck.user_id
  end

  test "should not create deck without name" do
    assert_no_difference("Deck.count") do
      post decks_url, params: {
        deck: { name: nil }
      }, headers: @headers
    end

    assert_response :unprocessable_entity
  end

  # === Update ===

  test "should update deck" do
    patch deck_url(@deck), params: {
      deck: { name: "Updated Name" }
    }, headers: @headers

    assert_response :success
    @deck.reload
    assert_equal "Updated Name", @deck.name
  end

  test "should not update other users deck" do
    other_user = create(:user)
    other_deck = create(:deck, user: other_user)

    patch deck_url(other_deck), params: {
      deck: { name: "Hacked" }
    }, headers: @headers

    assert_response :not_found
    other_deck.reload
    assert_not_equal "Hacked", other_deck.name
  end

  # === Destroy ===

  test "should destroy deck" do
    assert_difference("Deck.count", -1) do
      delete deck_url(@deck), headers: @headers
    end

    assert_response :no_content
  end

  # === Study ===

  test "study returns due flashcards" do
    due_card = create(:flashcard, deck: @deck, next_review_at: Date.current)
    future_card = create(:flashcard, deck: @deck, next_review_at: Date.current + 10.days)

    get study_deck_url(@deck), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @deck.id, json["deck"]["id"]
    
    card_ids = json["flashcards"].map { |f| f["id"] }
    assert_includes card_ids, due_card.id
    assert_not_includes card_ids, future_card.id
  end

  test "study respects limit parameter" do
    5.times { create(:flashcard, deck: @deck, next_review_at: Date.current) }

    get study_deck_url(@deck), params: { limit: 3 }, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 3, json["flashcards"].length
  end

  test "study returns cards_due count" do
    3.times { create(:flashcard, deck: @deck, next_review_at: Date.current) }
    2.times { create(:flashcard, deck: @deck, next_review_at: Date.current + 5.days) }

    get study_deck_url(@deck), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    # 3 new cards + any existing from setup
    assert json["cards_due"] >= 3
  end
end
