class ExpensesController < ApplicationController
  before_action :require_household
  before_action :set_expense, only: [ :edit, :update, :destroy ]

  def index
    household = current_user.household
    # 表示する月(?month=2026-09 のように指定。指定がなければ今月)
    @month = selected_month

    # 表示中の月の支出だけを、日付の新しい順に並べる
    @expenses = household.expenses
                         .in_month(@month)
                         .includes(:payer, :category) # N+1問題を避けるために、関連するテーブルをあらかじめ読み込む
                         .recent
    @monthly_total = household.monthly_total(@month)
  end

  def new
    # 日付は今日、支払った人は自分を初期値にしておく
    @expense = current_user.household.expenses.build(spent_on: Date.current, payer: current_user)
  end

  def create
    @expense = current_user.household.expenses.build(expense_params)
    if @expense.save
      # 登録した支出が見えるよう、その支出の月の一覧に戻る
      redirect_to expenses_path(month: @expense.spent_on.strftime("%Y-%m")), notice: "支出を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path(month: @expense.spent_on.strftime("%Y-%m")), notice: "支出を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path(month: @expense.spent_on.strftime("%Y-%m")), notice: "支出を削除しました。", status: :see_other
  end

  private

  # ?month=2026-09 を日付(その月の1日)に変換する。指定がない・形式が正しくないときは今月にする
  def selected_month
    Date.strptime(params[:month].to_s, "%Y-%m")
  rescue Date::Error
    Date.current.beginning_of_month
  end

  def set_expense
    @expense = current_user.household.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:amount, :spent_on, :memo, :payer_id, :category_id)
  end
end
