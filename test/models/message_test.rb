require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "should be valid" do
    message = create(:message)
    assert message.valid?
  end

  test "should have a role" do
    message = build(:message, role: nil)
    assert_not message.valid?
  end

  test "should have content" do
    message = build(:message, content: nil)
    assert_not message.valid?
  end

  test "should belong to a conversation" do
    message = build(:message, conversation: nil)
    assert_not message.valid?
  end

  # Edge case tests
  test "message content can be very long" do
    message = build(:message, content: "A" * 10000)
    assert message.valid?
  end

  test "message content with special characters is valid" do
    message = build(:message, content: "Code: def hello_world; puts 'Hello!' end")
    assert message.valid?
  end

  test "message with unicode content is valid" do
    message = build(:message, content: "你好世界 مرحبا العالم")
    assert message.valid?
  end

  test "message role can be different values" do
    conv = create(:conversation)
    user_msg = build(:message, conversation: conv, role: "user")
    assistant_msg = build(:message, conversation: conv, role: "assistant")
    assert user_msg.valid?
    assert assistant_msg.valid?
  end

  test "multiple messages can belong to same conversation" do
    conversation = create(:conversation)
    create(:message, conversation: conversation)
    create(:message, conversation: conversation)
    assert_equal 2, conversation.messages.count
  end
end
