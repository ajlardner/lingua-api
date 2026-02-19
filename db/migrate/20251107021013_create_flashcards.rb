class CreateFlashcards < ActiveRecord::Migration[8.1]
  def change
    create_table :flashcards do |t|
      t.references :deck, null: false, foreign_key: true
      t.text :front_text, null: false
      t.text :back_text, null: false
      t.integer :review_count, null: false, default: 0
      t.datetime :last_reviewed_at

      # number of days to wait before the next review
      t.integer :interval, null: false, default: 0

      # ease multiplier (starts at 2.5, or 250%)
      t.float :ease_factor, null: false, default: 2.5

      # date this card is due for review.
      # default it to today's date so it's ready for review immediately.
      t.date :next_review_at, null: false, default: -> { 'CURRENT_DATE' }, index: true
      t.timestamps
    end
  end
end
