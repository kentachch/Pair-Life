# Google ログインのあと、Google から戻ってきたときの処理
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google")
    else
      redirect_to new_user_session_path, alert: "Googleアカウントでログインできませんでした"
    end
  end

  # Google の画面でキャンセルしたときなど、認証に失敗したときに呼ばれる
  def failure
    redirect_to new_user_session_path, alert: "Googleアカウントでログインできませんでした"
  end
end
