class CreatePairInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :pair_invitations do |t|
      t.references :pair, null: false, foreign_key: true
      t.string :invitation_code, null: false, limit: 20
      t.bigint :issued_by, null: false
      t.string :status, null: false, limit: 20
      t.datetime :expires_at, null: false
      t.bigint :used_by
      t.datetime :used_at

      t.timestamps
    end
    add_index :pair_invitations, :invitation_code, unique: true
    add_foreign_key :pair_invitations, :users, column: :issued_by
    add_foreign_key :pair_invitations, :users, column: :used_by
  end
end
