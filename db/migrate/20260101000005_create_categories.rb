class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :category_name, null: false, limit: 30
      t.integer :display_order, null: false
      t.boolean :enabled, null: false, default: true
    end
    add_index :categories, :category_name, unique: true
  end
end
