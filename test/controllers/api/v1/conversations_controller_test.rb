require "test_helper"

class Api::V1::ConversationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @token = @user.generate_jwt
    @headers = { "Authorization" => "Bearer #{@token}" }
    
    @conversation = Conversation.create!(user: @user)
    @conversation.messages.create!(role: "system", content: "You are a Spanish tutor")
    @conversation.messages.create!(role: "assistant", content: "Hola! ¿Cómo estás?")
  end

  # Index Tests
  test "should get all conversations" do
    get api_v1_conversations_url, headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 1, json["conversations"].length
  end

  test "should include message count and preview" do
    get api_v1_conversations_url, headers: @headers
    
    json = JSON.parse(response.body)
    conv = json["conversations"][0]
    
    assert_includes conv.keys, "message_count"
    assert_includes conv.keys, "preview"
  end

  test "should not get conversations without auth" do
    get api_v1_conversations_url
    assert_response :unauthorized
  end

  test "should not show other users conversations" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_conv = Conversation.create!(user: other_user)
    
    get api_v1_conversations_url, headers: @headers
    
    json = JSON.parse(response.body)
    conv_ids = json["conversations"].map { |c| c["id"] }
    assert_not_includes conv_ids, other_conv.id
  end

  # Show Tests
  test "should show conversation with messages" do
    get api_v1_conversation_url(@conversation), headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_includes json["conversation"].keys, "messages"
    # Should not include system message
    roles = json["conversation"]["messages"].map { |m| m["role"] }
    assert_not_includes roles, "system"
  end

  test "should not show other users conversation" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_conv = Conversation.create!(user: other_user)
    
    get api_v1_conversation_url(other_conv), headers: @headers
    assert_response :not_found
  end

  # Create Tests
  test "should create conversation" do
    assert_difference "Conversation.count", 1 do
      post api_v1_conversations_url,
           params: { language: "Spanish", level: "beginner" },
           headers: @headers
    end
    assert_response :created
  end

  test "should create system message on new conversation" do
    post api_v1_conversations_url,
         params: { language: "French", level: "intermediate" },
         headers: @headers
    
    conv = Conversation.last
    system_message = conv.messages.find_by(role: "system")
    assert_not_nil system_message
    assert_match /French/, system_message.content
    assert_match /intermediate/, system_message.content
  end

  test "should use default language if not specified" do
    post api_v1_conversations_url, headers: @headers
    
    conv = Conversation.last
    system_message = conv.messages.find_by(role: "system")
    assert_match /Spanish/, system_message.content
  end

  # Delete Tests
  test "should delete conversation" do
    assert_difference "Conversation.count", -1 do
      delete api_v1_conversation_url(@conversation), headers: @headers
    end
    assert_response :no_content
  end

  test "should delete messages when conversation deleted" do
    initial_message_count = @conversation.messages.count
    
    delete api_v1_conversation_url(@conversation), headers: @headers
    
    assert_equal 0, Message.where(conversation_id: @conversation.id).count
  end

  test "should not delete other users conversation" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_conv = Conversation.create!(user: other_user)
    
    delete api_v1_conversation_url(other_conv), headers: @headers
    assert_response :not_found
  end
end
