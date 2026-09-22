class Settlement < ApplicationRecord
  belongs_to :household
  # 精算額が 0 円の月は、支払う人・受け取る人がいないので optional: true
  belongs_to :from_user, class_name: "User", optional: true
  belongs_to :to_user, class_name: "User", optional: true

  validates :target_month, presence: true, uniqueness: { scope: :household_id }
  validates :settled_at, presence: true
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :target_month_must_be_first_day
  validates :target_month_must_be_over, on: :create
  validates :users_must_match_amount
  validates :users_must_be_household_members

  private

  def target_month_must_be_first_day
    return if target_month.nil?
    errors.add(:target_month, "は月の1日を指定してください。") unless target_month.day == 1
  end

  # 精算できるのは、対象月が終わってから(当月・未来の月は不可)
  def target_month_must_be_over
    return if target_month.nil?
    errors.add(:target_month, "が終わっていないため、精算できません。") if target_month >= Date.current.beginning_of_month
  end

  def users_must_match_amount
    if amount.to_i.zero?
      errors.add(:base, "精算額が0円のときは、支払う人と受け取る人を指定できません。") if from_user || to_user
    elsif from_user.nil? || to_user.nil?
      errors.add(:base, "支払う人と受け取る人を指定してください。")
    end
  end

  def users_must_be_household_members
    return if household.nil?
    [ from_user, to_user ].compact.each do |user|
      errors.add(:base, "#{user.name}さんは世帯のメンバーではありません。")
    end
  end
end
