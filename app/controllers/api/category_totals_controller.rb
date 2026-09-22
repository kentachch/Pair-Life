module Api
  class CategoryTotalsController < ApplicationController
    def index
      household = current_user.household
      # 世帯に未所属のときは、画面用のようにリダイレクトせず「見つからない」を返す
      return head :not_found if household.nil?

      # ?month=2026-09 のように指定された月。指定がなければ今月
      month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current

      render json: {
        month: month.strftime("%Y-%m"),
        categories: household.category_totals(month).map { |name, amount| { name: name, amount: amount } }
      }
    rescue Date::Error
      # month が「2026-09」の形になっていないときは、400(リクエストが不正)を返す
      head :bad_request
    end
  end
end
