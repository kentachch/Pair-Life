require "test_helper"

class HouseholdsControllerTest < ActionDispatch::IntegrationTest
  # --- 世帯に所属していないユーザー ---

  test "未所属ユーザーは世帯作成画面を表示できる" do
    sign_in create_user(email: "new@example.com")

    get new_household_url
    assert_response :success
  end

  test "未所属ユーザーは世帯を作成でき、自分がメンバーになる" do
    user = create_user(email: "new@example.com")
    sign_in user

    assert_difference [ "Household.count", "HouseholdMember.count" ], 1 do
      post household_url, params: { household: { name: "テスト家" } }
    end

    assert_redirected_to household_url
    assert_equal "テスト家", user.reload.household.name
  end

  test "世帯名が空だと作成できず、入力画面に戻る" do
    sign_in create_user(email: "new@example.com")

    assert_no_difference "Household.count" do
      post household_url, params: { household: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "未所属ユーザーは世帯の詳細を見られず、作成画面へ移動する" do
    sign_in create_user(email: "new@example.com")

    get household_url
    assert_redirected_to new_household_url
  end

  # --- 世帯に所属しているユーザー ---

  test "所属済みユーザーは世帯の詳細を表示でき、招待コードが表示される" do
    sign_in users(:one)

    get household_url
    assert_response :success
    assert_match "INVITE01", response.body
  end

  test "2人そろった世帯では招待コードが表示されない" do
    households(:one).add_member!(create_user(email: "partner@example.com"))
    sign_in users(:one)

    get household_url
    assert_response :success
    assert_no_match "INVITE01", response.body
  end

  test "所属済みユーザーは世帯作成画面を使えない" do
    sign_in users(:one)

    get new_household_url
    assert_redirected_to root_url
  end

  test "所属済みユーザーは新しい世帯を作成できない" do
    sign_in users(:one)

    assert_no_difference "Household.count" do
      post household_url, params: { household: { name: "2つ目の世帯" } }
    end

    assert_redirected_to root_url
  end

  # --- ログインしていないユーザー ---

  test "ログインしていなければログイン画面へ移動する" do
    get new_household_url
    assert_redirected_to new_user_session_url
  end
end
