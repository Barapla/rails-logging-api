# spec/requests/api/v1/confirmations/confirm_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/confirmations/confirm', type: :request do
  let(:url) { '/api/v1/confirmations/confirm' }
  let(:user) { create(:user, :with_confirmation_token) }

  describe 'con token válido' do
    let(:valid_params) { { token: user.confirmation_token } }

    it 'confirma la cuenta del usuario' do
      expect {
        post url, params: valid_params
      }.to change { user.reload.confirmed_at }.from(nil)
    end

    it 'retorna status 200' do
      post url, params: valid_params
      expect(response).to have_http_status(:ok)
    end

    it 'retorna los datos del usuario' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['data']).to include(
        'email' => user.email,
        'first_name' => user.first_name,
        'last_name' => user.last_name
      )
    end

    it 'retorna un token JWT' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['token']).to be_present
      expect(json['token']).to be_a(String)
    end

    it 'retorna mensaje de éxito' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('confirmada exitosamente')
    end

    it 'no retorna el password_digest' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['data']).not_to have_key('password_digest')
    end

    it 'el token JWT es válido' do
      post url, params: valid_params
      json = JSON.parse(response.body)
      token = json['token']

      decoded = JsonWebTokenService.decode(token)
      expect(decoded[:user_id]).to eq(user.id)
    end
  end

  describe 'con token inválido' do
    context 'cuando el token no existe' do
      let(:invalid_params) { { token: 'token_inexistente' } }

      it 'no confirma ninguna cuenta' do
        expect {
          post url, params: invalid_params
        }.not_to change { User.where.not(confirmed_at: nil).count }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna mensaje de error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['status']['code']).to eq(422)
        expect(json['errors']).to include(a_string_matching(/inválido|expirado/i))
      end

      it 'no retorna token JWT' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json).not_to have_key('token')
      end
    end

    context 'cuando el token está vacío' do
      let(:invalid_params) { { token: '' } }

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de token no presente' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/token.*presente/i))
      end
    end

    context 'cuando no se envía el parámetro token' do
      it 'retorna status 422' do
        post url, params: {}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de token no presente' do
        post url, params: {}
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/token.*presente/i))
      end
    end

    context 'cuando el token ha expirado' do
      let(:expired_user) do
        create(:user,
          confirmation_token: 'expired_token',
          confirmation_sent_at: 5.hours.ago
        )
      end
      let(:expired_params) { { token: expired_user.confirmation_token } }

      it 'no confirma la cuenta' do
        expect {
          post url, params: expired_params
        }.not_to change { expired_user.reload.confirmed_at }
      end

      it 'retorna status 422' do
        post url, params: expired_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de token expirado' do
        post url, params: expired_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/expirado/i))
      end
    end
  end

  describe 'estructura de respuesta' do
    context 'cuando es exitoso' do
      before { post url, params: { token: user.confirmation_token } }

      it 'tiene la estructura correcta de status' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json['status']).to have_key('code')
        expect(json['status']).to have_key('message')
      end

      it 'tiene la estructura correcta de data' do
        json = JSON.parse(response.body)

        expect(json).to have_key('data')
        expect(json['data']).to be_a(Hash)
      end

      it 'tiene el token JWT' do
        json = JSON.parse(response.body)

        expect(json).to have_key('token')
        expect(json['token']).to be_a(String)
      end
    end

    context 'cuando falla' do
      before { post url, params: { token: 'invalid' } }

      it 'tiene la estructura correcta de status' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json['status']).to have_key('code')
        expect(json['status']).to have_key('message')
      end

      it 'tiene la estructura correcta de errors' do
        json = JSON.parse(response.body)

        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
      end

      it 'no tiene token JWT' do
        json = JSON.parse(response.body)

        expect(json).not_to have_key('token')
      end
    end
  end

  describe 'idempotencia' do
    it 'permite confirmar una cuenta ya confirmada' do
      user.update!(confirmed_at: Time.current)

      post url, params: { token: user.confirmation_token }

      expect(response).to have_http_status(:ok)
    end
  end
end
