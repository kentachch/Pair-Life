class ShoppingList < ApplicationRecord
  belongs_to :household
  has_many :items, class_name: "ShoppingListItem", dependent: :destroy

  # チェック済みのアイテムをまとめて削除する
  def clear_purchased!
    items.where(purchased: true).destroy_all
  end

  # カテゴリごとに分けたアイテムを、CATEGORIES の順番で返す。アイテムが0件のカテゴリは含めない
  # 例: { "野菜・果物" => [キャベツ, トマト], "乳製品・卵" => [牛乳] }
  # DB の並び替えではカテゴリの順番(定数の順番)を指定できないため、Ruby 側で並べ直す
  def items_by_category
    grouped = items.ordered.includes(:added_by).group_by(&:category)
    ShoppingListItem::CATEGORIES.filter_map { |category| [ category, grouped[category] ] if grouped[category] }.to_h
  end
end
