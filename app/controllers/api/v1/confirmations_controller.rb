# app/controllers/api/v1/confirmations_controller.rb
# frozen_string_literal: true

module Api
  module V1
    # ConfirmationsController - Manejo de confirmaciones de email
    class ConfirmationsController < ApplicationController
      skip_before_action :authorize_request

      # POST /api/v1/confirmation/confirm
      def confirm
        service = Confirmations::ConfirmUserService.new(params[:token])
        service.call

        if service.success?
          render json: {
            status: { code: 200, message: "Cuenta confirmada exitosamente" },
            data: UserSerializer.new(service.result[:user]).serializable_hash[:data][:attributes],
            token: service.result[:token]
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo confirmar la cuenta" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end

      # POST /api/v1/confirmation/resend
      def resend
        service = Confirmations::ResendConfirmationService.new(params[:email])
        service.call

        if service.success?
          render json: {
            status: {
              code: 200,
              message: "Si el email existe y no está confirmado, recibirás instrucciones de confirmación"
            }
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "No se pudo reenviar la confirmación" },
            errors: service.errors
          }, status: :unprocessable_content
        end
      end
    end
  end
end
