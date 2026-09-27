class ShoppingListItem < ApplicationRecord
  # 一覧の見出しはこの順番で並べる(スーパーの売り場を回る順番)
  CATEGORIES = %w[野菜・果物 肉・魚 乳製品・卵 米・パン・パスタ 調味料 生活日用品 その他].freeze

  belongs_to :shopping_list
  # added_by_id は users テーブルを参照するので、class_name で User モデルを指定する
  belongs_to :added_by, class_name: "User"

  # 保存・検証の前に、商品名の前後の空白を取り除く
  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, length: { maximum: 30 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :memo, length: { maximum: 100 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  # false.blank? は true になるため、boolean には presence ではなく inclusion を使う
  validates :is_essential, inclusion: { in: [ true, false ] }
  validates :purchased, inclusion: { in: [ true, false ] }

  # 自作のメソッドで検証するときは validates ではなく validate(s なし)を使う
  validate :name_must_be_unique_in_list
  validate :added_by_must_be_household_member

  # 未チェック → チェック済み、必須 → 任意、追加が古い順
  scope :ordered, -> { order(:purchased, is_essential: :desc, created_at: :asc) }

  # チェックを入れる・外す
  def toggle_purchased!
    update!(purchased: !purchased)
  end

  private

  # 同じリストに同じ商品名がないか確認する。相手がチェック済みなら、チェックを外すよう案内する
  def name_must_be_unique_in_list
    return if name.blank? || shopping_list.nil?

    # 編集中のアイテム自身は比べる対象から外す
    same = shopping_list.items.where(name: name).where.not(id: id).first
    return if same.nil?

    if same.purchased?
      errors.add(:base, "「#{name}」はチェック済みです。チェックを外してください")
    else
      errors.add(:name, "はすでにリストにあります")
    end
  end

  def added_by_must_be_household_member
    return if added_by.nil? || shopping_list.nil?
    errors.add(:added_by, "は世帯のメンバーではありません。") unless shopping_list.household.users.include?(added_by)
  end
end
