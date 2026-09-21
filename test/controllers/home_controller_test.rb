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
end
