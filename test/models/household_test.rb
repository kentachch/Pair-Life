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
end
