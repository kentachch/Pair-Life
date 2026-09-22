class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :household, null: false, foreign_key: true
      t.date :target_month, null: false
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.integer :amount, null: false, default: 0
      t.datetime :settled_at, null: false

      t.timestamps
    end
    # 1つの世帯で、同じ月の精算は1件だけ
    add_index :settlements, [ :household_id, :target_month ], unique: true
  end
end
