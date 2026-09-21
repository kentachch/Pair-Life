class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # ログインしていないユーザーはログイン画面へ移動させる
  before_action :authenticate_user!
  # Devise の画面を表示するときだけ、受け取れる項目に name を追加する
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])          # 新規登録
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])   # アカウント編集
  end
end
