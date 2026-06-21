class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.boolean :admin, null: false, default: false
      t.timestamps
    end
  end
end
