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

  # --- 一覧 ---

  test "自分の世帯の支出だけが一覧に表示される" do
    get expenses_url

    assert_response :success
    assert_match "スーパー", response.body
    assert_no_match "他の世帯の支出", response.body
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

    assert_redirected_to expenses_url
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

    assert_redirected_to expenses_url
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

    assert_redirected_to expenses_url
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
end
