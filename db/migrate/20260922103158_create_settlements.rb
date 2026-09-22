class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :household, null: false, foreign_key: true
      # 精算の対象月。その月の1日を保存する(例：2026-09-01)
      t.date :target_month, null: false
      # 支払う人・受け取る人。どちらも users テーブルを参照する
      # 精算額が 0 円の月も記録できるよう、空(null)を許可する
      t.references :from_user, foreign_key: { to_table: :users }
      t.references :to_user, foreign_key: { to_table: :users }
      t.integer :amount, null: false, default: 0
      # 精算を記録した日時
      t.datetime :settled_at, null: false

      t.timestamps
    end
    # 1つの世帯で、同じ月の精算は1件だけ
    add_index :settlements, [ :household_id, :target_month ], unique: true
  end
end
