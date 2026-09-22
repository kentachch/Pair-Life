Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  devise_scope :user do
    get   "users/sign_up", to: "devise/registrations#new",    as: :new_user_registration
    post  "users",         to: "devise/registrations#create", as: :user_registration
    get   "users/edit",    to: "devise/registrations#edit",   as: :edit_user_registration
    patch "users",         to: "devise/registrations#update"
    put   "users",         to: "devise/registrations#update"
  end

  # 死活監視用の URL。アプリが正常に起動していれば 200 を返す
  # Render のヘルスチェック(render.yaml の healthCheckPath)が、この URL にアクセスする
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
  resource :household, only: [ :new, :create, :show ]
  resource :invitation, only: [ :new, :create ]
  resources :categories, except: [ :show ]
  resources :expenses, except: [ :show ]
  resources :settlements, only: [ :index, :create ]

  # JSON を返す API は、画面用の URL と区別するため /api の下にまとめる
  namespace :api do
    resources :category_totals, only: [ :index ] # カテゴリ別の支出合計(円グラフ用)
  end
end
