module AiProviders
  class Error < StandardError; end

  module Base
    # Every provider must implement:
    #   chat(messages:, system_prompt:, model:) -> String
    #
    # messages - Array of hashes: [{ role: "user"/"assistant", content: "..." }, ...]
    # system_prompt - String with system-level instructions
    # model - String, the model name (provider-specific, optional)
    #
    # Returns the assistant's response text as a String.
    # Raises AiProviders::Error on any API failure.
    def chat(messages:, system_prompt:, model: nil)
      raise NotImplementedError, "#{self.class} must implement #chat"
    end
  end
end
