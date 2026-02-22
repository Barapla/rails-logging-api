# app/services/confirmations/resend_confirmation_service.rb
# frozen_string_literal: true

module Confirmations
  # Servicio para reenviar email de confirmación
  class ResendConfirmationService < BaseService
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
      return self unless @user.present?

      validate_not_confirmed
      return self unless success?

      regenerate_confirmation_token
      send_confirmation_email
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
      # Solo envía email si el usuario está activo
      unless @user.active?
        # No agrega error por seguridad, pero marca como que no debe continuar
        @user = nil
        @success = true
      end
    end

    def validate_not_confirmed
      if @user.confirmed_at.present?
        add_error("Tu cuenta ya está confirmada")
        @success = false
      end
    end

    def regenerate_confirmation_token
      @user.generate_confirmation_token!
    end

    def send_confirmation_email
      UserMailer.confirmation_instructions(@user).deliver_later
    end
  end
end
