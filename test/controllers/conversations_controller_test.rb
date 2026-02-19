require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @conversation = create(:conversation, user: @user, title: "Spanish Practice")
    @headers = auth_headers(@user)
  end

  # === Index ===

  test "should get index" do
    get conversations_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |c| c["id"] == @conversation.id }
  end

  test "should only show current users conversations" do
    other_user = create(:user)
    other_conversation = create(:conversation, user: other_user)

    get conversations_url, headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    ids = json.map { |c| c["id"] }

    assert_includes ids, @conversation.id
    assert_not_includes ids, other_conversation.id
  end

  test "should require auth for index" do
    get conversations_url
    assert_response :unauthorized
  end

  # === Show ===

  test "should show conversation" do
    get conversation_url(@conversation), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @conversation.id, json["id"]
    assert_equal "Spanish Practice", json["title"]
  end

  test "show includes messages" do
    create(:message, conversation: @conversation, role: "user", content: "Hello")
    create(:message, conversation: @conversation, role: "assistant", content: "Hola!")

    get conversation_url(@conversation), headers: @headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["messages"].length
  end

  test "should not show other users conversation" do
    other_user = create(:user)
    other_conversation = create(:conversation, user: other_user)

    get conversation_url(other_conversation), headers: @headers
    assert_response :not_found
  end

  # === Create ===

  test "should create conversation" do
    assert_difference("Conversation.count") do
      post conversations_url, params: { title: "French Practice" }, headers: @headers
    end

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "French Practice", json["title"]
  end

  test "created conversation belongs to current user" do
    post conversations_url, params: { title: "My Chat" }, headers: @headers
    assert_response :created

    conversation = Conversation.last
    assert_equal @user.id, conversation.user_id
  end

  test "should create conversation linked to deck" do
    deck = create(:deck, user: @user)

    post conversations_url, params: { title: "Deck Practice", deck_id: deck.id }, headers: @headers
    assert_response :created

    json = JSON.parse(response.body)
    assert_equal deck.id, json["deck_id"]
  end

  test "should not link to another users deck" do
    other_user = create(:user)
    other_deck = create(:deck, user: other_user)

    post conversations_url, params: { deck_id: other_deck.id }, headers: @headers
    assert_response :unprocessable_entity
  end

  test "should create conversation without title or deck" do
    assert_difference("Conversation.count") do
      post conversations_url, params: {}, headers: @headers
    end

    assert_response :created
  end

  # === Destroy ===

  test "should destroy conversation" do
    assert_difference("Conversation.count", -1) do
      delete conversation_url(@conversation), headers: @headers
    end

    assert_response :no_content
  end

  test "should not destroy other users conversation" do
    other_user = create(:user)
    other_conversation = create(:conversation, user: other_user)

    assert_no_difference("Conversation.count") do
      delete conversation_url(other_conversation), headers: @headers
    end

    assert_response :not_found
  end
end
