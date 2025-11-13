# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_08_002815) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "decks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_decks_on_user_id"
  end

  create_table "flashcards", force: :cascade do |t|
    t.bigint "deck_id", null: false
    t.text "back_text", null: false
    t.datetime "created_at", null: false
    t.float "ease_factor", default: 2.5, null: false
    t.text "front_text", null: false
    t.integer "interval", default: 0, null: false
    t.datetime "last_reviewed_at"
    t.date "next_review_at", default: -> { "CURRENT_DATE" }, null: false
    t.integer "review_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["deck_id"], name: "index_flashcards_on_deck_id"
    t.index ["next_review_at"], name: "index_flashcards_on_next_review_at"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "conversations", "users"
  add_foreign_key "decks", "users"
  add_foreign_key "flashcards", "decks"
  add_foreign_key "messages", "conversations"
end
