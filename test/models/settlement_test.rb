require "test_helper"

class SettlementTest < ActiveSupport::TestCase
  setup do
    # 「今日」を 2026-09-22 に固定する。9月は精算できず、8月以前は精算できる
    travel_to Time.zone.local(2026, 9, 22, 12, 0, 0)

    # 精算は2人そろった世帯で行うので、households(:one) にパートナーを追加する
    @household = households(:one)
    @partner = create_user(email: "partner@example.com", name: "パートナー")
    @household.add_member!(@partner)
    # expenses(:one) で users(:one) が 2026-09-01 に 3000 円払っている
  end

  # 支出を追加するヘルパー
  def add_expense(payer, amount, date = Date.new(2026, 9, 10))
    @household.expenses.create!(payer: payer, category: categories(:food), amount: amount, spent_on: date)
  end

  # 有効な精算を作るヘルパー。一部の値だけ変えて検証したいときに使う
  def build_settlement(**attributes)
    @household.settlements.build(
      { target_month: Date.new(2026, 8, 1), amount: 0, settled_at: Time.current }.merge(attributes)
    )
  end

  # ============================================================
  # 精算額の計算(build_for)
  # ============================================================

  test "払いすぎた人が受け取り、不足している人が差額を支払う" do
    add_expense(users(:one), 117_000) # users(:one) の合計は 120,000 円
    add_expense(@partner, 80_000)     # パートナーの合計は 80,000 円

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    # 本来の負担は 100,000 円ずつ。パートナーが 20,000 円支払う
    assert_equal @partner, settlement.from_user
    assert_equal users(:one), settlement.to_user
    assert_equal 20_000, settlement.amount
  end

  test "パートナーのほうが多く払っていれば、支払う向きが逆になる" do
    add_expense(@partner, 13_000) # users(:one) 3,000 円、パートナー 13,000 円

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    assert_equal users(:one), settlement.from_user
    assert_equal @partner, settlement.to_user
    assert_equal 5_000, settlement.amount
  end

  test "1円未満の端数は切り捨てる" do
    add_expense(users(:one), 1) # users(:one) の合計は 3,001 円、パートナーは 0 円

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    # 本来の負担は 1,500.5 円ずつ → 1,500 円(切り捨て)
    assert_equal 1_500, settlement.amount
  end

  test "2人が同じ額を払っていれば、精算額は 0 円で支払う人・受け取る人は空" do
    add_expense(@partner, 3_000) # 2人とも 3,000 円

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    assert_equal 0, settlement.amount
    assert_nil settlement.from_user
    assert_nil settlement.to_user
  end

  test "支出がない月は、精算額が 0 円になる" do
    settlement = Settlement.build_for(@household, Date.new(2026, 8, 1))

    assert_equal 0, settlement.amount
    assert_nil settlement.from_user
  end

  test "負担割合が 60:40 なら、割合に応じて精算する" do
    @household.household_members.find_by(user: users(:one)).update!(burden_ratio: 60)
    @household.household_members.find_by(user: @partner).update!(burden_ratio: 40)
    add_expense(users(:one), 97_000) # users(:one) だけが合計 100,000 円払う

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    # パートナーの本来の負担は 100,000 × 40% = 40,000 円
    assert_equal @partner, settlement.from_user
    assert_equal 40_000, settlement.amount
  end

  test "負担割合で出た端数も切り捨てる" do
    @household.household_members.find_by(user: users(:one)).update!(burden_ratio: 70)
    @household.household_members.find_by(user: @partner).update!(burden_ratio: 30)
    add_expense(users(:one), 97_001) # users(:one) だけが合計 100,001 円払う

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    # パートナーの本来の負担は 100,001 × 30% = 30,000.3 円 → 30,000 円
    assert_equal 30_000, settlement.amount
  end

  test "他の月の支出は計算に含めない" do
    add_expense(@partner, 50_000, Date.new(2026, 10, 1))

    settlement = Settlement.build_for(@household, Date.new(2026, 9, 1))

    # 9月は users(:one) の 3,000 円だけ
    assert_equal @partner, settlement.from_user
    assert_equal 1_500, settlement.amount
  end

  test "月の途中の日付を渡しても、対象月はその月の1日になる" do
    settlement = Settlement.build_for(@household, Date.new(2026, 8, 20))

    assert_equal Date.new(2026, 8, 1), settlement.target_month
  end

  test "メンバーが1人の世帯では nil を返す" do
    # households(:two) には users(:two) しかいない
    assert_nil Settlement.build_for(households(:two), Date.new(2026, 8, 1))
  end

  test "計算結果はまだ保存されていない" do
    settlement = Settlement.build_for(@household, Date.new(2026, 8, 1))

    assert settlement.new_record?
  end

  test "計算結果に記録日時を入れれば、そのまま保存できる" do
    add_expense(users(:one), 5_000, Date.new(2026, 8, 10))
    settlement = Settlement.build_for(@household, Date.new(2026, 8, 1))
    settlement.settled_at = Time.current

    assert settlement.save
  end

  # ============================================================
  # バリデーション
  # ============================================================

  test "必要な値がそろっていれば有効" do
    assert build_settlement.valid?
  end

  test "対象月が空だと無効" do
    assert_not build_settlement(target_month: nil).valid?
  end

  test "対象月が月の1日でなければ無効" do
    settlement = build_settlement(target_month: Date.new(2026, 8, 15))

    assert_not settlement.valid?
    assert_includes settlement.errors[:target_month], "は月の1日を指定してください。"
  end

  test "当月は精算できない" do
    settlement = build_settlement(target_month: Date.new(2026, 9, 1))

    assert_not settlement.valid?
    assert_includes settlement.errors[:target_month], "が終わっていないため、精算できません。"
  end

  test "未来の月は精算できない" do
    assert_not build_settlement(target_month: Date.new(2026, 10, 1)).valid?
  end

  test "先月は精算できる" do
    assert build_settlement(target_month: Date.new(2026, 8, 1)).valid?
  end

  test "同じ世帯の同じ月は、2回精算できない" do
    # settlements(:two_august) で households(:two) の8月は精算済み
    settlement = households(:two).settlements.build(target_month: Date.new(2026, 8, 1), amount: 0, settled_at: Time.current)

    assert_not settlement.valid?
    assert settlement.errors.of_kind?(:target_month, :taken)
  end

  test "別の世帯なら、同じ月でも精算できる" do
    # households(:two) の8月は精算済みだが、households(:one) の8月は未精算
    assert build_settlement(target_month: Date.new(2026, 8, 1)).valid?
  end

  test "記録日時が空だと無効" do
    assert_not build_settlement(settled_at: nil).valid?
  end

  test "精算額がマイナスだと無効" do
    assert_not build_settlement(amount: -1, from_user: @partner, to_user: users(:one)).valid?
  end

  test "精算額が小数だと無効" do
    assert_not build_settlement(amount: 100.5, from_user: @partner, to_user: users(:one)).valid?
  end

  test "1円以上なら、支払う人と受け取る人がいれば有効" do
    assert build_settlement(amount: 1_000, from_user: @partner, to_user: users(:one)).valid?
  end

  test "1円以上なのに、支払う人か受け取る人が空だと無効" do
    settlement = build_settlement(amount: 1_000, from_user: @partner)

    assert_not settlement.valid?
    assert_includes settlement.errors[:base], "支払う人と受け取る人を指定してください。"
  end

  test "0円なのに、支払う人・受け取る人が指定されていると無効" do
    settlement = build_settlement(amount: 0, from_user: @partner, to_user: users(:one))

    assert_not settlement.valid?
    assert_includes settlement.errors[:base], "精算額が0円のときは、支払う人と受け取る人を指定できません。"
  end

  test "他の世帯のユーザーは、支払う人・受け取る人にできない" do
    # users(:two) は households(:two) のメンバー
    settlement = build_settlement(amount: 1_000, from_user: users(:two), to_user: users(:one))

    assert_not settlement.valid?
    assert_includes settlement.errors[:base], "ユーザー2さんは世帯のメンバーではありません。"
  end

  test "0円の精算は、支払う人・受け取る人が空のまま保存できる" do
    # マイグレーションで from_user_id / to_user_id の null を許可していることの確認
    assert build_settlement.save
  end
end
