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
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])          # 新規登録
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])   # アカウント編集
  end

  def require_household
    redirect_to new_household_path, alert: "世帯を作成してください" unless current_user.household
  end

  # すでに世帯に所属しているユーザーは、作成・参加画面を使えないようにする
  def reject_household_member
    redirect_to root_path, alert: "世帯のメンバーはアクセスできません" if current_user.household
  end
end
