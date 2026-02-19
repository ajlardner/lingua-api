class CreateDecks < ActiveRecord::Migration[8.1]
  def change
    create_table :decks do |t|
      t.timestamps
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
    end
  end
end
