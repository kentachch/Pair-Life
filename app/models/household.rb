class Household < ApplicationRecord
  MAX_MEMBERS = 2

  DEFAULT_CATEGORIES = {
    "家賃" => "house",
    "水道代" => "droplet",
    "電気代" => "zap",
    "ガス代" => "flame",
    "食費" => "shopping-basket",
    "日用品" => "spray-can",
    "外食" => "utensils",
    "雑費" => "shapes",
    "交際費" => "gift",
    "その他" => "circle-ellipsis"
  }.freeze

  has_many :household_members, dependent: :destroy
  has_many :users, through: :household_members
  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy

  validates :name, presence: true

  # 世帯を作るときに招待コードを自動で発行する
  before_create :generate_invite_code

  def full? # 世帯の人数が上限に達しているかどうかを判定する
    household_members.count >= MAX_MEMBERS
  end

  # 世帯を作成し、作成者を1人目のメンバーとして登録する
  # 途中で失敗したら両方なかったことにするため、トランザクションでまとめる
  def self.create_with_owner!(name:, user:) # nameとuserを引数として受け取る
    transaction do
      household = create!(name: name)

      # 世帯作成時に初期カテゴリを自動で作る
      household.add_default_categories!
      household.household_members.create!(user: user)
      household
    end
  end

  # 世帯にメンバーを追加するメソッド
  def add_member!(user)
    transaction do
      household_members.create!(user: user)
      update!(invite_code: nil) if full? # 2人そろったら招待コードを無効にする
    end
  end

  # 初期カテゴリのうち、まだない物を追加する。何度実行しても同じカテゴリは重複しない
  # 同じ名前のカテゴリがすでにあり、アイコンが未設定(初期値の "tag")なら、初期カテゴリのアイコンにする
  def add_default_categories!
    DEFAULT_CATEGORIES.each do |name, icon|
      category = categories.find_or_initialize_by(name: name) # 探してなければ作る
      category.icon = icon if category.new_record? || category.icon == Category::DEFAULT_ICON
      category.save!
    end
  end

  # 指定した月の支出の合計金額
  def monthly_total(month)
    expenses.in_month(month).sum(:amount)
  end

  # 指定した月のカテゴリ別の支出合計を、金額の大きい順に返す
  # 例：[["家賃", 80000], ["食費", 45800], ["日用品", 3200]]
  def category_totals(month)
    expenses.in_month(month)
            .joins(:category)             # 支出テーブルにカテゴリテーブルをつなげる
            .group("categories.name")     # テーブル名は複数形の categories
            .sum(:amount)
            .sort_by { |_name, amount| -amount } # マイナスを付けると大きい順になる
  end

  private

  def generate_invite_code
    loop do # 無限に繰り返す処理
      self.invite_code = SecureRandom.hex(4).upcase # 8文字のランダムな16進数を生成し、読みやすいよう大文字にする
      break unless Household.exists?(invite_code: invite_code) # 重複がなければループを抜ける
      # 同じ招待コードが既にデータベースに存在するか？」を確認する処理
      # unless：条件が false のときに実行する
    end
  end
end
