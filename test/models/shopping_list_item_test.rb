require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  # 正しい値のアイテムを作る。keyword で一部の値だけ変えられる
  def build_item(**attrs)
    shopping_lists(:one).items.build({ name: "卵", category: "乳製品・卵", added_by: users(:one) }.merge(attrs))
  end

  test "正しい値なら有効" do
    assert build_item.valid?
  end

  test "個数・必須/任意・チェックの初期値" do
    item = build_item

    assert_equal 1, item.quantity
    assert item.is_essential
    assert_not item.purchased
  end

  test "商品名が空だと無効" do
    item = build_item(name: "")

    assert_not item.valid?
    assert item.errors.of_kind?(:name, :blank)
  end

  test "商品名が31文字以上だと無効" do
    item = build_item(name: "あ" * 31)

    assert_not item.valid?
    assert item.errors.of_kind?(:name, :too_long)
  end

  test "個数が0だと無効" do
    item = build_item(quantity: 0)

    assert_not item.valid?
    assert item.errors.of_kind?(:quantity, :greater_than_or_equal_to)
  end

  test "個数が小数だと無効" do
    item = build_item(quantity: 1.5)

    assert_not item.valid?
    assert item.errors.of_kind?(:quantity, :not_an_integer)
  end

  test "メモが101文字以上だと無効" do
    item = build_item(memo: "あ" * 101)

    assert_not item.valid?
    assert item.errors.of_kind?(:memo, :too_long)
  end

  test "一覧にないカテゴリだと無効" do
    item = build_item(category: "家電")

    assert_not item.valid?
    assert item.errors.of_kind?(:category, :inclusion)
  end

  test "必須/任意が空だと無効" do
    item = build_item(is_essential: nil)

    assert_not item.valid?
    assert item.errors.of_kind?(:is_essential, :inclusion)
  end

  test "任意(false)でも有効" do
    assert build_item(is_essential: false).valid?
  end

  test "商品名の前後の空白は取り除かれる" do
    assert_equal "卵", build_item(name: "  卵 ").name
  end

  test "同じリストに同じ商品名は登録できない" do
    # フィクスチャで shopping_lists(:one) に未チェックの「牛乳」がある
    item = build_item(name: "牛乳")

    assert_not item.valid?
    assert_includes item.errors.full_messages, "商品名はすでにリストにあります"
  end

  test "前後に空白があっても同じ商品名なら重複になる" do
    assert_not build_item(name: " 牛乳 ").valid?
  end

  test "チェック済みの物と重複したときは、チェックを外すよう案内する" do
    # フィクスチャで shopping_lists(:one) にチェック済みの「洗剤」がある
    item = build_item(name: "洗剤", category: "日用品")

    assert_not item.valid?
    assert_includes item.errors.full_messages, "「洗剤」はチェック済みです。チェックを外してください"
  end

  test "編集で名前を変えなければ、自分自身とは重複しない" do
    item = shopping_list_items(:milk)
    item.quantity = 3

    assert item.valid?
  end

  test "別のリストなら同じ商品名を登録できる" do
    # 「豆腐」は shopping_lists(:two) にだけある
    assert build_item(name: "豆腐").valid?
  end

  test "世帯のメンバーでない人は追加した人にできない" do
    item = build_item(added_by: users(:two))

    assert_not item.valid?
    assert item.errors.include?(:added_by)
  end

  test "toggle_purchased! でチェックを入れたり外したりできる" do
    item = shopping_list_items(:milk)

    item.toggle_purchased!
    assert item.reload.purchased

    item.toggle_purchased!
    assert_not item.reload.purchased
  end

  test "ordered は 未チェック → チェック済み、必須 → 任意、追加が古い順に並べる" do
    list = shopping_lists(:one)
    list.items.destroy_all
    old_optional = list.items.create!(name: "A", category: "その他", is_essential: false, added_by: users(:one))
    purchased    = list.items.create!(name: "B", category: "その他", purchased: true, added_by: users(:one))
    essential    = list.items.create!(name: "C", category: "その他", added_by: users(:one))
    new_optional = list.items.create!(name: "D", category: "その他", is_essential: false, added_by: users(:one))

    assert_equal [ essential, old_optional, new_optional, purchased ], list.items.ordered.to_a
  end
end
