require "test_helper"
require "webmock/minitest"

class LlmServiceTest < ActiveSupport::TestCase
  def setup
    # Mock credentials
    Rails.application.credentials.stubs(:dig).with(:openai, :api_key).returns("test-openai-key")
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns(nil)
  end

  # Provider selection tests
  test "uses openai when openai key is configured" do
    Rails.application.credentials.stubs(:dig).with(:openai, :api_key).returns("test-key")
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns(nil)
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: "Hello!" } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [OpenStruct.new(role: "user", content: "Hi")]
    response = LlmService.chat(messages)
    
    assert_equal "Hello!", response
  end

  test "uses anthropic when only anthropic key is configured" do
    Rails.application.credentials.stubs(:dig).with(:openai, :api_key).returns(nil)
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")
    
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: { content: [{ text: "Hola!" }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [OpenStruct.new(role: "user", content: "Hi")]
    response = LlmService.chat(messages, provider: :anthropic)
    
    assert_equal "Hola!", response
  end

  test "raises error when no provider configured" do
    Rails.application.credentials.stubs(:dig).with(:openai, :api_key).returns(nil)
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns(nil)
    
    messages = [OpenStruct.new(role: "user", content: "Hi")]
    
    assert_raises(RuntimeError) do
      LlmService.chat(messages)
    end
  end

  test "raises error for unknown provider" do
    messages = [OpenStruct.new(role: "user", content: "Hi")]
    
    assert_raises(RuntimeError) do
      LlmService.chat(messages, provider: :unknown)
    end
  end

  # OpenAI tests
  test "openai chat sends correct request format" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(
        body: hash_including(
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: "Hello" }]
        )
      )
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: "Hi there!" } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [OpenStruct.new(role: "user", content: "Hello")]
    LlmService.chat(messages, provider: :openai)
    
    assert_requested :post, "https://api.openai.com/v1/chat/completions"
  end

  test "openai handles API errors gracefully" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 500, body: { error: "Server error" }.to_json)

    messages = [OpenStruct.new(role: "user", content: "Hello")]
    response = LlmService.chat(messages, provider: :openai)
    
    assert_match /error/i, response
  end

  # Anthropic tests
  test "anthropic chat extracts system message" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")
    
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(
        body: hash_including(
          system: "You are a tutor",
          messages: [{ role: "user", content: "Hello" }]
        )
      )
      .to_return(
        status: 200,
        body: { content: [{ text: "Hi!" }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [
      OpenStruct.new(role: "system", content: "You are a tutor"),
      OpenStruct.new(role: "user", content: "Hello")
    ]
    LlmService.chat(messages, provider: :anthropic)
    
    assert_requested :post, "https://api.anthropic.com/v1/messages"
  end

  test "anthropic handles API errors gracefully" do
    Rails.application.credentials.stubs(:dig).with(:anthropic, :api_key).returns("test-key")
    
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: { error: "Server error" }.to_json)

    messages = [OpenStruct.new(role: "user", content: "Hello")]
    response = LlmService.chat(messages, provider: :anthropic)
    
    assert_match /error/i, response
  end

  # Options tests
  test "respects custom model option" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(body: hash_including(model: "gpt-4o"))
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: "Hello" } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [OpenStruct.new(role: "user", content: "Hi")]
    LlmService.chat(messages, provider: :openai, model: "gpt-4o")
    
    assert_requested :post, "https://api.openai.com/v1/chat/completions"
  end

  test "respects max_tokens option" do
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(body: hash_including(max_tokens: 1000))
      .to_return(
        status: 200,
        body: { choices: [{ message: { content: "Hello" } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    messages = [OpenStruct.new(role: "user", content: "Hi")]
    LlmService.chat(messages, provider: :openai, max_tokens: 1000)
    
    assert_requested :post, "https://api.openai.com/v1/chat/completions"
  end
end
