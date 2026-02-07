require "test_helper"

class Api::V1::MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "password123")
    @token = @user.generate_jwt
    @headers = { "Authorization" => "Bearer #{@token}" }
    
    @conversation = Conversation.create!(user: @user)
    @conversation.messages.create!(role: "system", content: "You are a Spanish tutor")
    @assistant_msg = @conversation.messages.create!(
      role: "assistant", 
      content: "¡Hola (Hello)! ¿Cómo estás (How are you)?"
    )
  end

  # Index Tests
  test "should get messages for conversation" do
    get api_v1_conversation_messages_url(@conversation), headers: @headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 1, json["messages"].length # Only assistant, not system
  end

  test "should not include system messages" do
    get api_v1_conversation_messages_url(@conversation), headers: @headers
    
    json = JSON.parse(response.body)
    roles = json["messages"].map { |m| m["role"] }
    assert_not_includes roles, "system"
  end

  test "should return messages in chronological order" do
    @conversation.messages.create!(role: "user", content: "Estoy bien")
    @conversation.messages.create!(role: "assistant", content: "¡Muy bien!")
    
    get api_v1_conversation_messages_url(@conversation), headers: @headers
    
    json = JSON.parse(response.body)
    # First should be the original assistant message
    assert_equal @assistant_msg.id, json["messages"][0]["id"]
  end

  test "should not get messages without auth" do
    get api_v1_conversation_messages_url(@conversation)
    assert_response :unauthorized
  end

  test "should not get messages for other users conversation" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_conv = Conversation.create!(user: other_user)
    
    get api_v1_conversation_messages_url(other_conv), headers: @headers
    assert_response :not_found
  end

  # Create Tests - These require LLM mocking, so basic structure tests
  test "should require content parameter" do
    # This would normally fail due to LLM call, but tests the validation
    # In a real test, we'd mock LlmService.chat
    assert_raises(ActiveRecord::RecordInvalid) do
      post api_v1_conversation_messages_url(@conversation),
           params: { content: "" },
           headers: @headers
    end
  end

  # Message response format
  test "message response includes required fields" do
    get api_v1_conversation_messages_url(@conversation), headers: @headers
    
    json = JSON.parse(response.body)
    message = json["messages"][0]
    
    assert_includes message.keys, "id"
    assert_includes message.keys, "role"
    assert_includes message.keys, "content"
    assert_includes message.keys, "created_at"
  end

  # Vocabulary extraction tests (unit test the helper method)
  test "extracts vocabulary from response text" do
    controller = Api::V1::MessagesController.new
    
    text = "¡Hola (Hello)! ¿Cómo (How) estás (are you)?"
    suggestions = controller.send(:extract_flashcard_suggestions, text)
    
    assert_equal 3, suggestions.length
    assert_includes suggestions.map { |s| s[:front_text] }, "Hola"
    assert_includes suggestions.map { |s| s[:back_text] }, "Hello"
  end

  test "deduplicates vocabulary suggestions" do
    controller = Api::V1::MessagesController.new
    
    text = "Hola (Hello) and hola (Hello again)"
    suggestions = controller.send(:extract_flashcard_suggestions, text)
    
    # Should dedupe by front_text (case insensitive)
    hola_count = suggestions.count { |s| s[:front_text].downcase == "hola" }
    assert_equal 1, hola_count
  end

  test "handles unicode characters in vocabulary" do
    controller = Api::V1::MessagesController.new
    
    text = "Niño (Child) and señora (Mrs.)"
    suggestions = controller.send(:extract_flashcard_suggestions, text)
    
    assert_includes suggestions.map { |s| s[:front_text] }, "Niño"
    assert_includes suggestions.map { |s| s[:front_text] }, "señora"
  end
end
