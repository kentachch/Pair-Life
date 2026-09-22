require "test_helper"

class HouseholdTest < ActiveSupport::TestCase
  test "名前があれば有効" do
    assert Household.new(name: "テスト家").valid?
  end

  test "名前が空だと無効" do
    household = Household.new(name: "")

    assert_not household.valid?
    assert household.errors.of_kind?(:name, :blank)
  end

  test "作成時に8文字の招待コードが発行される" do
    household = Household.create!(name: "テスト家")

    assert_equal 8, household.invite_code.length
  end

  test "招待コードは大文字で発行される" do
    household = Household.create!(name: "テスト家")

    assert_equal household.invite_code.upcase, household.invite_code
  end

  test "招待コードは世帯ごとに異なる" do
    first = Household.create!(name: "テスト家1")
    second = Household.create!(name: "テスト家2")

    assert_not_equal first.invite_code, second.invite_code
  end

  test "メンバーが1人のときは満員ではない" do
    # フィクスチャの households(:one) には users(:one) が1人だけ所属している
    assert_not households(:one).full?
  end

  test "メンバーが2人そろうと満員になる" do
    household = households(:one)
    household.household_members.create!(user: create_user(email: "partner@example.com"))

    assert household.full?
  end

  test "create_with_owner! で作成者が1人目のメンバーになる" do
    user = create_user(email: "owner@example.com")

    household = Household.create_with_owner!(name: "テスト家", user: user)

    assert_equal [ user ], household.users
  end

  test "create_with_owner! で世帯名が空だと、世帯もメンバーも作られない" do
    user = create_user(email: "owner@example.com")

    assert_no_difference [ "Household.count", "HouseholdMember.count" ] do
      assert_raises(ActiveRecord::RecordInvalid) do
        Household.create_with_owner!(name: "", user: user)
      end
    end
  end

  test "create_with_owner! で既に世帯に所属しているユーザーだと、世帯も作られない" do
    # トランザクションにより、メンバー登録の失敗で世帯の作成も取り消される
    assert_no_difference "Household.count" do
      assert_raises(ActiveRecord::RecordInvalid) do
        Household.create_with_owner!(name: "テスト家", user: users(:one))
      end
    end
  end

  test "add_member! で2人目が参加すると招待コードが無効になる" do
    household = households(:one)

    household.add_member!(create_user(email: "partner@example.com"))

    assert_nil household.reload.invite_code
    assert_equal 2, household.users.count
  end

  test "add_member! で参加に失敗したら招待コードは残る" do
    household = households(:one)

    # users(:two) はすでに households(:two) に所属しているので参加できない
    assert_raises(ActiveRecord::RecordInvalid) do
      household.add_member!(users(:two))
    end

    assert_equal "INVITE01", household.reload.invite_code
  end

  test "create_with_owner! で初期カテゴリが作られる" do
    household = Household.create_with_owner!(name: "テスト家", user: create_user(email: "owner@example.com"))

    assert_equal Household::DEFAULT_CATEGORY_NAMES.sort, household.categories.pluck(:name).sort
  end

  test "category_totals はカテゴリごとの合計を金額の大きい順に返す" do
    household = households(:one)
    # expenses(:one) で「食費」に 3000 円が登録済み
    household.expenses.create!(payer: users(:one), category: categories(:food), amount: 2000, spent_on: Date.new(2026, 9, 5))
    household.expenses.create!(payer: users(:one), category: categories(:rent), amount: 80000, spent_on: Date.new(2026, 9, 25))

    assert_equal [ [ "家賃", 80000 ], [ "食費", 5000 ] ], household.category_totals(Date.new(2026, 9, 1))
  end

  test "category_totals は他の月の支出を含まない" do
    household = households(:one)
    household.expenses.create!(payer: users(:one), category: categories(:rent), amount: 80000, spent_on: Date.new(2026, 10, 1))

    assert_equal [ [ "食費", 3000 ] ], household.category_totals(Date.new(2026, 9, 1))
  end

  test "category_totals は支出がない月には空の配列を返す" do
    assert_equal [], households(:one).category_totals(Date.new(2026, 8, 1))
  end
end
