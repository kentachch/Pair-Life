require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "未所属ユーザーは招待コード入力画面を表示できる" do
    sign_in create_user(email: "partner@example.com")

    get new_invitation_url
    assert_response :success
  end

  test "正しい招待コードで世帯に参加でき、招待コードが無効になる" do
    user = create_user(email: "partner@example.com")
    sign_in user

    post invitation_url, params: { invite_code: "INVITE01" }

    assert_redirected_to household_url
    assert_equal households(:one), user.reload.household
    assert_nil households(:one).reload.invite_code
  end

  test "招待コードの前後の空白は無視される" do
    user = create_user(email: "partner@example.com")
    sign_in user

    post invitation_url, params: { invite_code: "  INVITE01  " }

    assert_equal households(:one), user.reload.household
  end

  test "招待コードを小文字で入力しても参加できる" do
    user = create_user(email: "partner@example.com")
    sign_in user

    post invitation_url, params: { invite_code: "invite01" }

    assert_equal households(:one), user.reload.household
  end

  test "間違った招待コードでは参加できない" do
    sign_in create_user(email: "partner@example.com")

    assert_no_difference "HouseholdMember.count" do
      post invitation_url, params: { invite_code: "WRONG000" }
    end

    assert_response :unprocessable_entity
  end

  test "2人そろって無効になった招待コードでは参加できない" do
    households(:one).add_member!(create_user(email: "partner@example.com"))
    sign_in create_user(email: "third@example.com")

    assert_no_difference "HouseholdMember.count" do
      post invitation_url, params: { invite_code: "INVITE01" }
    end

    assert_response :unprocessable_entity
  end

  test "所属済みユーザーは招待コードで参加できない" do
    sign_in users(:two)

    assert_no_difference "HouseholdMember.count" do
      post invitation_url, params: { invite_code: "INVITE01" }
    end

    assert_redirected_to root_url
  end

  test "ログインしていなければログイン画面へ移動する" do
    get new_invitation_url
    assert_redirected_to new_user_session_url
  end
end
