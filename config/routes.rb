Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  devise_scope :user do
    get   "users/sign_up", to: "devise/registrations#new",    as: :new_user_registration
    post  "users",         to: "devise/registrations#create", as: :user_registration
    get   "users/edit",    to: "devise/registrations#edit",   as: :edit_user_registration
    patch "users",         to: "devise/registrations#update"
    put   "users",         to: "devise/registrations#update"
  end

  root "home#index"
  resource :household, only: [ :new, :create, :show ] # 世帯の作成・表示
  resource :invitation, only: [ :new, :create ]        # 招待コードでの参加
  resources :categories, except: [ :show ] # カテゴリの作成・編集・削除
  resources :expenses, except: [ :show ]   # 支出の作成・編集・削除

  # JSON を返す API は、画面用の URL と区別するため /api の下にまとめる
  namespace :api do
    resources :category_totals, only: [ :index ] # カテゴリ別の支出合計(円グラフ用)
  end
end
