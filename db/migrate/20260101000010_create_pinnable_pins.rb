# Portable types only (string/text/integer/datetime) — no JSONB — so the engine runs
# identically on SQLite, MySQL, and Postgres. The anchor blob is JSON-serialized text.
# author/tenant/resolved_by are polymorphic with string id columns to tolerate any host
# primary-key type (bigint or uuid).
class CreatePinnablePins < ActiveRecord::Migration[8.0]
  def change
    create_table :pinnable_pins do |t|
      t.string :public_id, null: false

      t.string :author_type
      t.string :author_id
      t.string :author_label

      t.string :tenant_type
      t.string :tenant_id

      t.string :url, null: false
      t.text :body
      t.text :anchor

      t.integer :status, null: false, default: 0
      t.string :resolved_by_type
      t.string :resolved_by_id
      t.string :resolved_by_label
      t.datetime :resolved_at

      t.string :user_agent

      t.timestamps
    end

    add_index :pinnable_pins, :public_id, unique: true
    add_index :pinnable_pins, %i[tenant_type tenant_id]
    add_index :pinnable_pins, :url
    add_index :pinnable_pins, :status
  end
end
