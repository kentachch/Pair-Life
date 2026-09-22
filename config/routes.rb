Rails.application.routes.draw do
  devise_for :users
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
