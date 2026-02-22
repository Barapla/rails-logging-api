# spec/requests/api/v1/password/forgot_password_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/passwords/forgot', type: :request do
  let(:url) { '/api/v1/passwords/forgot' }
  let(:user) { create(:user, :confirmed) }

  describe 'con email válido' do
    let(:valid_params) { { email: user.email } }

    it 'retorna status 200' do
      post url, params: valid_params
      expect(response).to have_http_status(:ok)
    end

    it 'retorna mensaje de éxito' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('instrucciones')
    end

    it 'genera un reset_password_token' do
      expect {
        post url, params: valid_params
      }.to change { user.reload.reset_password_token }.from(nil)
    end

    it 'establece reset_password_sent_at' do
      expect {
        post url, params: valid_params
      }.to change { user.reload.reset_password_sent_at }.from(nil)
    end

    it 'enqueue un email de reset' do
      expect {
        post url, params: valid_params
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
    end

    it 'no retorna información sensible del usuario' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json).not_to have_key('data')
      expect(json).not_to have_key('token')
    end
  end

  describe 'con email inválido' do
    context 'cuando el email no existe' do
      let(:invalid_params) { { email: 'noexiste@example.com' } }

      it 'retorna status 200 (por seguridad)' do
        post url, params: invalid_params
        expect(response).to have_http_status(:ok)
      end

      it 'retorna mensaje genérico' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['status']['message']).to include('instrucciones')
      end

      it 'no genera ningún token' do
        expect {
          post url, params: invalid_params
        }.not_to change { User.where.not(reset_password_token: nil).count }
      end

      it 'no enqueue ningún email' do
        expect {
          post url, params: invalid_params
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context 'cuando falta el email' do
      let(:invalid_params) { {} }

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de validación' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/email.*requerido/i))
      end
    end

    context 'cuando el email está vacío' do
      let(:invalid_params) { { email: '' } }

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de validación' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/email.*requerido/i))
      end
    end
  end

  describe 'con usuario inactivo' do
    let(:inactive_user) { create(:user, :confirmed, :inactive) }
    let(:params) { { email: inactive_user.email } }

    it 'retorna status 200 (por seguridad)' do
      post url, params: params
      expect(response).to have_http_status(:ok)
    end

    it 'no genera token' do
      expect {
        post url, params: params
      }.not_to change { inactive_user.reload.reset_password_token }
    end

    it 'no enqueue email' do
      expect {
        post url, params: params
      }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end

  describe 'case insensitivity' do
    let(:params) { { email: user.email.upcase } }

    it 'retorna status 200' do
      post url, params: params
      expect(response).to have_http_status(:ok)
    end

    it 'genera el token correctamente' do
      expect {
        post url, params: params
      }.to change { user.reload.reset_password_token }.from(nil)
    end
  end

  describe 'múltiples solicitudes' do
    it 'regenera el token en cada solicitud' do
      post url, params: { email: user.email }
      first_token = user.reload.reset_password_token

      post url, params: { email: user.email }
      second_token = user.reload.reset_password_token

      expect(second_token).not_to eq(first_token)
    end

    it 'actualiza reset_password_sent_at' do
      post url, params: { email: user.email }
      first_sent_at = user.reload.reset_password_sent_at

      travel 1.hour do
        post url, params: { email: user.email }
        second_sent_at = user.reload.reset_password_sent_at

        expect(second_sent_at).to be > first_sent_at
      end
    end
  end

  describe 'estructura de respuesta' do
    before { post url, params: { email: user.email } }

    it 'tiene la estructura correcta de status' do
      json = JSON.parse(response.body)

      expect(json).to have_key('status')
      expect(json['status']).to have_key('code')
      expect(json['status']).to have_key('message')
    end

    it 'no expone información sensible' do
      json = JSON.parse(response.body)

      expect(json).not_to have_key('data')
      expect(json).not_to have_key('user')
      expect(json).not_to have_key('token')
      expect(json).not_to have_key('reset_password_token')
    end
  end
end
