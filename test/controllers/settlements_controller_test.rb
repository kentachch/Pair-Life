require "test_helper"

class SettlementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # 「今日」を 2026-09-22 に固定する。9月は精算できず、8月以前は精算できる
    travel_to Time.zone.local(2026, 9, 22, 12, 0, 0)

    # 精算は2人そろった世帯で行うので、households(:one) にパートナーを追加する
    @household = households(:one)
    @partner = create_user(email: "partner@example.com", name: "パートナー")
    @household.add_member!(@partner)
    sign_in users(:one)
  end

  # 8月の支出を追加するヘルパー(フィクスチャの expenses(:one) は9月の支出)
  def add_august_expense(payer, amount)
    @household.expenses.create!(payer: payer, category: categories(:food), amount: amount, spent_on: Date.new(2026, 8, 10))
  end

  # ============================================================
  # 表示(index)
  # ============================================================

  test "月を指定しなければ先月を表示する" do
    get settlements_url

    assert_response :success
    assert_select "h2", text: "2026年8月"
  end

  test "精算額と、支払う人・受け取る人が表示される" do
    add_august_expense(users(:one), 120_000)
    add_august_expense(@partner, 80_000)

    get settlements_url(month: "2026-08")

    # パートナーがユーザー1に 20,000 円支払う
    assert_select "p", text: /パートナー\s*さん\s*→\s*ユーザー1\s*さん/
    assert_match "¥20,000", response.body
    # 支出の合計と、支払った人の内訳も表示される
    assert_match "¥200,000", response.body
    assert_match "支払った人の内訳", response.body
  end

  test "終わった月で未精算なら、精算ボタンが表示される" do
    get settlements_url(month: "2026-08")

    assert_select "form[action=?]", settlements_path do
      assert_select "input[name=month][value=?]", "2026-08"
      assert_select "button", text: "精算済みにする"
    end
  end

  test "精算額が 0 円の月は、その旨が表示される" do
    get settlements_url(month: "2026-08")

    assert_match "精算はありません(0円)", response.body
  end

  test "当月は精算ボタンが出ず、月が終わってから精算できると表示される" do
    get settlements_url(month: "2026-09")

    assert_match "9月が終わってから精算できます", response.body
    assert_select "form[action=?]", settlements_path, count: 0
  end

  test "未来の月も精算ボタンは出ない" do
    get settlements_url(month: "2026-10")

    assert_select "form[action=?]", settlements_path, count: 0
  end

  test "精算済みの月は、精算済みと記録日時が表示され、ボタンは出ない" do
    @household.settlements.create!(target_month: Date.new(2026, 8, 1), amount: 0, settled_at: Time.zone.local(2026, 9, 1, 10, 30))

    get settlements_url(month: "2026-08")

    assert_select "span", text: "精算済み"
    assert_match "2026/09/01 10:30 に精算済みにしました", response.body
    assert_select "form[action=?]", settlements_path, count: 0
  end

  test "精算済みの月は、記録した金額を表示する(あとから支出が増えても変わらない)" do
    @household.settlements.create!(target_month: Date.new(2026, 8, 1), from_user: @partner, to_user: users(:one),
                                   amount: 5_000, settled_at: Time.current)
    # 精算したあとに支出が増えても、表示は記録した 5,000 円のまま
    add_august_expense(users(:one), 100_000)

    get settlements_url(month: "2026-08")

    assert_match "¥5,000", response.body
    assert_no_match "¥50,000", response.body
  end

  test "パートナーが未参加なら、精算額の代わりに案内を表示する" do
    # users(:two) の世帯(households(:two))にはメンバーが1人しかいない
    sign_out users(:one)
    sign_in users(:two)

    get settlements_url(month: "2026-07")

    assert_response :success
    assert_match "パートナーが参加すると精算できます", response.body
    assert_select "form[action=?]", settlements_path, count: 0
  end

  test "前の月・次の月へのリンクがある" do
    get settlements_url(month: "2026-01")

    assert_select "a[href=?]", settlements_path(month: "2025-12")
    assert_select "a[href=?]", settlements_path(month: "2026-02")
  end

  # ============================================================
  # 記録(create)
  # ============================================================

  test "精算済みにすると、計算した内容で保存される" do
    add_august_expense(users(:one), 120_000)
    add_august_expense(@partner, 80_000)

    assert_difference "@household.settlements.count", 1 do
      post settlements_url, params: { month: "2026-08" }
    end

    assert_redirected_to settlements_url(month: "2026-08")
    assert_equal "8月を精算済みにしました。", flash[:notice]

    settlement = @household.settlements.find_by(target_month: Date.new(2026, 8, 1))
    assert_equal @partner, settlement.from_user
    assert_equal users(:one), settlement.to_user
    assert_equal 20_000, settlement.amount
    assert_equal Time.current, settlement.settled_at
  end

  test "精算額が 0 円の月も精算済みにできる" do
    assert_difference "@household.settlements.count", 1 do
      post settlements_url, params: { month: "2026-08" }
    end

    assert_equal 0, @household.settlements.last.amount
  end

  test "金額を送っても使われず、サーバーで計算した金額で保存される" do
    add_august_expense(users(:one), 10_000)

    post settlements_url, params: { month: "2026-08", amount: 999_999, settlement: { amount: 999_999 } }

    assert_equal 5_000, @household.settlements.last.amount
  end

  test "当月は精算できない" do
    assert_no_difference "Settlement.count" do
      post settlements_url, params: { month: "2026-09" }
    end

    assert_redirected_to settlements_url(month: "2026-09")
    assert_not_nil flash[:alert]
  end

  test "月の指定がなければ当月として扱うので、精算されない" do
    assert_no_difference "Settlement.count" do
      post settlements_url
    end
  end

  test "精算済みの月は、もう一度精算できない" do
    post settlements_url, params: { month: "2026-08" }

    assert_no_difference "Settlement.count" do
      post settlements_url, params: { month: "2026-08" }
    end

    assert_redirected_to settlements_url(month: "2026-08")
    assert_not_nil flash[:alert]
  end

  test "パートナーが未参加なら精算できない" do
    sign_out users(:one)
    sign_in users(:two)

    assert_no_difference "Settlement.count" do
      post settlements_url, params: { month: "2026-07" }
    end

    assert_equal "パートナーが参加すると精算できます。", flash[:alert]
  end

  # ============================================================
  # 権限
  # ============================================================

  test "他の世帯の精算は表示されない" do
    # settlements(:two_august) で households(:two) の8月は精算済みだが、households(:one) の8月は未精算
    get settlements_url(month: "2026-08")

    assert_select "span", text: "精算済み", count: 0
    assert_select "form[action=?]", settlements_path
  end

  test "精算すると、自分の世帯の記録として保存される" do
    post settlements_url, params: { month: "2026-07" }

    assert @household.settled?(Date.new(2026, 7, 1))
    assert_not households(:two).settled?(Date.new(2026, 7, 1))
  end

  test "世帯に未所属なら世帯作成画面へ移動する" do
    sign_out users(:one)
    sign_in create_user(email: "new@example.com")

    get settlements_url
    assert_redirected_to new_household_url

    post settlements_url, params: { month: "2026-08" }
    assert_redirected_to new_household_url
  end

  test "ログインしていなければログイン画面へ移動する" do
    sign_out users(:one)

    get settlements_url
    assert_redirected_to new_user_session_url
  end

  # ============================================================
  # ナビゲーション
  # ============================================================

  test "下部タブバーでは、精算の画面にいるとき精算タブが強調される" do
    get settlements_url

    assert_select "nav.fixed a.text-blue-600[href=?]", settlements_path
  end

  test "PC用のヘッダーに精算画面へのリンクがある" do
    get settlements_url

    assert_select "header nav a[href=?]", settlements_path, text: "精算"
  end
end
