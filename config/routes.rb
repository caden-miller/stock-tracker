Rails.application.routes.draw do
  resources :stocks
  resources :balances
  resources :stock_holdings

  namespace :brokerage do
    get "connect", to: "connections#new"
    get "callback", to: "connections#callback"
    resources :accounts, only: [:index, :show] do
      collection { post :sync }
    end
  end

  namespace :banking do
    get "connect", to: "connections#new"
    post "connect", to: "connections#create"
    post "webhook", to: "connections#webhook"
    resources :accounts, only: [:index, :show] do
      collection { post :sync }
    end
  end

  root "balances#index"
end
