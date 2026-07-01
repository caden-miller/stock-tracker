Rails.application.routes.draw do
  # Main dashboard — Truthifi-powered monitoring
  get  "dashboard",      to: "dashboard#index", as: :dashboard
  post "dashboard/sync", to: "dashboard#sync",  as: :dashboard_sync

  # Truthifi OAuth 2.1 connection flow
  namespace :truthifi do
    get    "connect",    to: "connections#new",     as: :connect
    get    "callback",   to: "connections#callback", as: :callback
    delete "disconnect", to: "connections#destroy",  as: :disconnect
  end

  namespace :brokerage do
    resources :accounts, only: [:index, :show] do
      collection { post :sync }
    end
  end

  namespace :banking do
    resources :accounts, only: [:index, :show] do
      collection { post :sync }
    end
  end

  resources :stocks
  resources :balances
  resources :stock_holdings

  root "dashboard#index"
end
