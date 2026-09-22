require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # users(:one) は households(:one) に所属している
    sign_in users(:one)
  end

  def valid_params(**attributes)
    { expense: { amount: 1200, spent_on: "2026-09-15", category_id: categories(:food).id,
                 payer_id: users(:one).id, memo: "ドラッグストア" }.merge(attributes) }
  end

  test "自分の世帯の支出だけが一覧に表示される" do
    get expenses_url(month: "2026-09")

    assert_response :success
    assert_match "スーパー", response.body
    assert_no_match "他の世帯の支出", response.body
  end

  test "指定した月の支出と合計だけが表示される" do
    households(:one).expenses.create!(payer: users(:one), category: categories(:rent), amount: 80000,
                                      spent_on: Date.new(2026, 9, 30), memo: "9月の家賃")
    households(:one).expenses.create!(payer: users(:one), category: categories(:rent), amount: 70000,
                                      spent_on: Date.new(2026, 10, 1), memo: "10月の家賃")

    get expenses_url(month: "2026-09")

    assert_select "h2", text: "2026年9月"
    assert_match "9月の家賃", response.body
    assert_no_match "10月の家賃", response.body
    # expenses(:one) の 3000 円 + 80000 円
    assert_match "¥83,000", response.body
  end

  test "前の月・次の月へのリンクがある" do
    get expenses_url(month: "2026-01")

    # 1月の前は前年の12月、次は2月
    assert_select "a[href=?]", expenses_path(month: "2025-12")
    assert_select "a[href=?]", expenses_path(month: "2026-02")
  end

  test "月を指定しなければ今月を表示する" do
    travel_to Date.new(2026, 9, 22) do
      get expenses_url
    end

    assert_select "h2", text: "2026年9月"
  end

  test "月の形式が正しくなければ今月を表示する" do
    travel_to Date.new(2026, 9, 22) do
      get expenses_url(month: "abc")
    end

    assert_response :success
    assert_select "h2", text: "2026年9月"
  end

  test "一覧にはカテゴリのアイコンが表示される" do
    get expenses_url(month: "2026-09")

    assert_select "[data-icon=shopping-basket] svg"
  end

  # --- 登録 ---

  test "登録画面では日付が今日、支払った人が自分になっている" do
    get new_expense_url

    assert_response :success
    assert_select "input[name='expense[spent_on]'][value=?]", Date.current.to_s
    assert_select "select[name='expense[payer_id]'] option[selected][value=?]", users(:one).id.to_s
  end

  test "支出を登録すると自分の世帯に保存される" do
    assert_difference "households(:one).expenses.count", 1 do
      post expenses_url, params: valid_params
    end

    # 登録した支出の月(2026-09)の一覧に戻る
    assert_redirected_to expenses_url(month: "2026-09")
    expense = households(:one).expenses.order(:created_at).last
    assert_equal 1200, expense.amount
    assert_equal users(:one), expense.payer
  end

  test "金額が空だと登録できず、入力画面に戻る" do
    assert_no_difference "Expense.count" do
      post expenses_url, params: valid_params(amount: "")
    end

    assert_response :unprocessable_entity
  end

  test "他の世帯のカテゴリを指定しても登録できない" do
    assert_no_difference "Expense.count" do
      post expenses_url, params: valid_params(category_id: categories(:other_household_food).id)
    end

    assert_response :unprocessable_entity
  end

  test "他の世帯のユーザーを支払った人に指定しても登録できない" do
    assert_no_difference "Expense.count" do
      post expenses_url, params: valid_params(payer_id: users(:two).id)
    end

    assert_response :unprocessable_entity
  end

  # --- 編集 ---

  test "編集画面を表示できる" do
    get edit_expense_url(expenses(:one))
    assert_response :success
  end

  test "支出を変更できる" do
    patch expense_url(expenses(:one)), params: { expense: { amount: 4500 } }

    assert_redirected_to expenses_url(month: "2026-09")
    assert_equal 4500, expenses(:one).reload.amount
  end

  test "不正な値では変更できず、入力画面に戻る" do
    patch expense_url(expenses(:one)), params: { expense: { amount: 0 } }

    assert_response :unprocessable_entity
    assert_equal 3000, expenses(:one).reload.amount
  end

  test "パートナーが登録した支出も編集・削除できる" do
    partner = create_user(email: "partner@example.com")
    households(:one).add_member!(partner)
    sign_out users(:one)
    sign_in partner

    # expenses(:one) は users(:one) が支払った支出
    patch expense_url(expenses(:one)), params: { expense: { amount: 3500 } }
    assert_equal 3500, expenses(:one).reload.amount

    assert_difference "Expense.count", -1 do
      delete expense_url(expenses(:one))
    end
  end

  # --- 削除 ---

  test "支出を削除できる" do
    assert_difference "Expense.count", -1 do
      delete expense_url(expenses(:one))
    end

    assert_redirected_to expenses_url(month: "2026-09")
  end

  # --- 他の世帯の支出(権限チェック) ---

  test "他の世帯の支出の編集画面は表示できない" do
    get edit_expense_url(expenses(:two))
    assert_response :not_found
  end

  test "他の世帯の支出は変更できない" do
    patch expense_url(expenses(:two)), params: { expense: { amount: 1 } }

    assert_response :not_found
    assert_equal 5000, expenses(:two).reload.amount
  end

  test "他の世帯の支出は削除できない" do
    assert_no_difference "Expense.count" do
      delete expense_url(expenses(:two))
    end

    assert_response :not_found
  end

  # --- 世帯・ログイン状態 ---

  test "世帯に未所属なら世帯作成画面へ移動する" do
    sign_out users(:one)
    sign_in create_user(email: "new@example.com")

    get expenses_url
    assert_redirected_to new_household_url
  end

  test "ログインしていなければログイン画面へ移動する" do
    sign_out users(:one)

    get expenses_url
    assert_redirected_to new_user_session_url
  end

  # --- 支払った人の内訳 ---

  test "支払った人ごとの合計と割合が表示される" do
    partner = create_user(email: "partner@example.com", name: "パートナー")
    households(:one).add_member!(partner)
    # expenses(:one) で users(:one) が 3000 円。パートナーが 1000 円払うと 75% : 25%
    households(:one).expenses.create!(payer: partner, category: categories(:rent), amount: 1000, spent_on: Date.new(2026, 9, 10))

    get expenses_url(month: "2026-09")

    assert_select "li", text: /ユーザー1.*\(あなた\).*75%.*¥3,000/m
    assert_select "li", text: /パートナー.*25%.*¥1,000/m
    # 割合の横棒
    assert_select "div[style='width: 75%']"
    assert_select "div[style='width: 25%']"
  end

  test "支払いがないメンバーは ¥0 と表示される" do
    partner = create_user(email: "partner@example.com", name: "パートナー")
    households(:one).add_member!(partner)

    get expenses_url(month: "2026-09")

    assert_select "li", text: /パートナー.*0%.*¥0/m
  end

  test "パートナーが未参加なら、招待コードの確認へ案内する" do
    get expenses_url(month: "2026-09")

    assert_match "パートナーはまだ参加していません", response.body
    assert_select "a[href=?]", household_path, text: "招待コードを確認"
  end

  test "2人そろっていれば、未参加の案内は出ない" do
    households(:one).add_member!(create_user(email: "partner@example.com"))

    get expenses_url(month: "2026-09")

    assert_no_match "パートナーはまだ参加していません", response.body
  end

  test "一覧の編集・削除ボタンは、スマホでも押しやすいアイコンボタンになっている" do
    get expenses_url(month: "2026-09")

    assert_select "a[href=?][aria-label='編集']", edit_expense_path(expenses(:one))
    assert_select "form[action=?] button[aria-label='削除']", expense_path(expenses(:one))
  end

  test "下部タブバーでは、支出の画面にいるとき支出タブが強調される" do
    get expenses_url(month: "2026-09")

    assert_select "nav.fixed a.text-blue-600[href=?]", expenses_path
  end
end
