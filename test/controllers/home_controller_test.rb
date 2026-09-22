require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "ログインしていればトップページを表示できる" do
    sign_in users(:one)

    get root_url
    assert_response :success
  end

  test "ヘッダーにカテゴリ画面へのリンクがある" do
    sign_in users(:one)

    get root_url
    assert_select "header a[href=?]", categories_path, text: "カテゴリを作る"
  end

  test "ヘッダーに世帯ページへのリンクがある" do
    sign_in users(:one)

    get root_url
    assert_select "header a[href=?]", household_path, text: "世帯メンバー"
  end


  test "ログインしていなければログイン画面へ移動する" do
    get root_url
    assert_redirected_to new_user_session_url
  end

  test "世帯に所属していなければ世帯作成画面へ移動する" do
    sign_in create_user(email: "new@example.com")

    get root_url
    assert_redirected_to new_household_url
  end

  test "最近の支出は新しい順に5件だけ表示される" do
    sign_in users(:one)
    # expenses(:one)(9/1)に加えて5件登録し、合計6件にする
    (1..5).each do |i|
      households(:one).expenses.create!(payer: users(:one), category: categories(:rent),
                                        amount: 1000 + i, spent_on: Date.new(2026, 9, 10 + i))
    end

    get root_url

    # 一番古い9/1の支出は6件目なので表示されない
    assert_no_match "2026/09/01", response.body
    assert_match "2026/09/15", response.body
  end

  test "他の世帯の支出は表示されない" do
    sign_in users(:one)

    get root_url
    # expenses(:two) は households(:two) の 5000 円の支出
    assert_no_match "¥5,000", response.body
  end

  test "カレンダーでは支出があった日にその日の合計が表示される" do
    sign_in users(:one)

    travel_to Date.new(2026, 9, 21) do
      households(:one).expenses.create!(payer: users(:one), category: categories(:rent), amount: 500, spent_on: Date.new(2026, 9, 1))

      get root_url
    end

    assert_select "h3", text: "2026年9月"
    # 9/1 は expenses(:one) の 3000 円 + 500 円
    assert_select "td", text: /1\s*¥3,500/
  end

  test "円グラフ用に今月のAPIのURLが埋め込まれている" do
    sign_in users(:one)

    travel_to Date.new(2026, 9, 21) do
      get root_url
    end

    assert_select "[data-controller='category-chart'][data-category-chart-url-value=?]",
                  api_category_totals_path(month: "2026-09")
  end

  test "今月の支出合計が表示される" do
    sign_in users(:one)

    travel_to Date.new(2026, 9, 22) do
      households(:one).expenses.create!(payer: users(:one), category: categories(:rent), amount: 80000, spent_on: Date.new(2026, 9, 25))
      # 先月の支出は合計に含まれない
      households(:one).expenses.create!(payer: users(:one), category: categories(:rent), amount: 999, spent_on: Date.new(2026, 8, 31))

      get root_url
    end

    assert_match "9月の支出合計", response.body
    # expenses(:one) の 3000 円 + 80000 円
    assert_match "¥83,000", response.body
  end

  test "最近の支出にはカテゴリのアイコンが表示される" do
    sign_in users(:one)

    get root_url

    assert_select "[data-icon=shopping-basket] svg"
  end

  test "今月の支払った人の内訳が表示される" do
    sign_in users(:one)
    partner = create_user(email: "partner@example.com", name: "パートナー")
    households(:one).add_member!(partner)

    travel_to Date.new(2026, 9, 22) do
      households(:one).expenses.create!(payer: partner, category: categories(:rent), amount: 80000, spent_on: Date.new(2026, 9, 25))

      get root_url
    end

    assert_match "支払った人の内訳", response.body
    # expenses(:one) で users(:one) が 3000 円
    assert_select "li", text: /ユーザー1.*¥3,000/m
    assert_select "li", text: /パートナー.*¥80,000/m
  end
end
