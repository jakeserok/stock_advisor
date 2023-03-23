Rails.application.routes.draw do
  devise_for :users
  root "stock_info#index"
  get 'stocks', to: 'stock_info#stocks'
  get 'stock', to: 'stock_info#stock'
end
