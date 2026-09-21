class HouseholdMember < ApplicationRecord
  belongs_to :household
  belongs_to :user

  validates :user_id, uniqueness: true # ユーザーは1つの世帯にしか所属できない
  validates :burden_ratio, presence: true, 
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 } 
  # 負担の割合は0以上100以下の整数であることを検証する
  validate :household_not_full, on: :create # 世帯の人数が上限に達していないかを検証する
  # on: :create: 作成時だけチェックする

  private

  def household_not_full
    return if household.nil? # householdがnilの場合は何もしない

    # householdがfull?の場合はエラーを追加する
    errors.add(:base, "世帯の人数が上限に達しています") if household.full?
  end
end
