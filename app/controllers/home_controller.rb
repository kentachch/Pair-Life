class HomeController < ApplicationController
  before_action :require_household
  def index
    household = current_user.household
    @first_day_of_month = Date.current.beginning_of_month # Date.current：今日の日付を取得
    @recent_expenses = household.expenses.includes(:payer, :category).recent.limit(5)
    @monthly_expenses = household.expenses.in_month(@first_day_of_month) # 今月の支出を取得
    @total_amount = @monthly_expenses.group(:spent_on).sum(:amount) # 今月の支出の合計金額を計算
    @category_amounts = @monthly_expenses.joins(:category).group("categories.name").sum(:amount) # 今月のカテゴリーごとの支出の合計金額を計算
  end
end
