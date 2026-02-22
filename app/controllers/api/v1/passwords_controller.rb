# app/controllers/api/v1/passwords_controller.rb
# frozen_string_literal: true

module Api
  module V1
    # PasswordsController - Manejo de recuperación de contraseña
    class PasswordsController < ApplicationController
      skip_before_action :authorize_request

      # POST /api/v1/password/forgot
      def forgot
        service = Passwords::ForgotPasswordService.new(params[:email])
        service.call

        if service.success?
          render json: {
            status: {
              code: 200,
              message: "Si el email existe, recibirás instrucciones para restablecer tu contraseña"
            }
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo procesar la solicitud" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end

      # POST /api/v1/password/reset
      def reset
        service = Passwords::ResetPasswordService.new(
          params[:token],
          params[:password],
          params[:password_confirmation]
        )

        service.call

        if service.success?
          render json: {
            status: { code: 200, message: "Contraseña restablecida exitosamente" },
            data: UserSerializer.new(service.result[:user]).serializable_hash[:data][:attributes],
            token: service.result[:token]
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo restablecer la contraseña" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end
    end
  end
end
