# app/services/passwords/forgot_password_service.rb
# frozen_string_literal: true

module Passwords
  # Servicio para generar token de reset y enviar email
  class ForgotPasswordService < BaseService
    def initialize(email)
      super()
      @email = email&.strip&.downcase
    end

    def call
      validate_email
      return self unless success?

      find_user
      # Por seguridad, siempre retorna success true aunque el usuario no exista
      return self unless @user

      validate_user_status
      return self unless @user.present?  # ← AGREGA ESTE CHECK

      generate_reset_token
      send_reset_email
      self
    end

    private

    attr_reader :email

    def validate_email
      if email.blank?
        add_error("Email es requerido")
        @success = false
      end
    end

    def find_user
      @user = User.find_by(email: email)
    end

    def validate_user_status
      # Solo envía email si el usuario está activo y confirmado
      unless @user.active? && @user.confirmed_at.present?
        # No agrega error por seguridad, pero marca como que no debe continuar
        @user = nil
        @success = true
      end
    end

    def generate_reset_token
      @user.generate_password_token!
    end

    def send_reset_email
      UserMailer.reset_password_instructions(@user).deliver_later
    end
  end
end
