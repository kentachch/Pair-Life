class AddIconToCategories < ActiveRecord::Migration[8.1]
  def change
    # Lucide(https://lucide.dev)のアイコン名を保存する。例："house"、"shopping-basket"
    # 既存のカテゴリにも値が入るよう、初期値を "tag" にしておく
    add_column :categories, :icon, :string, null: false, default: "tag"
  end
end
