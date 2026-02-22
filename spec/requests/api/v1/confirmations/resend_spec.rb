# spec/requests/api/v1/confirmations/resend_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/confirmations/resend', type: :request do
  let(:url) { '/api/v1/confirmations/resend' }
  let(:user) { create(:user) }

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

    it 'regenera el confirmation_token' do
      old_token = user.confirmation_token
      post url, params: valid_params

      expect(user.reload.confirmation_token).not_to eq(old_token)
    end

    it 'actualiza confirmation_sent_at' do
      user.generate_confirmation_token!
      old_sent_at = user.confirmation_sent_at

      travel 1.hour do
        post url, params: valid_params
        expect(user.reload.confirmation_sent_at).to be > old_sent_at
      end
    end

    it 'enqueue un email de confirmación' do
      expect {
        post url, params: valid_params
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
    end

    it 'no retorna información sensible del usuario' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json).not_to have_key('data')
      expect(json).not_to have_key('token')
      expect(json).not_to have_key('confirmation_token')
    end
  end

  describe 'con usuario ya confirmado' do
    let(:confirmed_user) { create(:user, :confirmed) }
    let(:params) { { email: confirmed_user.email } }

    it 'retorna status 422' do
      post url, params: params
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'retorna error indicando que ya está confirmado' do
      post url, params: params
      json = JSON.parse(response.body)

      expect(json['errors']).to include(a_string_matching(/ya.*confirmada/i))
    end

    it 'no enqueue email' do
      expect {
        post url, params: params
      }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end

    it 'no regenera token' do
      old_token = confirmed_user.confirmation_token
      post url, params: params

      expect(confirmed_user.reload.confirmation_token).to eq(old_token)
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

      it 'no enqueue ningún email' do
        expect {
          post url, params: invalid_params
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end

      it 'no genera ningún token' do
        expect {
          post url, params: invalid_params
        }.not_to change { User.where.not(confirmation_token: nil).count }
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
    let(:inactive_user) { create(:user, :inactive) }
    let(:params) { { email: inactive_user.email } }

    it 'retorna status 200 (por seguridad)' do
      post url, params: params
      expect(response).to have_http_status(:ok)
    end

    it 'no genera token' do
      expect {
        post url, params: params
      }.not_to change { inactive_user.reload.confirmation_token }
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
      old_token = user.confirmation_token
      post url, params: params

      expect(user.reload.confirmation_token).not_to eq(old_token)
    end
  end

  describe 'rate limiting de emails' do
    let(:params) { { email: user.email } }

    context 'cuando se reenvía muy rápido' do
      it 'permite el primer reenvío' do
        post url, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'permite reenvíos después de tiempo razonable' do
        user.update!(confirmation_sent_at: 10.minutes.ago)

        post url, params: params
        expect(response).to have_http_status(:ok)
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
      expect(json).not_to have_key('confirmation_token')
    end
  end
end
