# ShoppingListItem::CATEGORIES の名前を変えたときに、DB に残った古いカテゴリ名を新しい名前に書き換える
# 古い名前のままだと一覧のどの見出しにも入らず、画面に表示されなくなるため
class RenameOldShoppingListItemCategories < ActiveRecord::Migration[8.1]
  # 古いカテゴリ名 => 新しいカテゴリ名
  RENAMES = {
    "米・パン" => "米・パン・パスタ",
    "主食(米・パン・パスタ)" => "米・パン・パスタ",
    "生活日用品" => "日用品"
  }.freeze

  # マイグレーションの中では、アプリのモデル(app/models)を使わずにその場で小さなモデルを作る
  # アプリのモデルは今後変わる可能性があり、そうなると古いマイグレーションが動かなくなるため
  class ShoppingListItem < ActiveRecord::Base
    self.table_name = "shopping_list_items"
  end

  def up
    RENAMES.each do |old_name, new_name|
      ShoppingListItem.where(category: old_name).update_all(category: new_name)
    end
  end

  def down
    # 元がどの古い名前だったかは分からないので、戻すときは何もしない
  end
end
