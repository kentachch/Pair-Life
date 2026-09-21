class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :payer
  belongs_to :category

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :spent_on, presence: true
  validates :memo, length: { maximum: 255 }

  validates :payer_must_be_household_member
  validates :category_must_belong_to_household

  private

  def payer_must_be_household_member
    return if payer.nil? || household.nil?
    errors.add(:payer, "は世帯のメンバーではありません。") unless household.users.includes?(payer)
  end

  def category_must_belong_to_household
    return if category.nil? || household.nil?
    errors.add(:category, "はこの世帯のカテゴリーではありません。") unless category.household_id == household.id
  end
end
