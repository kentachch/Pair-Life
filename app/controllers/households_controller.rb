class HouseholdsController < ApplicationController
  # すでに世帯に所属している人は、新しく世帯を作れない
  before_action :reject_household_member, only: [ :new, :create ]
  # 世帯に所属していない人は、世帯の詳細を見られない
  before_action :require_household, only: [ :show ]

  def new
    @household = Household.new
  end

  def create
    @household = Household.create_with_owner!(name: household_params[:name], user: current_user)
    # resource(単数形)のルーティングなので、household_path に引数は渡さない
    redirect_to household_path, notice: "世帯を作成しました。招待コードをパートナーに伝えてください。"

  rescue ActiveRecord::RecordInvalid => e # e：発生した例外オブジェクト
    @household = e.record.is_a?(Household) ? e.record : Household.new(household_params)
    render :new, status: :unprocessable_entity
  end

  def show
    @household = current_user.household
  end

  private

  def household_params # params：フォームから送信された値
    params.require(:household).permit(:name)
  end
end
