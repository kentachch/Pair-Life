require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Google から受け取る情報(auth)を、テスト用に作る
  def google_auth(uid: "12345", email: "google@example.com", name: "グーグル太郎", email_verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: name },
      extra: { raw_info: { email_verified: email_verified } }
    )
  end

  test "from_omniauth: 初めての Google ログインでユーザーが作られる" do
    user = nil
    assert_difference "User.count", 1 do
      user = User.from_omniauth(google_auth)
    end

    assert user.persisted?
    assert_equal "グーグル太郎", user.name
    assert_equal "google@example.com", user.email
    assert_equal "google_oauth2", user.provider
    assert_equal "12345", user.uid
  end

  test "from_omniauth: 2回目以降は同じユーザーが返る" do
    first = User.from_omniauth(google_auth)

    assert_no_difference "User.count" do
      assert_equal first, User.from_omniauth(google_auth)
    end
  end

  test "from_omniauth: 同じメールアドレスの既存ユーザーに紐付く" do
    user = users(:one)

    assert_no_difference "User.count" do
      assert_equal user, User.from_omniauth(google_auth(email: user.email))
    end

    user.reload
    assert_equal "google_oauth2", user.provider
    assert_equal "12345", user.uid
    assert_equal "ユーザー1", user.name # 名前は上書きしない
  end

  test "from_omniauth: メールアドレスが未確認なら既存ユーザーに紐付けない" do
    user = users(:one)

    assert_no_difference "User.count" do
      result = User.from_omniauth(google_auth(email: user.email, email_verified: false))
      assert_not result.persisted?
    end

    assert_nil user.reload.uid
  end
end
