module AiProviders
  class AnthropicProvider
    include Base

    DEFAULT_MODEL = "claude-sonnet-4-20250514"

    def initialize
      @client = Anthropic::Client.new(
        api_key: Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]
      )
    end

    def chat(messages:, system_prompt:, model: nil)
      api_messages = messages.map { |m| { role: m[:role], content: m[:content] } }

      response = @client.messages(
        model: model || DEFAULT_MODEL,
        max_tokens: 1024,
        system: system_prompt,
        messages: api_messages
      )

      response["content"].first["text"]
    rescue StandardError => e
      raise AiProviders::Error, "Anthropic API error: #{e.message}"
    end
  end
end
