require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @conversation = create(:conversation, user: @user)
    @headers = auth_headers(@user)
    @original_provider_method = AiClient.method(:provider)
  end

  teardown do
    # Restore original provider method
    AiClient.define_singleton_method(:provider, @original_provider_method) if @original_provider_method
  end

  test "should create message and get AI response" do
    mock_provider = Object.new
    mock_provider.define_singleton_method(:chat) do |messages:, system_prompt:, **|
      "Hola! That means hello in Spanish."
    end
    AiClient.define_singleton_method(:provider) { |_name = nil| mock_provider }

    assert_difference("Message.count", 2) do
      post conversation_messages_url(@conversation),
           params: { content: "How do I say hello?" },
           headers: @headers
    end

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal "user", json["user_message"]["role"]
    assert_equal "How do I say hello?", json["user_message"]["content"]
    assert_equal "assistant", json["assistant_message"]["role"]
    assert_equal "Hola! That means hello in Spanish.", json["assistant_message"]["content"]
  end

  test "should require auth" do
    post conversation_messages_url(@conversation), params: { content: "Hello" }
    assert_response :unauthorized
  end

  test "should not send message to other users conversation" do
    other_user = create(:user)
    other_conversation = create(:conversation, user: other_user)

    post conversation_messages_url(other_conversation),
         params: { content: "Hello" },
         headers: @headers

    assert_response :not_found
  end

  test "should handle AI provider errors" do
    failing_provider = Object.new
    failing_provider.define_singleton_method(:chat) do |messages:, system_prompt:, **|
      raise AiProviders::Error, "API is down"
    end
    AiClient.define_singleton_method(:provider) { |_name = nil| failing_provider }

    post conversation_messages_url(@conversation),
         params: { content: "Hello" },
         headers: @headers

    assert_response :service_unavailable

    json = JSON.parse(response.body)
    assert_match(/API is down/, json["error"])
  end

  test "should include deck context when conversation is linked to deck" do
    deck = create(:deck, user: @user, name: "Spanish Basics")
    create(:flashcard, deck: deck, front_text: "Hello", back_text: "Hola")
    conversation = create(:conversation, user: @user, deck: deck)

    received_prompt = nil
    mock_provider = Object.new
    mock_provider.define_singleton_method(:chat) do |messages:, system_prompt:, **|
      received_prompt = system_prompt
      "Let me help you practice Spanish!"
    end
    AiClient.define_singleton_method(:provider) { |_name = nil| mock_provider }

    post conversation_messages_url(conversation),
         params: { content: "Help me practice" },
         headers: @headers

    assert_response :created
    assert_match(/Spanish Basics/, received_prompt)
    assert_match(/Hello/, received_prompt)
    assert_match(/Hola/, received_prompt)
  end
end
