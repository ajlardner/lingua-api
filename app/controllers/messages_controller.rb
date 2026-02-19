class MessagesController < ApplicationController
  before_action :set_conversation

  # POST /conversations/:conversation_id/messages
  def create
    service = ChatService.new(@conversation)
    assistant_message = service.call(params[:content])

    render json: {
      user_message: @conversation.messages.where(role: "user").order(:created_at).last,
      assistant_message: assistant_message
    }, status: :created
  rescue AiProviders::Error => e
    render json: { error: e.message }, status: :service_unavailable
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end
end
