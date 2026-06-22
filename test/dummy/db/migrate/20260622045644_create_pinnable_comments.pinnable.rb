# This migration comes from pinnable (originally 20260101000030)
# Replies on a pin — the conversation thread. Portable types; body encrypts at rest when
# the host opts into config.encrypt (it can quote PII just like a pin body).
class CreatePinnableComments < ActiveRecord::Migration[8.0]
  def change
    create_table :pinnable_comments do |t|
      t.references :pin, null: false, foreign_key: { to_table: :pinnable_pins }
      t.string :public_id, null: false
      t.string :author_type
      t.string :author_id
      t.string :author_label
      t.text :body
      t.timestamps
    end

    add_index :pinnable_comments, :public_id, unique: true
  end
end
