# spec/requests/api/v1/sessions/login_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/sessions', type: :request do
  let(:url) { '/api/v1/sessions' }
  let(:user) { create(:user, :confirmed, password: 'password123') }

  describe 'con credenciales válidas' do
    let(:valid_params) do
      {
        email: user.email,
        password: 'password123'
      }
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
      expect(json['status']['message']).to include('iniciada exitosamente')
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

    it 'el token JWT expira en el futuro' do
      post url, params: valid_params
      json = JSON.parse(response.body)
      token = json['token']

      decoded = JsonWebTokenService.decode(token)
      expect(decoded[:exp]).to be > Time.current.to_i
    end
  end

  describe 'con credenciales inválidas' do
    context 'cuando el email no existe' do
      let(:invalid_params) do
        {
          email: 'noexiste@example.com',
          password: 'password123'
        }
      end

      it 'retorna status 401' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'retorna mensaje de error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['status']['code']).to eq(401)
        expect(json['status']['message']).to include('fallida')
      end

      it 'retorna errores' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
        expect(json['errors']).to be_an(Array)
      end

      it 'no retorna token JWT' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json).not_to have_key('token')
      end

      it 'no retorna datos de usuario' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json).not_to have_key('data')
      end
    end

    context 'cuando el password es incorrecto' do
      let(:invalid_params) do
        {
          email: user.email,
          password: 'wrong_password'
        }
      end

      it 'retorna status 401' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'retorna mensaje de error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['status']['code']).to eq(401)
        expect(json['errors']).to be_present
      end

      it 'no retorna token JWT' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json).not_to have_key('token')
      end
    end

    context 'cuando falta el email' do
      let(:invalid_params) do
        {
          password: 'password123'
        }
      end

      it 'retorna status 401' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'retorna error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
      end
    end

    context 'cuando falta el password' do
      let(:invalid_params) do
        {
          email: user.email
        }
      end

      it 'retorna status 401' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'retorna error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
      end
    end

    context 'cuando ambos parámetros están vacíos' do
      let(:invalid_params) do
        {
          email: '',
          password: ''
        }
      end

      it 'retorna status 401' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'retorna error' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
      end
    end
  end

  describe 'con usuario no confirmado' do
    let(:unconfirmed_user) { create(:user, password: 'password123') }
    let(:params) do
      {
        email: unconfirmed_user.email,
        password: 'password123'
      }
    end

    it 'retorna status 401' do
      post url, params: params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'retorna error indicando falta de confirmación' do
      post url, params: params
      json = JSON.parse(response.body)

      expect(json['errors']).to include(a_string_matching(/confirmar|confirmación/i))
    end

    it 'no retorna token JWT' do
      post url, params: params
      json = JSON.parse(response.body)

      expect(json).not_to have_key('token')
    end
  end

  describe 'con usuario inactivo' do
    let(:inactive_user) { create(:user, :confirmed, :inactive, password: 'password123') }
    let(:params) do
      {
        email: inactive_user.email,
        password: 'password123'
      }
    end

    it 'retorna status 401' do
      post url, params: params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'retorna error indicando cuenta inactiva' do
      post url, params: params
      json = JSON.parse(response.body)

      expect(json['errors']).to include(a_string_matching(/inactiva|desactivada/i))
    end

    it 'no retorna token JWT' do
      post url, params: params
      json = JSON.parse(response.body)

      expect(json).not_to have_key('token')
    end
  end

  describe 'estructura de respuesta' do
    context 'cuando es exitoso' do
      before { post url, params: { email: user.email, password: 'password123' } }

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
      before { post url, params: { email: user.email, password: 'wrong' } }

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

      it 'no tiene data' do
        json = JSON.parse(response.body)

        expect(json).not_to have_key('data')
      end
    end
  end

  describe 'case sensitivity' do
    context 'cuando el email tiene mayúsculas' do
      let(:params) do
        {
          email: user.email.upcase,
          password: 'password123'
        }
      end

      it 'retorna status 200' do
        post url, params: params
        expect(response).to have_http_status(:ok)
      end

      it 'retorna token JWT' do
        post url, params: params
        json = JSON.parse(response.body)

        expect(json['token']).to be_present
      end
    end
  end
end
