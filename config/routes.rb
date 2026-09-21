Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  resource :household, only: [ :new, :create, :show ] # 世帯の作成・表示
  resource :invitation, only: [ :new, :create ]        # 招待コードでの参加
  resources :categories, except: [ :show ] # カテゴリの作成・編集・削除
  resources :expenses, except: [ :show ]   # 支出の作成・編集・削除
end
