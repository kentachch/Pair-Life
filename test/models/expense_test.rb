require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  # 有効な支出を作るためのヘルパー。一部の値だけ変えて検証したいときに使う
  def build_expense(**attributes)
    households(:one).expenses.build(
      { payer: users(:one), category: categories(:food), amount: 1000, spent_on: Date.new(2026, 9, 10) }.merge(attributes)
    )
  end

  test "必要な値がそろっていれば有効" do
    assert build_expense.valid?
  end

  test "メモは空でもよい" do
    assert build_expense(memo: "").valid?
  end

  test "金額が空だと無効" do
    assert_not build_expense(amount: nil).valid?
  end

  test "金額が0以下だと無効" do
    assert_not build_expense(amount: 0).valid?
    assert_not build_expense(amount: -100).valid?
  end

  test "金額が小数だと無効" do
    assert_not build_expense(amount: 100.5).valid?
  end

  test "日付が空だと無効" do
    assert_not build_expense(spent_on: nil).valid?
  end

  test "メモが256文字以上だと無効" do
    assert_not build_expense(memo: "あ" * 256).valid?
  end

  test "支払った人がUserとして取得できる" do
    assert_equal users(:one), expenses(:one).payer
  end

  test "パートナーを支払った人にできる" do
    partner = create_user(email: "partner@example.com")
    households(:one).add_member!(partner)

    assert build_expense(payer: partner).valid?
  end

  test "他の世帯のユーザーを支払った人にできない" do
    # users(:two) は households(:two) のメンバー
    expense = build_expense(payer: users(:two))

    assert_not expense.valid?
    assert_includes expense.errors[:payer], "は世帯のメンバーではありません。"
  end

  test "他の世帯のカテゴリは使えない" do
    expense = build_expense(category: categories(:other_household_food))

    assert_not expense.valid?
    assert_includes expense.errors[:category], "はこの世帯のカテゴリーではありません。"
  end
end
