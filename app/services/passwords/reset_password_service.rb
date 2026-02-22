# app/services/passwords/reset_password_service.rb
# frozen_string_literal: true

module Passwords
  # Servicio para resetear password usando token
  class ResetPasswordService < BaseService
    def initialize(token, password, password_confirmation)
      super()
      @token = token
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      validate_token_presence
      return self unless success?

      find_user
      return self unless success?

      validate_token_expiration
      return self unless success?

      reset_password
      return self unless success?

      generate_jwt_token
      self
    end

    private

    attr_reader :token, :password, :password_confirmation

    def validate_token_presence
      return if token.present?

      add_error("Token no está presente")
      @success = false
    end

    def find_user
      @user = User.find_by(reset_password_token: token)
      return if @user.present?

      add_error("Token inválido o expirado")
      @success = false
    end

    def validate_token_expiration
      return if @user.password_token_valid?

      add_error("El enlace ha expirado. Solicita un nuevo enlace de recuperación")
      @success = false
    end

    def reset_password
      # Valida que ambos campos estén presentes
      if password.blank?
        add_error("Password es requerido")
        @success = false
        return
      end

      if password_confirmation.blank?
        add_error("Password confirmation es requerido")
        @success = false
        return
      end

      @user.password = password
      @user.password_confirmation = password_confirmation

      unless @user.save
        @user.errors.full_messages.each { |error| add_error(error) }
        @success = false
        return
      end

      # Limpia el token después de resetear
      @user.update!(reset_password_token: nil)
    end

    def generate_jwt_token
      @result = {
        token: JsonWebTokenService.encode(user_id: @user.id),
        user: @user
      }
    end
  end
end
