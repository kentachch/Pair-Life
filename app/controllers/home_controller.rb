class HomeController < ApplicationController
  before_action :require_household

  def index
    household = current_user.household
    # 表示する月(今月の1日)。Date.current：今日の日付を取得
    @month = Date.current.beginning_of_month

    # 今月の支出の合計金額
    @monthly_total = household.monthly_total(@month)

    # 最近の支出（支払った人、そのカテゴリーの情報も）5件に絞る
    @recent_expenses = household.expenses.includes(:payer, :category).recent.limit(5)

    # 今月の日ごとの合計 → { 2026-09-01 => 3000, 2026-09-15 => 1200 } のようなハッシュ(カレンダー用)
    @daily_totals = household.expenses.in_month(@month).group(:spent_on).sum(:amount)
    # Userに紐づく支出の指定した一ヶ月に絞る。日付でグループ化。金額を合計する。
  end
end
