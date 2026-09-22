require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # users(:one) は households(:one) に所属している
    sign_in users(:one)
  end

  # --- 一覧・追加 ---

  test "自分の世帯のカテゴリだけが一覧に表示される" do
    get categories_url

    assert_response :success
    assert_match "家賃", response.body
    # 他の世帯にしかないカテゴリは表示されない
    households(:two).categories.create!(name: "ペット")
    get categories_url
    assert_no_match "ペット", response.body
  end

  test "追加画面を表示できる" do
    get new_category_url
    assert_response :success
  end

  test "カテゴリを追加すると自分の世帯に登録される" do
    assert_difference "households(:one).categories.count", 1 do
      post categories_url, params: { category: { name: "趣味" } }
    end

    assert_redirected_to categories_url
  end

  test "名前が空だと追加できず、入力画面に戻る" do
    assert_no_difference "Category.count" do
      post categories_url, params: { category: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  # --- 編集 ---

  test "編集画面を表示できる" do
    get edit_category_url(categories(:food))
    assert_response :success
  end

  test "カテゴリの名前を変更できる" do
    patch category_url(categories(:food)), params: { category: { name: "食料品" } }

    assert_redirected_to categories_url
    assert_equal "食料品", categories(:food).reload.name
  end

  test "同じ世帯にある名前には変更できない" do
    patch category_url(categories(:food)), params: { category: { name: "家賃" } }

    assert_response :unprocessable_entity
    assert_equal "食費", categories(:food).reload.name
  end

  # --- 削除 ---

  test "支出のないカテゴリは削除できる" do
    assert_difference "Category.count", -1 do
      delete category_url(categories(:rent))
    end

    assert_redirected_to categories_url
  end

  test "支出が登録されているカテゴリは削除できない" do
    # フィクスチャで categories(:food) には expenses(:one) が登録されている
    assert_no_difference "Category.count" do
      delete category_url(categories(:food))
    end

    assert_redirected_to categories_url
    assert_not_nil flash[:alert]
  end

  # --- 他の世帯のカテゴリ(権限チェック) ---

  test "他の世帯のカテゴリの編集画面は表示できない" do
    get edit_category_url(categories(:other_household_food))
    assert_response :not_found
  end

  test "他の世帯のカテゴリは変更できない" do
    patch category_url(categories(:other_household_food)), params: { category: { name: "書き換え" } }

    assert_response :not_found
    assert_equal "食費", categories(:other_household_food).reload.name
  end

  test "他の世帯のカテゴリは削除できない" do
    assert_no_difference "Category.count" do
      delete category_url(categories(:other_household_food))
    end

    assert_response :not_found
  end

  # --- 世帯・ログイン状態 ---

  test "世帯に未所属なら世帯作成画面へ移動する" do
    sign_out users(:one)
    sign_in create_user(email: "new@example.com")

    get categories_url
    assert_redirected_to new_household_url
  end

  test "ログインしていなければログイン画面へ移動する" do
    sign_out users(:one)

    get categories_url
    assert_redirected_to new_user_session_url
  end

  test "一覧ではカテゴリごとにアイコンと支出の件数が表示される" do
    get categories_url

    # category_icon ヘルパーは <span data-icon="アイコン名"><svg>...</svg></span> を出力する
    assert_select "[data-icon=shopping-basket] svg"
    assert_select "[data-icon=house] svg"
    # categories(:food) には expenses(:one) の1件がある
    assert_match "支出 1 件", response.body
  end

  test "支出があるカテゴリには削除ボタンを表示しない" do
    get categories_url

    # 支出のない「家賃」だけ削除ボタンがある
    assert_select "form[action=?]", category_path(categories(:rent))
    assert_select "form[action=?]", category_path(categories(:food)), count: 0
  end

  test "アイコンを選んでカテゴリを追加できる" do
    post categories_url, params: { category: { name: "ペット", icon: "dog" } }

    assert_equal "dog", households(:one).categories.find_by(name: "ペット").icon
  end

  test "追加画面では初期値の tag アイコンが選ばれている" do
    get new_category_url

    assert_select "input[type=radio][name='category[icon]'][value=tag][checked]"
  end

  test "カテゴリのアイコンを変更できる" do
    patch category_url(categories(:food)), params: { category: { icon: "utensils" } }

    assert_equal "utensils", categories(:food).reload.icon
  end
end
