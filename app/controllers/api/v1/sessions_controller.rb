# frozen_string_literal: true

module Api
  module V1
    # SessionsController - Manejo de sesiones y autenticación
    class SessionsController < ApplicationController
      skip_before_action :authorize_request, only: [ :create, :signup ]

      # POST /api/v1/session (login)
      def create
        service = Authentication::AuthenticateUserService.new(
          params[:email],
          params[:password]
        )

        service.call

        if service.success?
          render json: {
            status: { code: 200, message: "Sesión iniciada exitosamente" },
            data: UserSerializer.new(service.result[:user]).serializable_hash[:data][:attributes],
            token: service.result[:token]
          }, status: :ok
        else
          render json: {
            status: { code: 401, message: "Autenticación fallida" },
            errors: service.errors
          }, status: :unauthorized
        end
      end

      # POST /api/v1/session/signup
      def signup
        service = Authentication::RegisterUserService.new(user_params)
        service.call

        if service.success?
          render json: {
            status: { code: 201, message: "Usuario registrado exitosamente. Revisa tu email para confirmar tu cuenta" },
            data: UserSerializer.new(service.result).serializable_hash[:data][:attributes]
          }, status: :created
        else
          render json: {
            status: { code: 422, message: "No se pudo crear el usuario" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/sessions/destroy
      def destroy
        # @current_user ya está disponible por authorize_request
        token = request.headers["Authorization"]&.split(" ")&.last

        service = Authentication::LogoutService.new(token)
        service.call

        if service.success?
          render json: {
            status: { code: 200, message: "Sesión cerrada exitosamente" }
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo cerrar la sesión" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end
    end
  end
end
