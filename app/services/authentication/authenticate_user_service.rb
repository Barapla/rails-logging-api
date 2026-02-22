# app/services/authentication/authenticate_user_service.rb
# frozen_string_literal: true

module Authentication
  # Servicio para autenticar un usuario y generar token JWT
  class AuthenticateUserService < BaseService
    def initialize(email, password)
      super()
      @email = email&.strip&.downcase
      @password = password
    end

    def call
      validate_params
      return self unless success?

      find_user
      return self unless success?

      validate_password
      return self unless success?

      validate_confirmation
      return self unless success?

      validate_active_status
      return self unless success?

      generate_jwt_token
      self
    end

    private

    attr_reader :email, :password

    def validate_params
      if email.blank?
        add_error("Email es requerido")
        @success = false
        return
      end

      if password.blank?
        add_error("Password es requerido")
        @success = false
      end
    end

    def find_user
      @user = User.with_inactive.find_by(email: email)

      unless @user
        add_error("Email o password incorrectos")
        @success = false
      end
    end

    def validate_password
      unless @user.authenticate(password)
        add_error("Email o password incorrectos")
        @success = false
      end
    end

    def validate_confirmation
      unless @user.confirmed_at.present?
        add_error("Debes confirmar tu cuenta antes de iniciar sesión")
        @success = false
      end
    end

    def validate_active_status
      unless @user.active?
        add_error("Tu cuenta está inactiva. Contacta al administrador")
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
