# frozen_string_literal: true

module Api
  module V1
    # ProfilesController handles user profile
    class ProfilesController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/profile
      def show
        render json: {
          status: { code: 200, message: "Profile retrieved successfully." },
          data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
        }, status: :ok
      end

      # PUT/PATCH /api/v1/profile
      def update
        if current_user.update(profile_params)
          render json: {
            status: { code: 200, message: "Profile updated successfully." },
            data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "Profile update failed." },
            errors: current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def profile_params
        params.require(:user).permit(:first_name, :last_name, :email)
      end
    end
  end
end
