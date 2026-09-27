class CreateShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.integer :quantity, null: false, default: 1
      t.string :memo
      t.string :category, null: false
      t.boolean :is_essential, null: false, default: true
      t.boolean :purchased, null: false, default: false

      t.timestamps
    end
    add_index :shopping_list_items, [ :shopping_list_id, :name ], unique: true
  end
end
