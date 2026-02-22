# spec/requests/api/v1/users/index_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /api/v1/users', type: :request do
  let(:url) { '/api/v1/users' }

  describe 'con usuario admin' do
    let(:admin_role) { Role.find_by(name: 'admin') }
    let(:admin_user) { create(:user, :confirmed, role: admin_role) }
    let(:token) { JsonWebTokenService.encode(user_id: admin_user.id) }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

    let!(:users) { create_list(:user, 3, :confirmed) }

    it 'retorna status 200' do
      get url, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'retorna todos los usuarios' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['data'].size).to eq(User.count)
    end

    it 'incluye los datos de los usuarios' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['data'].first).to have_key('email')
      expect(json['data'].first).to have_key('first_name')
      expect(json['data'].first).to have_key('last_name')
    end

    it 'no retorna password_digest' do
      get url, headers: headers
      json = JSON.parse(response.body)

      json['data'].each do |user_data|
        expect(user_data).not_to have_key('password_digest')
      end
    end

    it 'retorna mensaje de éxito' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('obtenidos exitosamente')
    end
  end

  describe 'con usuario regular' do
    let(:user_role) { Role.find_by(name: 'usuario') }
    let(:regular_user) { create(:user, :confirmed, role: user_role) }
    let(:token) { JsonWebTokenService.encode(user_id: regular_user.id) }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

    it 'retorna status 403' do
      get url, headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it 'retorna mensaje de permiso denegado' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(403)
      expect(json['status']['message']).to include('No tienes permiso')
    end

    it 'retorna error específico de permiso' do
      get url, headers: headers
      json = JSON.parse(response.body)

      expect(json['errors']).to include(a_string_matching(/read.*users/i))
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
    let(:admin_role) { Role.find_by(name: 'admin') }
    let(:admin_user) { create(:user, :confirmed, role: admin_role) }
    let(:token) { JsonWebTokenService.encode(user_id: admin_user.id) }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

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
      expect(json['data']).to be_an(Array)
    end
  end
end
