class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :household, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.references :category, null: false, foreign_key: true
      t.integer :amount, null: false
      t.date :spent_on, null: false
      t.string :memo

      t.timestamps
    end
    add_index :expenses, [ :household_id, :spent_on ]
    # 「世帯＋日付」の範囲での検索を高速化するためのインデックスを追加
  end
end
