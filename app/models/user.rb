class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  validates :name, presence: true

  has_one :household_member, dependent: :destroy
  has_one :household, through: :household_member

  # Google から受け取った情報(auth)をもとに、ログインさせるユーザーを返す
  # 1. すでに Google で紐付け済みのユーザーがいれば、そのユーザー
  # 2. 同じメールアドレスのユーザーがいれば、Google と紐付けてそのユーザー
  # 3. どちらもいなければ、新しくユーザーを作る
  # 保存に失敗したときは、保存されていないユーザー(persisted? が false)を返す
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Google がメールアドレスの持ち主であることを確認済みの場合だけ、既存のアカウントと紐付ける
    # (確認されていないメールアドレスで、他人のアカウントに入れてしまうのを防ぐ)
    return new unless auth.extra.raw_info.email_verified

    user = find_or_initialize_by(email: auth.info.email)
    user.provider = auth.provider
    user.uid = auth.uid
    if user.new_record?
      user.name = auth.info.name.presence || auth.info.email.split("@").first
      # パスワードは使わないが、Devise の必須項目なのでランダムな値を入れておく
      user.password = Devise.friendly_token[0, 20]
    end
    user.save
    user
  end
end
