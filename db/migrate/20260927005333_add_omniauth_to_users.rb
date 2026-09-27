# Google などの外部サービスでログインするためのカラム
# provider … どのサービスか(例: "google_oauth2")
# uid      … そのサービス上でのユーザーID
class AddOmniauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    # 同じサービスの同じユーザーが、2つのアカウントに紐付かないようにする
    add_index :users, [ :provider, :uid ], unique: true
  end
end
