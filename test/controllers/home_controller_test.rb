require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "ログインしていればトップページを表示できる" do
    sign_in users(:one)

    get root_url
    assert_response :success
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
end
