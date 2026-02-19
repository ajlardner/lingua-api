class AddDeckAndTitleToConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :deck, null: true, foreign_key: true
    add_column :conversations, :title, :string
  end
end
