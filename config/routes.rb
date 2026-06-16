Rails.application.routes.draw do
  resources :stocks
  resources :balances
  resources :stock_holdings

  namespace :brokerage do
    get "connect", to: "connections#new"
    resources :accounts, only: [:index, :show]
  end

  namespace :banking do
    get "connect", to: "connections#new"
    resources :accounts, only: [:index, :show]
  end

  root "balances#index"
end
