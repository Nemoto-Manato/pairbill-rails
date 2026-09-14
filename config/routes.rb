Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect("/dashboard")

  get "signup", to: "users#new", as: :signup
  post "signup", to: "users#create"

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "pair/setup", to: "pairs#setup"
  post "pair", to: "pairs#create"
  get "pair/invitation", to: "pair_invitations#index"
  post "pair/invitations", to: "pair_invitations#create"
  post "pair/invitations/join", to: "pair_invitations#join"
  post "pair/invitations/:id/cancel", to: "pair_invitations#cancel", as: :cancel_pair_invitation

  get "dashboard", to: "dashboard#show"

  resources :claims, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    member do
      post :approve
      post :reject
    end
  end

  get "settlements", to: "settlements#index"
  get "settlements/:year_month", to: "settlements#show", as: :settlement_month, constraints: { year_month: /\d{4}-\d{2}/ }
  post "settlements/:year_month/request", to: "settlements#request_settlement",
                                           as: :request_settlement, constraints: { year_month: /\d{4}-\d{2}/ }
  post "settlements/:id/approve", to: "settlements#approve", as: :approve_settlement
  post "settlements/:id/cancel", to: "settlements#cancel", as: :cancel_settlement

  get "notifications", to: "notifications#index", as: :notifications
  post "notifications/:id/read", to: "notifications#mark_read", as: :read_notification

  get "settings/profile", to: "profiles#edit"
  post "settings/profile", to: "profiles#update"
end
