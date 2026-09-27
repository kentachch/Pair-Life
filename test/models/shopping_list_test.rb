require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  test "clear_purchased! はチェック済みのアイテムだけを削除する" do
    list = shopping_lists(:one)
    purchased_item = shopping_list_items(:detergent)

    assert_difference "list.items.count", -1 do
      list.clear_purchased!
    end

    assert_not ShoppingListItem.exists?(purchased_item.id)
    assert ShoppingListItem.exists?(shopping_list_items(:milk).id) # 未チェックの物は残る
  end

  test "items_by_category はカテゴリの順番で並べ、0件のカテゴリは含めない" do
    grouped = shopping_lists(:one).items_by_category

    # フィクスチャ: キャベツ(野菜・果物)、牛乳(乳製品・卵)、洗剤(日用品)
    assert_equal [ "野菜・果物", "乳製品・卵", "日用品" ], grouped.keys
    assert_equal [ shopping_list_items(:milk) ], grouped["乳製品・卵"]
  end

  test "Household#shopping_list! はリストがなければ作る" do
    household = Household.create!(name: "テスト家")

    assert_difference "ShoppingList.count", 1 do
      assert_kind_of ShoppingList, household.shopping_list!
    end
  end

  test "Household#shopping_list! は2回呼んでもリストは1つのまま" do
    household = Household.create!(name: "テスト家")
    first = household.shopping_list!

    assert_no_difference "ShoppingList.count" do
      assert_equal first, household.shopping_list!
    end
  end
end
