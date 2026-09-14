class CreatePairMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :pair_members do |t|
      t.references :pair, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.datetime :joined_at, null: false
    end
    add_index :pair_members, [ :pair_id, :user_id ], unique: true
    add_index :pair_members, :user_id, unique: true
  end
end
