class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.timestamps
      t.references :user, null: false, foreign_key: true
    end
  end
end
