# spec/requests/api/v1/profiles/show_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/v1/profile', type: :request do
  let(:url) { '/api/v1/profile' }
  let(:user) { create(:user, :confirmed) }
  let(:token) { JsonWebTokenService.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'con autenticación válida' do
    it 'retorna status 200' do
      get url, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'retorna los datos del usuario' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['data']).to include(
        'email' => user.email,
        'first_name' => user.first_name,
        'last_name' => user.last_name
      )
    end

    it 'no retorna el password_digest' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['data']).not_to have_key('password_digest')
    end

    it 'retorna mensaje de éxito' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('obtenido exitosamente')
    end
  end

  describe 'sin autenticación' do
    it 'retorna status 401' do
      get url
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'con token inválido' do
    let(:headers) { { 'Authorization' => 'Bearer invalid_token' } }

    it 'retorna status 401' do
      get url, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'estructura de respuesta' do
    before { get url, headers: headers }

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
  end
end
