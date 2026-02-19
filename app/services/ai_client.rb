class AiClient
  PROVIDERS = {
    "anthropic" => AiProviders::AnthropicProvider,
    "openai" => AiProviders::OpenaiProvider
  }.freeze

  def self.provider(name = nil)
    name ||= Rails.application.credentials.dig(:ai, :provider) || ENV["AI_PROVIDER"] || "anthropic"
    klass = PROVIDERS[name.to_s]
    raise ArgumentError, "Unknown AI provider: #{name}. Available: #{PROVIDERS.keys.join(', ')}" unless klass
    klass.new
  end
end
