# app/controllers/api/v1/profiles_controller.rb
# frozen_string_literal: true

module Api
  module V1
    class ProfilesController < ApplicationController
      # GET /api/v1/profile
      def show
        # No necesita authorize! - es el perfil del mismo usuario autenticado
        render json: {
          status: { code: 200, message: "Perfil obtenido exitosamente" },
          data: UserSerializer.new(@current_user).serializable_hash[:data][:attributes]
        }, status: :ok
      end

      # PATCH /api/v1/profile
      def update
        # No necesita authorize! - solo puede editar su propio perfil
        service = Users::UpdateProfileService.new(@current_user, profile_params)
        service.call

        if service.success?
          render json: {
            status: { code: 200, message: "Perfil actualizado exitosamente" },
            data: UserSerializer.new(service.result).serializable_hash[:data][:attributes]
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo actualizar el perfil" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end

      private

      def profile_params
        params.require(:profile).permit(:first_name, :last_name, :email, :password, :password_confirmation)
      end
    end
  end
end
