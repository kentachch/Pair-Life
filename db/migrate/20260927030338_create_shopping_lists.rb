class CreateShoppingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_lists do |t|
      t.references :household, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
