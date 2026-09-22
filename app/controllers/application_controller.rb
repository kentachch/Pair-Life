class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # ?month=2026-09 を日付(その月の1日)に変換する。指定がない・形式が正しくないときは default を返す
  # 支出一覧と精算画面で使う
  def selected_month(default: Date.current.beginning_of_month)
    Date.strptime(params[:month].to_s, "%Y-%m")
  rescue Date::Error
    default
  end

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
