class DecksController < ApplicationController
  before_action :set_deck, only: [:show, :update, :destroy, :study]

  # GET /decks
  def index
    @decks = Deck.all
    render json: @decks
  end

  # GET /decks/:id
  def show
    render json: @deck, include: :flashcards
  end

  # POST /decks
  def create
    @deck = Deck.new(deck_params)
    # TODO: Set user from authentication
    # @deck.user = current_user

    if @deck.save
      render json: @deck, status: :created
    else
      render json: { errors: @deck.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /decks/:id
  def update
    if @deck.update(deck_params)
      render json: @deck
    else
      render json: { errors: @deck.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /decks/:id
  def destroy
    @deck.destroy
    head :no_content
  end

  # GET /decks/:id/study
  # Returns cards due for review, randomized
  def study
    @flashcards = @deck.flashcards.due.order("RANDOM()").limit(params[:limit] || 20)
    render json: {
      deck: @deck,
      cards_due: @flashcards.count,
      flashcards: @flashcards
    }
  end

  private

  def set_deck
    @deck = Deck.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:name, :user_id)
  end
end
