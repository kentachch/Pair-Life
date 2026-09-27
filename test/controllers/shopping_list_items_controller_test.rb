require "test_helper"

class ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # users(:one) は households(:one) に所属している
    sign_in users(:one)
  end

  # --- 一覧 ---

  test "一覧にカテゴリの見出し・必須/任意のラベル・追加した人が表示される" do
    get shopping_list_items_url

    assert_response :success
    assert_select "h2", text: "乳製品・卵"
    assert_select "h2", text: "野菜・果物"
    assert_select "h2", text: "肉・魚", count: 0 # アイテムがないカテゴリの見出しは出ない
    assert_match "牛乳", response.body
    assert_match "必須", response.body
    assert_match "任意", response.body
    assert_match "ユーザー1さんが追加", response.body
  end

  test "他の世帯のアイテムは一覧に表示されない" do
    get shopping_list_items_url

    assert_no_match "豆腐", response.body
  end

  test "チェック済みがあるときだけ「チェック済みを削除」ボタンが出る" do
    get shopping_list_items_url
    assert_select "form[action=?]", clear_purchased_shopping_list_items_path

    shopping_list_items(:detergent).destroy
    get shopping_list_items_url
    assert_select "form[action=?]", clear_purchased_shopping_list_items_path, count: 0
  end

  test "アイテムがないときは「買う物はありません」と表示される" do
    shopping_lists(:one).items.destroy_all

    get shopping_list_items_url

    assert_match "買う物はありません", response.body
  end

  test "リストがない世帯でも、開くとリストが作られる" do
    shopping_lists(:one).destroy

    assert_difference "ShoppingList.count", 1 do
      get shopping_list_items_url
    end
    assert_response :success
  end

  # --- 追加 ---

  test "アイテムを追加すると、追加した人が自分になる" do
    assert_difference "shopping_lists(:one).items.count", 1 do
      post shopping_list_items_url, params: {
        shopping_list_item: { name: "卵", quantity: 1, category: "乳製品・卵", is_essential: true }
      }
    end

    assert_redirected_to shopping_list_items_url
    assert_equal users(:one), ShoppingListItem.find_by!(name: "卵").added_by
  end

  test "追加した人や購入済みはフォームから指定できない" do
    post shopping_list_items_url, params: {
      shopping_list_item: { name: "卵", category: "乳製品・卵", added_by_id: users(:two).id, purchased: true }
    }

    item = ShoppingListItem.find_by!(name: "卵")
    assert_equal users(:one), item.added_by
    assert_not item.purchased
  end

  test "入力に誤りがあると追加できず、一覧画面をエラー付きで表示する" do
    assert_no_difference "ShoppingListItem.count" do
      post shopping_list_items_url, params: { shopping_list_item: { name: "牛乳", category: "乳製品・卵" } }
    end

    assert_response :unprocessable_entity
    assert_match "商品名はすでにリストにあります", response.body
  end

  # --- 編集・削除 ---

  test "編集画面を表示できる" do
    get edit_shopping_list_item_url(shopping_list_items(:milk))
    assert_response :success
  end

  test "アイテムを変更できる。追加した人は変わらない" do
    patch shopping_list_item_url(shopping_list_items(:milk)), params: {
      shopping_list_item: { name: "豆乳", quantity: 3, is_essential: false }
    }

    assert_redirected_to shopping_list_items_url
    item = shopping_list_items(:milk).reload
    assert_equal "豆乳", item.name
    assert_equal 3, item.quantity
    assert_not item.is_essential
    assert_equal users(:one), item.added_by
  end

  test "入力に誤りがあると変更できず、編集画面に戻る" do
    patch shopping_list_item_url(shopping_list_items(:milk)), params: { shopping_list_item: { quantity: 0 } }

    assert_response :unprocessable_entity
    assert_equal 2, shopping_list_items(:milk).reload.quantity
  end

  test "アイテムを削除できる" do
    assert_difference "ShoppingListItem.count", -1 do
      delete shopping_list_item_url(shopping_list_items(:milk))
    end

    assert_redirected_to shopping_list_items_url
  end

  # --- チェック ---

  test "チェックを入れたり外したりできる" do
    item = shopping_list_items(:milk)

    patch toggle_purchased_shopping_list_item_url(item)
    assert_redirected_to shopping_list_items_url
    assert item.reload.purchased

    patch toggle_purchased_shopping_list_item_url(item)
    assert_not item.reload.purchased
  end

  test "チェック済みの物をまとめて削除できる" do
    assert_difference "ShoppingListItem.count", -1 do
      delete clear_purchased_shopping_list_items_url
    end

    assert_redirected_to shopping_list_items_url
    assert ShoppingListItem.exists?(shopping_list_items(:milk).id)
  end

  # --- 権限 ---

  # 1つのテストで 404 のリクエストを続けて送るとログイン状態が引き継がれないため、操作ごとにテストを分ける
  test "他の世帯のアイテムの編集画面は表示できない" do
    get edit_shopping_list_item_url(shopping_list_items(:other_household_item))
    assert_response :not_found
  end

  test "他の世帯のアイテムは変更できない" do
    patch shopping_list_item_url(shopping_list_items(:other_household_item)), params: { shopping_list_item: { name: "書き換え" } }

    assert_response :not_found
    assert_equal "豆腐", shopping_list_items(:other_household_item).reload.name
  end

  test "他の世帯のアイテムはチェックできない" do
    patch toggle_purchased_shopping_list_item_url(shopping_list_items(:other_household_item))

    assert_response :not_found
    assert_not shopping_list_items(:other_household_item).reload.purchased
  end

  test "他の世帯のアイテムは削除できない" do
    assert_no_difference "ShoppingListItem.count" do
      delete shopping_list_item_url(shopping_list_items(:other_household_item))
    end

    assert_response :not_found
  end

  test "チェック済みをまとめて削除しても、他の世帯のアイテムは消えない" do
    other = shopping_list_items(:other_household_item)
    other.update!(purchased: true)

    delete clear_purchased_shopping_list_items_url

    assert ShoppingListItem.exists?(other.id)
  end

  test "世帯に所属していないと世帯作成画面へ移動する" do
    sign_in create_user(email: "nohousehold@example.com")

    get shopping_list_items_url

    assert_redirected_to new_household_url
  end

  test "ログインしていないとログイン画面へ移動する" do
    sign_out users(:one)

    get shopping_list_items_url

    assert_redirected_to new_user_session_url
  end
end
