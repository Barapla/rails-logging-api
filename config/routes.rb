# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API namespace
  namespace :api do
    namespace :v1 do
      # Authentication routes
      namespace :auth do
        devise_for :users,
                   path: "",
                   path_names: {
                     sign_in: "login",
                     sign_out: "logout",
                     registration: "signup"
                   },
                   controllers: {
                     sessions: "api/v1/auth/sessions",
                     registrations: "api/v1/auth/registrations"
                   }
      end

      # Protected routes
      authenticate :user do
        # User profile
        resource :profile, only: [ :show, :update ], controller: "profiles"

        # Resources (example protected routes)
        resources :posts
      end
    end
  end
end
