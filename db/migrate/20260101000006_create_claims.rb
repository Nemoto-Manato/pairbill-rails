class CreateClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :claims do |t|
      t.references :pair, null: false, foreign_key: true
      t.bigint :claimant_id, null: false
      t.bigint :recipient_id, null: false
      t.references :category, null: false, foreign_key: true
      t.date :expense_date, null: false
      t.integer :amount, null: false
      t.string :description, null: false, limit: 100
      t.string :status, null: false, limit: 20
      t.string :rejection_reason, limit: 100
      t.datetime :responded_at

      t.timestamps
    end
    add_index :claims, :expense_date
    add_index :claims, :status
    add_foreign_key :claims, :users, column: :claimant_id
    add_foreign_key :claims, :users, column: :recipient_id
  end
end
