class ChatService
  def initialize(conversation)
    @conversation = conversation
    @provider = AiClient.provider
  end

  def call(user_message_content)
    # Save the user's message
    @conversation.messages.create!(role: "user", content: user_message_content)

    # Build conversation history for the AI
    messages = @conversation.messages.order(:created_at).map do |msg|
      { role: msg.role, content: msg.content }
    end

    # Call the AI provider
    ai_response_text = @provider.chat(
      messages: messages,
      system_prompt: build_system_prompt
    )

    # Save and return the assistant's response
    @conversation.messages.create!(role: "assistant", content: ai_response_text)
  end

  private

  def build_system_prompt
    prompt = <<~PROMPT
      You are a friendly and encouraging language learning tutor. Your role is to:
      - Help the user practice vocabulary and grammar
      - Quiz them on words they are learning
      - Explain concepts when they are confused
      - Adapt to their level based on their responses
      - Keep the conversation engaging and encouraging
    PROMPT

    deck = @conversation.deck
    if deck
      flashcards = deck.flashcards.limit(100)
      if flashcards.any?
        prompt += "\nThe user is studying the deck \"#{deck.name}\" with these flashcards:\n"
        flashcards.each do |card|
          due_status = card.due? ? " [DUE FOR REVIEW]" : ""
          prompt += "- Front: #{card.front_text} | Back: #{card.back_text}#{due_status}\n"
        end
        prompt += "\nFocus on these words in your conversation. Prioritize cards marked [DUE FOR REVIEW]."
      end
    end

    prompt
  end
end
