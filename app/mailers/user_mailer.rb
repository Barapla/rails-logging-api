class UserMailer < ApplicationMailer
    def welcome_email
        @user = params[:user]
        @url  = "http://example.com/login"
        mail(to: @user.email, subject: "Bienvenido a MiDoc")
    end

    def recovery_email
        @user = params[:user]
        mail(to: @user.email, subject: "Correo de recuperación")
    end

    def confirmation_instructions
        @user = params[:user]
        mail(to: @user.email, subject: "Correo de confirmación")
    end

    def reset_password_instructions(user)
        @user = user
        @reset_url = "#{ENV.fetch('FRONTEND_URL')}/reset-password?token=#{user.reset_password_token}"
        mail(to: @user.email, subject: "Instrucciones para restablecer tu contraseña")
    end
end
