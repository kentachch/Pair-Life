class SettlementsController < ApplicationController
  before_action :require_household

  def index
    @household = current_user.household
    # 初期表示は先月(当月はまだ精算できないため)
    @month = selected_month(default: Date.current.prev_month.beginning_of_month)

    @monthly_total = @household.monthly_total(@month)
    @payer_totals = @household.payer_totals(@month)

    # 精算済みなら保存された記録を、未精算なら計算した結果(保存前)を表示する
    # パートナーが未参加の世帯では nil になる
    @settlement = @household.settlements.find_by(target_month: @month) ||
                  Settlement.build_for(@household, @month)
  end

  def create
    household = current_user.household
    month = selected_month
    # 処理のあとは、精算した月の画面に戻る
    redirect_path = settlements_path(month: month.strftime("%Y-%m"))

    # 金額はフォームから受け取らず、サーバー側でもう一度計算する(画面の値を書き換えられても安全)
    settlement = Settlement.build_for(household, month)
    return redirect_to redirect_path, alert: "パートナーが参加すると精算できます。" if settlement.nil?

    settlement.settled_at = Time.current
    if settlement.save
      redirect_to redirect_path, notice: "#{month.strftime('%-m月')}を精算済みにしました。"
    else
      # 当月・未来の月や、精算済みの月はバリデーションで保存されない
      redirect_to redirect_path, alert: settlement.errors.full_messages.to_sentence
    end
  rescue ActiveRecord::RecordNotUnique
    # ボタンの二度押しなどで、同じ月を同時に保存しようとした場合(ユニークインデックスで防がれる)
    redirect_to redirect_path, alert: "この月はすでに精算済みです。"
  end
end
