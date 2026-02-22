# app/services/authentication/logout_service.rb
# frozen_string_literal: true

module Authentication
  # Servicio para cerrar sesión y agregar token a blacklist
  class LogoutService < BaseService
    def initialize(token)
      super()
      @token = token
    end

    def call
      validate_token_presence
      return self unless success?

      blacklist_token
      self
    end

    private

    attr_reader :token

    def validate_token_presence
      return if token.present?

      add_error("Token no proporcionado")
      @success = false
    end

    def blacklist_token
      decoded = JsonWebTokenService.decode(token)

      unless decoded
        add_error("Token inválido")
        @success = false
        return
      end

      exp_time = decoded[:exp] - Time.current.to_i

      if exp_time.positive?
        REDIS.setex("blacklist:#{token}", exp_time, "true")  # ← Cambia Redis.current a REDIS
      else
        add_error("Token ya expirado")
        @success = false
      end
    rescue JWT::DecodeError => e
      add_error("Error al decodificar token: #{e.message}")
      @success = false
    rescue Redis::BaseError => e
      add_error("Error al guardar en blacklist: #{e.message}")
      @success = false
    end
  end
end
