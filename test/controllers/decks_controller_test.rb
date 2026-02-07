require "test_helper"

class DecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @deck = create(:deck, user: @user)
  end

  # === Index ===

  test "should get index" do
    get decks_url
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |d| d["id"] == @deck.id }
  end

  # === Show ===

  test "should show deck" do
    get deck_url(@deck)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @deck.id, json["id"]
    assert_equal @deck.name, json["name"]
  end

  test "show includes flashcards" do
    create(:flashcard, deck: @deck)
    create(:flashcard, deck: @deck)

    get deck_url(@deck)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["flashcards"].length
  end

  # === Create ===

  test "should create deck" do
    assert_difference("Deck.count") do
      post decks_url, params: {
        deck: { name: "Spanish Vocab", user_id: @user.id }
      }
    end

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "Spanish Vocab", json["name"]
  end

  test "should not create deck without name" do
    assert_no_difference("Deck.count") do
      post decks_url, params: {
        deck: { name: nil, user_id: @user.id }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Update ===

  test "should update deck" do
    patch deck_url(@deck), params: {
      deck: { name: "Updated Name" }
    }

    assert_response :success
    @deck.reload
    assert_equal "Updated Name", @deck.name
  end

  # === Destroy ===

  test "should destroy deck" do
    assert_difference("Deck.count", -1) do
      delete deck_url(@deck)
    end

    assert_response :no_content
  end

  # === Study ===

  test "study returns due flashcards" do
    due_card = create(:flashcard, deck: @deck, next_review_at: Date.current)
    future_card = create(:flashcard, deck: @deck, next_review_at: Date.current + 10.days)

    get study_deck_url(@deck)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @deck.id, json["deck"]["id"]
    
    card_ids = json["flashcards"].map { |f| f["id"] }
    assert_includes card_ids, due_card.id
    assert_not_includes card_ids, future_card.id
  end

  test "study respects limit parameter" do
    5.times { create(:flashcard, deck: @deck, next_review_at: Date.current) }

    get study_deck_url(@deck), params: { limit: 3 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 3, json["flashcards"].length
  end

  test "study returns cards_due count" do
    3.times { create(:flashcard, deck: @deck, next_review_at: Date.current) }
    2.times { create(:flashcard, deck: @deck, next_review_at: Date.current + 5.days) }

    get study_deck_url(@deck)
    assert_response :success

    json = JSON.parse(response.body)
    # 3 new cards + any existing from setup
    assert json["cards_due"] >= 3
  end
end
