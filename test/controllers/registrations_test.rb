require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "アカウント編集画面に削除ボタンがない" do
    sign_in users(:one)

    get edit_user_registration_url

    assert_response :success
    assert_no_match "アカウントを削除", response.body
  end

  test "DELETE /users を送ってもアカウントは削除されない" do
    sign_in users(:one)

    assert_no_difference "User.count" do
      delete "/users"
    end

    # ルートが存在しないので 404 になる
    assert_response :not_found
  end

  test "新規登録はこれまでどおりできる" do
    assert_difference "User.count", 1 do
      post user_registration_url, params: {
        user: { name: "新規ユーザー", email: "new@example.com", password: "password", password_confirmation: "password" }
      }
    end
  end
end
