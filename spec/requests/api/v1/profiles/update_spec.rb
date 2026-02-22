# spec/requests/api/v1/profiles/update_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PATCH /api/v1/profile', type: :request do
  let(:url) { '/api/v1/profile' }
  let(:user) { create(:user, :confirmed, password: 'oldpassword123', password_confirmation: 'oldpassword123') }
  let(:token) { JsonWebTokenService.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'con parámetros válidos' do
    let(:valid_params) do
      {
        profile: {
          first_name: 'Nuevo',
          last_name: 'Nombre'
        }
      }
    end

    it 'retorna status 200' do
      patch url, params: valid_params, headers: headers
      expect(response).to have_http_status(:ok)
    end

    it 'actualiza los datos del usuario' do
      patch url, params: valid_params, headers: headers
      user.reload

      expect(user.first_name).to eq('Nuevo')
      expect(user.last_name).to eq('Nombre')
    end

    it 'retorna los datos actualizados' do
      patch url, params: valid_params, headers: headers
      json = JSON.parse(response.body)

      expect(json['data']['first_name']).to eq('Nuevo')
      expect(json['data']['last_name']).to eq('Nombre')
    end

    it 'retorna mensaje de éxito' do
      patch url, params: valid_params, headers: headers
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('actualizado exitosamente')
    end
  end

  describe 'actualización de email' do
    let(:new_email_params) do
      {
        profile: {
          email: 'nuevo@example.com'
        }
      }
    end

    it 'permite cambiar el email' do
      patch url, params: new_email_params, headers: headers
      expect(user.reload.email).to eq('nuevo@example.com')
    end
  end

  describe 'actualización de password' do
    let(:password_params) do
      {
        profile: {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
    end

    it 'permite cambiar el password' do
      patch url, params: password_params, headers: headers
      user.reload
      expect(user.authenticate('newpassword123')).to eq(user)
    end

    it 'el password antiguo ya no funciona' do
      patch url, params: password_params, headers: headers
      user.reload
      expect(user.authenticate('oldpassword123')).to be false
    end
  end

  describe 'con parámetros inválidos' do
    context 'cuando el email ya existe' do
      let(:existing_user) { create(:user) }
      let(:invalid_params) do
        {
          profile: {
            email: existing_user.email
          }
        }
      end

      it 'retorna status 422' do
        patch url, params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna errores de validación' do
        patch url, params: invalid_params, headers: headers
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/email/i))
      end
    end

    context 'cuando el password es muy corto' do
      let(:invalid_params) do
        {
          profile: {
            password: '123',
            password_confirmation: '123'
          }
        }
      end

      it 'retorna status 422' do
        patch url, params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de longitud' do
        patch url, params: invalid_params, headers: headers
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/password.*short/i))
      end
    end

    context 'cuando password y password_confirmation no coinciden' do
      let(:invalid_params) do
        {
          profile: {
            password: 'newpassword123',
            password_confirmation: 'different123'
          }
        }
      end

      it 'retorna status 422' do
        patch url, params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'sin autenticación' do
    it 'retorna status 401' do
      patch url, params: { profile: { first_name: 'Test' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'estructura de respuesta' do
    let(:params) { { profile: { first_name: 'Test' } } }

    context 'cuando es exitoso' do
      before { patch url, params: params, headers: headers }

      it 'tiene la estructura correcta' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json).to have_key('data')
        expect(json['data']).to be_a(Hash)
      end
    end

    context 'cuando falla' do
      let(:params) { { profile: { email: '' } } }

      before { patch url, params: params, headers: headers }

      it 'tiene la estructura correcta' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json).to have_key('errors')
        expect(json['errors']).to be_an(Array)
      end
    end
  end
end
