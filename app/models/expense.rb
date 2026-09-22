class Expense < ApplicationRecord
  belongs_to :household
  # payer_id は users テーブルを参照するので、class_name で User モデルを指定する
  belongs_to :payer, class_name: "User"
  belongs_to :category

  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :spent_on, presence: true
  validates :memo, length: { maximum: 255 }

  # 自作のメソッドで検証するときは validates ではなく validate(s なし)を使う
  validate :payer_must_be_household_member
  validate :category_must_belong_to_household

  scope :in_month, ->(date) { where(spent_on: date.all_month) }
  # dateを引数として受け取って、その月の1日から末日までの範囲で絞り込むスコープを定義。

  scope :recent, -> { order(spent_on: :desc, created_at: :desc) }
  # 日付の新しい順。同じ日付なら後から登録したものを上にする

  private

  def payer_must_be_household_member
    return if payer.nil? || household.nil?
    errors.add(:payer, "は世帯のメンバーではありません。") unless household.users.include?(payer)
  end

  def category_must_belong_to_household
    return if category.nil? || household.nil?
    errors.add(:category, "はこの世帯のカテゴリーではありません。") unless category.household_id == household.id
  end
end
