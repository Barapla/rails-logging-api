# app/services/json_web_token_service.rb
# frozen_string_literal: true

class JsonWebTokenService
  SECRET_KEY = Rails.application.credentials.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    # Verificar si está en blacklist
    return nil if blacklisted?(token)

    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

    def self.blacklisted?(token)
        REDIS.exists?("blacklist:#{token}")  # ← Cambia Redis.current a REDIS
    rescue Redis::BaseError
        false
    end
end
