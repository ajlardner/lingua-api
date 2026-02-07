class FlashcardsController < ApplicationController
  before_action :set_deck
  before_action :set_flashcard, only: [:show, :update, :destroy, :review]

  # GET /decks/:deck_id/flashcards
  def index
    @flashcards = @deck.flashcards
    render json: @flashcards
  end

  # GET /decks/:deck_id/flashcards/due
  def due
    @flashcards = @deck.flashcards.due
    render json: @flashcards
  end

  # GET /decks/:deck_id/flashcards/:id
  def show
    render json: @flashcard
  end

  # POST /decks/:deck_id/flashcards
  def create
    @flashcard = @deck.flashcards.build(flashcard_params)

    if @flashcard.save
      render json: @flashcard, status: :created
    else
      render json: { errors: @flashcard.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /decks/:deck_id/flashcards/:id
  def update
    if @flashcard.update(flashcard_params)
      render json: @flashcard
    else
      render json: { errors: @flashcard.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /decks/:deck_id/flashcards/:id
  def destroy
    @flashcard.destroy
    head :no_content
  end

  # POST /decks/:deck_id/flashcards/:id/review
  # Params: { quality: 0-5 }
  def review
    quality = params[:quality].to_i

    unless (0..5).include?(quality)
      return render json: { error: "Quality must be 0-5" }, status: :unprocessable_entity
    end

    @flashcard.record_review(quality)
    render json: {
      flashcard: @flashcard,
      next_review_at: @flashcard.next_review_at,
      interval: @flashcard.interval,
      ease_factor: @flashcard.ease_factor
    }
  end

  private

  def set_deck
    @deck = Deck.find(params[:deck_id])
  end

  def set_flashcard
    @flashcard = @deck.flashcards.find(params[:id])
  end

  def flashcard_params
    params.require(:flashcard).permit(:front_text, :back_text)
  end
end
