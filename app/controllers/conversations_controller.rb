class ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show, :destroy ]

  # GET /conversations
  def index
    @conversations = current_user.conversations.order(updated_at: :desc)
    render json: @conversations
  end

  # GET /conversations/:id
  def show
    render json: @conversation, include: :messages
  end

  # POST /conversations
  def create
    @conversation = current_user.conversations.build(conversation_params)

    if @conversation.save
      render json: @conversation, status: :created
    else
      render json: { errors: @conversation.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /conversations/:id
  def destroy
    @conversation.destroy
    head :no_content
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end

  def conversation_params
    params.permit(:title, :deck_id)
  end
end
