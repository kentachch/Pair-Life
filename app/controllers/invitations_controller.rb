class InvitationsController < ApplicationController
  # すでに世帯に所属している人は、招待コードで参加できない
  before_action :reject_household_member

  def new
  end

  def create
    # invite_codeを探す。空白は削除し、小文字で入力されても見つかるよう大文字にそろえる
    household = Household.find_by(invite_code: params[:invite_code].to_s.strip.upcase)

    if household.nil?
      flash.now[:alert] = "招待コードが正しくないか、すでに使用されています。"
      render :new, status: :unprocessable_entity
    else
      household.add_member!(current_user) # householdにcurrent_userを追加する
      redirect_to household_path, notice: "世帯に参加しました。"
    end
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "この世帯には参加できません。"
    render :new, status: :unprocessable_entity
  end
end
