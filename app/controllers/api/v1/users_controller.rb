# app/controllers/api/v1/users_controller.rb
# frozen_string_literal: true

module Api
  module V1
    # UsersController - Gestión de usuarios (solo admin)
    class UsersController < ApplicationController
      include SoftDeletableController
      # GET /api/v1/users
      def index
        authorize!(User, :index)

        users = policy_scope(User).includes(:role)
        users = apply_soft_delete_scope(users)

        render json: {
          status: { code: 200, message: "Usuarios obtenidos exitosamente" },
          data: users.map { |user| UserSerializer.new(user).serializable_hash[:data][:attributes] }
        }, status: :ok
      end
    end
  end
end
