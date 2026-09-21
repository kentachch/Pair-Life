require "test_helper"

class HouseholdMemberTest < ActiveSupport::TestCase
  test "負担割合の初期値は50" do
    member = HouseholdMember.new

    assert_equal 50, member.burden_ratio
  end

  test "2人目のメンバーは参加できる" do
    member = households(:one).household_members.build(user: create_user(email: "partner@example.com"))

    assert member.valid?
  end

  test "3人目のメンバーは参加できない" do
    household = households(:one)
    household.household_members.create!(user: create_user(email: "partner@example.com"))

    third = household.household_members.build(user: create_user(email: "third@example.com"))

    assert_not third.valid?
    assert_includes third.errors[:base], "世帯の人数が上限に達しています"
  end

  test "1人のユーザーは2つの世帯に所属できない" do
    # users(:one) はすでに households(:one) に所属している
    member = households(:two).household_members.build(user: users(:one))

    assert_not member.valid?
    assert member.errors.of_kind?(:user_id, :taken)
  end

  test "負担割合は0から100の範囲なら有効" do
    member = household_members(:one)

    member.burden_ratio = 0
    assert member.valid?

    member.burden_ratio = 100
    assert member.valid?
  end

  test "負担割合が範囲外だと無効" do
    member = household_members(:one)

    member.burden_ratio = -1
    assert_not member.valid?

    member.burden_ratio = 101
    assert_not member.valid?
  end

  test "負担割合が小数だと無効" do
    member = household_members(:one)
    member.burden_ratio = 50.5

    assert_not member.valid?
  end
end
