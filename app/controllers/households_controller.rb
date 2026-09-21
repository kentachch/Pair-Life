class HouseholdsController < ApplicationController
  def new
    @household = Household.new
  end

  def create
    @household = Household.create_with_owner!(name: household_params[:name], user: current_user)
    redirect_to household_path(@household), notice: "世帯を作成しました。招待コードをパートナーに伝えてください。"

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
