class Household < ApplicationRecord
  MAX_MEMBERS = 2

  has_many :household_members, dependent: :destroy
  has_many :users, through: :household_members
  # 世帯・家族・パートナー同士の名前
  validates :name, presence: true

  # 世帯を作るときに招待コードを自動で発行する
  before_create :generate_invite_code

  def full? # 世帯の人数が上限に達しているかどうかを判定する
    household_members.count >= MAX_MEMBERS
  end

  private

  def generate_invite_code
    loop do # 無限に繰り返す処理
      self.invite_code = SecureRandom.hex(4) # 8文字のランダムな16進数を生成
      break unless Household.exists?(invite_code: invite_code) # 重複がなければループを抜ける
      # 同じ招待コードが既にデータベースに存在するか？」を確認する処理
      # unless：条件が false のときに実行する
    end
  end
end
