module AiProviders
  class OpenaiProvider
    include Base

    DEFAULT_MODEL = "gpt-4o-mini"

    def initialize
      @client = OpenAI::Client.new(
        access_token: Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]
      )
    end

    def chat(messages:, system_prompt:, model: nil)
      api_messages = []
      api_messages << { role: "system", content: system_prompt } if system_prompt.present?
      api_messages += messages.map { |m| { role: m[:role], content: m[:content] } }

      response = @client.chat(
        parameters: {
          model: model || DEFAULT_MODEL,
          messages: api_messages
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      raise AiProviders::Error, "OpenAI API error: #{e.message}"
    end
  end
end
