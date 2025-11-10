class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.timestamps
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
    end
  end
end
