# app/services/users/update_profile_service.rb
# frozen_string_literal: true

module Users
  # Servicio para actualizar perfil de usuario
  class UpdateProfileService < BaseService
    def initialize(user, attributes)
      super()
      @user = user
      @attributes = attributes
    end

    def call
      update_user
      self
    end

    private

    attr_reader :user, :attributes

    def update_user
      if user.update(attributes)
        @result = user
      else
        user.errors.full_messages.each { |error| add_error(error) }
        @success = false
      end
    end
  end
end
