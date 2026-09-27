require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  # テスト中は実際に Google へアクセスせず、用意した情報が返ってくるようにする
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  def mock_google(email_verified: true)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "12345",
      info: { email: "google@example.com", name: "グーグル太郎" },
      extra: { raw_info: { email_verified: email_verified } }
    )
  end

  test "Google でログインするとユーザーが作られ、ログイン状態になる" do
    mock_google

    assert_difference "User.count", 1 do
      post user_google_oauth2_omniauth_authorize_path
      follow_redirect! # Google のコールバック URL へ
    end

    assert_redirected_to root_path
    get root_path
    assert_response :redirect # 世帯がないので世帯作成画面へ(ログインできている)
    assert_redirected_to new_household_path
  end

  test "ユーザーを保存できなかったときはログイン画面に戻る" do
    mock_google(email_verified: false)
    User.create!(name: "既存", email: "google@example.com", password: "password")

    assert_no_difference "User.count" do
      post user_google_oauth2_omniauth_authorize_path
      follow_redirect!
    end

    assert_redirected_to new_user_session_path
  end

  test "Google 側で認証に失敗したときはログイン画面に戻る" do
    OmniAuth.config.mock_auth[:google_oauth2] = :access_denied

    post user_google_oauth2_omniauth_authorize_path
    follow_redirect! # 失敗用の URL(/users/auth/failure)へ

    assert_redirected_to new_user_session_path
  end

  test "ログイン画面に Google ログインのボタンがある" do
    get new_user_session_path

    assert_match "Googleでログイン", response.body
  end
end
