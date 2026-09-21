class ExpensesController < ApplicationController
  before_action :require_household
  before_action :set_expense, only: [ :edit, :update, :destroy ]

  def index
    # 日付の新しい順。同じ日付なら後から登録したものを上にする
    @expenses = current_user.household.expenses
                            .includes(:payer, :category) # N+1問題を避けるために、関連するテーブルをあらかじめ読み込む
                            .order(spent_on: :desc, created_at: :desc)
  end

  def new
    # 日付は今日、支払った人は自分を初期値にしておく
    @expense = current_user.household.expenses.build(spent_on: Date.current, payer: current_user)
  end

  def create
    @expense = current_user.household.expenses.build(expense_params)
    if @expense.save
      redirect_to expenses_path, notice: "支出を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "支出を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: "支出を削除しました。", status: :see_other
  end

  private

  def set_expense
    @expense = current_user.household.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:amount, :spent_on, :memo, :payer_id, :category_id)
  end
end
