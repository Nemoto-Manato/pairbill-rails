class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :pair, null: false, foreign_key: true
      t.date :settlement_month, null: false
      t.bigint :requested_by, null: false
      t.bigint :payer_id
      t.bigint :payee_id
      t.integer :payment_amount, null: false
      t.integer :requester_receivable_total, null: false
      t.integer :partner_receivable_total, null: false
      t.integer :approved_claim_count, null: false
      t.string :status, null: false, limit: 30
      t.datetime :requested_at, null: false
      t.bigint :approved_by
      t.datetime :completed_at
      t.datetime :cancelled_at

      t.timestamps
    end
    add_index :settlements, [ :pair_id, :settlement_month ]
    add_index :settlements, :status
    add_foreign_key :settlements, :users, column: :requested_by
    add_foreign_key :settlements, :users, column: :payer_id
    add_foreign_key :settlements, :users, column: :payee_id
    add_foreign_key :settlements, :users, column: :approved_by
  end
end
