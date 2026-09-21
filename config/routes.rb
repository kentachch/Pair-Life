Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  resource :household, only: [ :new, :create, :show ] do # 世帯の作成・表示
  resource :household_members, only: [ :new, :create ] # 世帯メンバーの追加
  end
end
