Rails.application.routes.draw do
  resources :balances
  resources :stock_holdings
  root 'balances#index'
end

