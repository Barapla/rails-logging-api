# frozen_string_literal: true

module Api
    module V1
        # ApplicationController - Controlador base para API v1
        class ApplicationController < ActionController::API
            include Authorizable
            before_action :authorize_request

            attr_reader :current_user

            private

            def authorize_request
                service = Authentication::AuthorizeRequestService.new(request.headers)
                @current_user = service.call

                return if @current_user

                render json: {
                status: { code: 401, message: "No autorizado" },
                errors: service.errors
                }, status: :unauthorized
            end
        end
    end
end
