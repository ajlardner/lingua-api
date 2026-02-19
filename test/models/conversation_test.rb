require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "should be valid" do
    conversation = create(:conversation)
    assert conversation.valid?
  end

  test "should belong to a user" do
    conversation = build(:conversation, user: nil)
    assert_not conversation.valid?
  end

  # Association tests
  test "has many messages" do
    conversation = create(:conversation)
    assert_respond_to conversation, :messages
  end

  test "destroying conversation destroys messages" do
    conversation = create(:conversation)
    message = create(:message, conversation: conversation)
    assert_equal conversation.id, message.conversation_id
    assert_difference("Message.count", -1) do
      conversation.destroy
    end
  end

  # Edge case tests
  test "multiple conversations can belong to same user" do
    user = create(:user)
    conv1 = create(:conversation, user: user)
    conv2 = create(:conversation, user: user)
    assert_equal 2, user.conversations.count
  end

  test "conversation messages are empty on creation" do
    conversation = create(:conversation)
    assert_equal 0, conversation.messages.count
  end

  test "conversation can have multiple messages" do
    conversation = create(:conversation)
    msg1 = create(:message, conversation: conversation)
    msg2 = create(:message, conversation: conversation, role: "assistant")
    assert_equal 2, conversation.messages.count
  end
end
