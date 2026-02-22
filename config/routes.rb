# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  namespace :api do
    namespace :v1 do
      # Authentication
      # Sessions resource (auth)
      resource :sessions, only: [ :create, :destroy ] do
        collection do
          post :signup
        end
      end

      resources :passwords, only: [] do
        collection do
          post :forgot
          post :reset
        end
      end

      resources :confirmations, only: [] do
        collection do
          post :resend
          post :confirm
        end
      end

      # Profile (protected)
      resource :profile, only: [ :show, :update ]
      resources :users, only: [ :index ]
    end
  end
end
