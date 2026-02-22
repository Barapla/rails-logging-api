# app/services/authentication/register_user_service.rb
# frozen_string_literal: true

module Authentication
  # Servicio para registrar un nuevo usuario y enviar confirmación
  class RegisterUserService < BaseService
    def initialize(user_params)
      super()
      @user_params = user_params
    end

    def call
      create_user
      return self unless success?

      generate_confirmation_token
      send_confirmation_email

      @result = @user
      self
    end

    private

    attr_reader :user_params

    def create_user
      @user = User.new(user_params)

      unless @user.save
        @user.errors.full_messages.each { |error| add_error(error) }
        @success = false
      end
    end

    def generate_confirmation_token
      @user.generate_confirmation_token!
    end

    def send_confirmation_email
      UserMailer.confirmation_instructions(@user).deliver_later
    end
  end
end
