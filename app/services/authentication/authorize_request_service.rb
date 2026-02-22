# frozen_string_literal: true

module Authentication
    # AuthorizeRequestService - Servicio para autorizar requests con JWT
    class AuthorizeRequestService
        attr_reader :headers, :errors

        def initialize(headers = {})
            @headers = headers
            @errors = []
        end

        def call
            user
        end

        def success?
            errors.empty?
        end

        private

        def user
            return nil unless decoded_token

            @user ||= User.find_by(id: decoded_token[:user_id])
            
            unless @user
                @errors << 'Usuario no encontrado'
                return nil
            end

            @user
        end

        def decoded_token
            return nil unless auth_header

            @decoded_token ||= JsonWebTokenService.decode(auth_header)
            
            unless @decoded_token
                @errors << 'Token inválido o expirado'
                return nil
            end

            @decoded_token
        end

        def auth_header
            if headers['Authorization'].present?
                return headers['Authorization'].split(' ').last
            else
                @errors << 'Token no presente'
                nil
            end
        end
    end
end