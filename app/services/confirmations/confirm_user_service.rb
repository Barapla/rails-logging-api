# app/services/confirmations/confirm_user_service.rb
# frozen_string_literal: true

module Confirmations
  # Servicio para confirmar cuenta de usuario mediante token
  class ConfirmUserService < BaseService
    def initialize(token)
      super()
      @token = token
    end

    def call
      validate_token_presence
      return self unless success?

      find_user
      return self unless success?

      validate_token_expiration
      return self unless success?

      confirm_user
      return self unless success?

      generate_jwt_token
      self
    end

    private

    attr_reader :token

    def validate_token_presence
      return if token.present?

      add_error("Token no está presente")
      @success = false
    end

    def find_user
      @user = User.find_by(confirmation_token: token)
      return if @user.present?

      add_error("Token inválido o expirado")
      @success = false
    end

    def validate_token_expiration
      return if @user.confirmation_token_valid?

      add_error("El enlace ha expirado. Solicita un nuevo enlace de confirmación")
      @success = false
    end

    def confirm_user
      unless @user.confirm!
        add_error("No se pudo confirmar la cuenta")
        @success = false
      end
    end

    def generate_jwt_token
      @result = {
        token: JsonWebTokenService.encode(user_id: @user.id),
        user: @user
      }
    end
  end
end
