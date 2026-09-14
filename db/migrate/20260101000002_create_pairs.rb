class CreatePairs < ActiveRecord::Migration[8.1]
  def change
    create_table :pairs do |t|
      t.string :pair_name, null: false, limit: 50
      t.bigint :created_by, null: false

      t.timestamps
    end
    add_foreign_key :pairs, :users, column: :created_by
  end
end
