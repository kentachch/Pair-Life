require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "名前があれば有効" do
    assert households(:one).categories.build(name: "趣味").valid?
  end

  test "名前が空だと無効" do
    category = households(:one).categories.build(name: "")

    assert_not category.valid?
    assert category.errors.of_kind?(:name, :blank)
  end

  test "名前が21文字以上だと無効" do
    category = households(:one).categories.build(name: "あ" * 21)

    assert_not category.valid?
    assert category.errors.of_kind?(:name, :too_long)
  end

  test "同じ世帯では同じ名前のカテゴリを作れない" do
    # フィクスチャで households(:one) に「食費」がある
    category = households(:one).categories.build(name: "食費")

    assert_not category.valid?
    assert category.errors.of_kind?(:name, :taken)
  end

  test "別の世帯なら同じ名前のカテゴリを作れる" do
    household = Household.create!(name: "テスト家")

    assert household.categories.build(name: "食費").valid?
  end

  test "支出が登録されているカテゴリは削除できない" do
    # フィクスチャで categories(:food) には expenses(:one) が登録されている
    category = categories(:food)

    assert_not category.destroy
    assert Category.exists?(category.id)
  end

  test "アイコンを指定しなければ tag になる" do
    assert_equal Category::DEFAULT_ICON, households(:one).categories.build(name: "趣味").icon
  end

  test "候補にないアイコンは使えない" do
    category = households(:one).categories.build(name: "趣味", icon: "not-exist-icon")

    assert_not category.valid?
    assert category.errors.of_kind?(:icon, :inclusion)
  end
end
