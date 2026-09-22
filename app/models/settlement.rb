class Settlement < ApplicationRecord
  belongs_to :household
  # 精算額が 0 円の月は、支払う人・受け取る人がいないので optional: true
  belongs_to :from_user, class_name: "User", optional: true
  belongs_to :to_user, class_name: "User", optional: true

  validates :target_month, presence: true, uniqueness: { scope: :household_id }
  validates :settled_at, presence: true
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # 自作のメソッドで検証するときは validates ではなく validate(s なし)を使う
  validate :target_month_must_be_first_day
  validate :target_month_must_be_over, on: :create
  validate :users_must_match_amount
  validate :users_must_be_household_members

  # 指定した月の精算内容を計算して、保存前の Settlement を返す
  # メンバーが2人そろっていないときは nil を返す
  def self.build_for(household, month)
    month = month.beginning_of_month
    members = household.household_members.includes(:user).to_a
    return nil if members.size < Household::MAX_MEMBERS

    paid = household.payer_totals(month) # { User => 実際に払った額 }
    total = paid.values.sum

    # メンバーごとの差額 = 実際に払った額 − 本来の負担額
    # 100r は有理数の 100。割り算の誤差(0.1 + 0.2 = 0.30000000000000004 のようなもの)を防ぐ
    differences = members.to_h do |member|
      share = total * member.burden_ratio / 100r
      [ member.user, paid.fetch(member.user, 0) - share ]
    end

    # 差額が一番大きい人(払いすぎた人)が受け取り、一番小さい人(不足している人)が支払う
    to_user, overpaid = differences.max_by { |_user, difference| difference }
    from_user, = differences.min_by { |_user, difference| difference }
    amount = overpaid.floor # 端数は切り捨て

    if amount.zero?
      new(household: household, target_month: month, amount: 0)
    else
      new(household: household, target_month: month, from_user: from_user, to_user: to_user, amount: amount)
    end
  end

  private

  # 対象月は「その月の1日」で保存する決まり
  def target_month_must_be_first_day
    return if target_month.nil?
    errors.add(:target_month, "は月の1日を指定してください。") unless target_month.day == 1
  end

  # 精算できるのは、対象月が終わってから(当月・未来の月は不可)
  def target_month_must_be_over
    return if target_month.nil?
    errors.add(:target_month, "が終わっていないため、精算できません。") if target_month >= Date.current.beginning_of_month
  end

  # 0円なら支払う人・受け取る人は空。1円以上なら両方必要
  def users_must_match_amount
    if amount.to_i.zero?
      errors.add(:base, "精算額が0円のときは、支払う人と受け取る人を指定できません。") if from_user || to_user
    elsif from_user.nil? || to_user.nil?
      errors.add(:base, "支払う人と受け取る人を指定してください。")
    end
  end

  # 支払う人・受け取る人は、同じ世帯のメンバーでなければならない
  def users_must_be_household_members
    return if household.nil?
    [ from_user, to_user ].compact.each do |user|
      errors.add(:base, "#{user.name}さんは世帯のメンバーではありません。") unless household.users.include?(user)
    end
  end
end
