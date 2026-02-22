# spec/requests/api/v1/sessions/logout_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DELETE /api/v1/sessions', type: :request do
  let(:url) { '/api/v1/sessions' }
  let(:user) { create(:user, :confirmed) }
  let(:token) { JsonWebTokenService.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'con token válido' do
    it 'retorna status 200' do
      delete url, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'retorna mensaje de éxito' do
      delete url, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('cerrada exitosamente')
    end

    it 'invalida el token' do
      delete url, headers: headers

      # Intentar usar el token de nuevo
      get '/api/v1/profile', headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'agrega el token a la blacklist' do
      delete url, headers: headers
      expect(REDIS.exists?("blacklist:#{token}")).to be true
    end
  end

  describe 'con token inválido' do
    let(:headers) { { 'Authorization' => 'Bearer invalid_token' } }

    it 'retorna status 401' do  # ← Cambia de 422 a 401
      delete url, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'retorna error' do
      delete url, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(401)  # ← Cambia de 422 a 401
      expect(json['errors']).to be_present
    end
  end

  describe 'sin token' do
    it 'retorna status 401' do  # ← Cambia de 422 a 401
      delete url
      expect(response).to have_http_status(:unauthorized)
    end

    it 'retorna error' do  # ← Cambia mensaje
      delete url
      json = JSON.parse(response.body)
      expect(json['errors']).to include(a_string_matching(/no presente|authorization/i))
    end
  end

  describe 'con token ya usado' do
    before do
      delete url, headers: headers
    end

    it 'retorna status 401 en segundo intento' do
      delete url, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'estructura de respuesta' do
    context 'cuando es exitoso' do
      before { delete url, headers: headers }

      it 'tiene la estructura correcta de status' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json['status']).to have_key('code')
        expect(json['status']).to have_key('message')
      end

      it 'no tiene errores' do
        json = JSON.parse(response.body)
        expect(json).not_to have_key('errors')
      end
    end

    context 'cuando falla' do
      before { delete url }

      it 'tiene la estructura correcta de status' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json['status']).to have_key('code')
        expect(json['status']).to have_key('message')
      end

      it 'tiene errores' do
        json = JSON.parse(response.body)

        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
      end
    end
  end
end
