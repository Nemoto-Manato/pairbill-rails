class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :display_name, null: false, limit: 50
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
