# frozen_string_literal: true

module Api
  module V1
    module Auth
      # RegistrationsController handles user registration
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        # POST /api/v1/auth/signup
        def create
          build_resource(sign_up_params)

          resource.save
          yield resource if block_given?

          if resource.persisted?
            sign_up(resource_name, resource) if resource.active_for_authentication?
            render json: {
              status: { code: 201, message: "Signed up successfully." },
              data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
            }, status: :created
          else
            clean_up_passwords resource
            set_minimum_password_length
            render json: {
              status: { code: 422, message: "User couldn't be created successfully." },
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              status: { code: 201, message: "Signed up successfully." },
              data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
            }, status: :created
          else
            render json: {
              status: { code: 422, message: "User couldn't be created successfully." },
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
