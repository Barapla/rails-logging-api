# spec/requests/api/v1/password/reset_password_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/passwords/reset', type: :request do
  let(:url) { '/api/v1/passwords/reset' }
  let(:user) { create(:user, :confirmed) }

  before do
    user.generate_password_token!
  end

  describe 'con token y password válidos' do
    let(:valid_params) do
      {
        token: user.reset_password_token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    end

    it 'retorna status 200' do
      post url, params: valid_params
      expect(response).to have_http_status(:ok)
    end

    it 'retorna mensaje de éxito' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(200)
      expect(json['status']['message']).to include('restablecida')
    end

    it 'cambia el password del usuario' do
      old_password_digest = user.password_digest
      post url, params: valid_params

      expect(user.reload.password_digest).not_to eq(old_password_digest)
    end

    it 'elimina el reset_password_token' do
      post url, params: valid_params
      expect(user.reload.reset_password_token).to be_nil
    end

    it 'permite login con el nuevo password' do
      post url, params: valid_params

      expect(user.reload.authenticate('newpassword123')).to eq(user)
    end

    it 'no permite login con el password anterior' do
      old_password = 'password123'
      user.update!(password: old_password)
      user.generate_password_token!

      post url, params: {
        token: user.reset_password_token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }

      expect(user.reload.authenticate(old_password)).to be false
    end

    it 'retorna token JWT para auto-login' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['token']).to be_present
      expect(json['token']).to be_a(String)
    end

    it 'el token JWT es válido' do
      post url, params: valid_params
      json = JSON.parse(response.body)
      token = json['token']

      decoded = JsonWebTokenService.decode(token)
      expect(decoded[:user_id]).to eq(user.id)
    end

    it 'retorna los datos del usuario' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['data']).to include(
        'email' => user.email,
        'first_name' => user.first_name
      )
    end
  end

  describe 'con token inválido' do
    context 'cuando el token no existe' do
      let(:invalid_params) do
        {
          token: 'token_inexistente',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de token inválido' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/token.*inválido|expirado/i))
      end

      it 'no cambia ningún password' do
        expect {
          post url, params: invalid_params
        }.not_to change { user.reload.password_digest }
      end

      it 'no retorna token JWT' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json).not_to have_key('token')
      end
    end

    context 'cuando el token está vacío' do
      let(:invalid_params) do
        {
          token: '',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de token requerido' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/token.*presente|requerido/i))
      end
    end

    context 'cuando el token ha expirado' do
      before do
        user.update!(reset_password_sent_at: 5.hours.ago)
      end

      let(:expired_params) do
        {
          token: user.reset_password_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
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

      it 'no cambia el password' do
        expect {
          post url, params: expired_params
        }.not_to change { user.reload.password_digest }
      end
    end
  end

  describe 'con password inválido' do
    context 'cuando el password es muy corto' do
      let(:invalid_params) do
        {
          token: user.reset_password_token,
          password: '123',
          password_confirmation: '123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de longitud' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/password.*6/i))
      end

      it 'no cambia el password' do
        expect {
          post url, params: invalid_params
        }.not_to change { user.reload.password_digest }
      end
    end

    context 'cuando password y confirmation no coinciden' do
      let(:invalid_params) do
        {
          token: user.reset_password_token,
          password: 'newpassword123',
          password_confirmation: 'different123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de confirmación' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/confirmation/i))
      end
    end

    context 'cuando falta el password' do
      let(:invalid_params) do
        {
          token: user.reset_password_token,
          password_confirmation: 'newpassword123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'cuando falta password_confirmation' do
      let(:invalid_params) do
        {
          token: user.reset_password_token,
          password: 'newpassword123'
        }
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'estructura de respuesta' do
    context 'cuando es exitoso' do
      let(:valid_params) do
        {
          token: user.reset_password_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      before { post url, params: valid_params }

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
      end

      it 'no expone el password_digest' do
        json = JSON.parse(response.body)

        expect(json['data']).not_to have_key('password_digest')
      end
    end

    context 'cuando falla' do
      let(:invalid_params) do
        {
          token: 'invalid',
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      before { post url, params: invalid_params }

      it 'tiene la estructura correcta de status' do
        json = JSON.parse(response.body)

        expect(json).to have_key('status')
        expect(json['status']).to have_key('code')
      end

      it 'tiene errors' do
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
end
