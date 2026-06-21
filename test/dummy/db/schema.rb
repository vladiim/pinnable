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

ActiveRecord::Schema[8.1].define(version: 2026_06_21_020706) do
  create_table "pinnable_pins", force: :cascade do |t|
    t.text "anchor"
    t.string "author_id"
    t.string "author_label"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "public_id", null: false
    t.datetime "resolved_at"
    t.string "resolved_by_id"
    t.string "resolved_by_label"
    t.string "resolved_by_type"
    t.integer "status", default: 0, null: false
    t.string "tenant_id"
    t.string "tenant_type"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.string "user_agent"
    t.index ["public_id"], name: "index_pinnable_pins_on_public_id", unique: true
    t.index ["status"], name: "index_pinnable_pins_on_status"
    t.index ["tenant_type", "tenant_id"], name: "index_pinnable_pins_on_tenant_type_and_tenant_id"
    t.index ["url"], name: "index_pinnable_pins_on_url"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
  end
end
