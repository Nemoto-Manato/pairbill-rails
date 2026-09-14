class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false, limit: 30
      t.string :title, null: false, limit: 100
      t.string :message, null: false, limit: 255
      t.bigint :related_claim_id
      t.bigint :related_settlement_id
      t.boolean :read, null: false, default: false
      t.datetime :read_at

      t.datetime :created_at, null: false
    end
    add_index :notifications, :read
    add_foreign_key :notifications, :claims, column: :related_claim_id
    add_foreign_key :notifications, :settlements, column: :related_settlement_id
  end
end
