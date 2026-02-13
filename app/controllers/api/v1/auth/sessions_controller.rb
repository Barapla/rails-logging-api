# frozen_string_literal: true

module Api
    module V1
        module Auth
            # SessionsController handles login/logout
            class SessionsController < Devise::SessionsController
                respond_to :json

                # POST /api/v1/auth/login
                def create
                    super do |resource|
                        if resource.persisted?
                            render json: {
                                status: { code: 200, message: "Logged in successfully." },
                                data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
                            }, status: :ok and return
                        end
                    end
                end

                # DELETE /api/v1/auth/logout
                def destroy
                    super do
                        render json: {
                            status: { code: 200, message: "Logged out successfully." }
                        }, status: :ok and return
                    end
                end

                private

                def respond_with(resource, _opts = {})
                    render json: {
                        status: { code: 200, message: "Logged in successfully." },
                        data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
                    }, status: :ok
                end

                def respond_to_on_destroy
                    if request.headers["Authorization"].present?
                        render json: {
                        status: { code: 200, message: "Logged out successfully." }
                        }, status: :ok
                    else
                        render json: {
                        status: { code: 401, message: "Couldn't find an active session." }
                        }, status: :unauthorized
                    end
                end
            end
        end
    end
end
