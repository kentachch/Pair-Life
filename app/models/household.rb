class Household < ApplicationRecord
  MAX_MEMBERS = 2
  DEFAULT_CATEGORY_NAMES = %w[家賃 水道代 電気代 ガス代 食費 日用品 外食 雑費 交際費 その他].freeze
  has_many :household_members, dependent: :destroy
  has_many :users, through: :household_members
  has_many :categories, dependent: :destroy
  # 世帯・家族・パートナー同士の名前
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
      DEFAULT_CATEGORY_NAMES.each do |category_name|
        household.categories.create!(name: category_name)
      end
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
