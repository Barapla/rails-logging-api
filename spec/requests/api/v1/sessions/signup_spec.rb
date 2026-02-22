# spec/requests/api/v1/sessions/signup_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /api/v1/sessions/signup', type: :request do
  let(:url) { '/api/v1/sessions/signup' }
  let(:valid_params) do
    {
      user: {
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe'
      }
    }
  end

  describe 'con parámetros válidos' do
    it 'crea un nuevo usuario' do
      expect {
        post url, params: valid_params
      }.to change(User, :count).by(1)
    end

    it 'retorna status 201' do
      post url, params: valid_params
      expect(response).to have_http_status(:created)
    end

    it 'retorna los datos del usuario' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['data']).to include(
        'email' => 'test@example.com',
        'first_name' => 'John',
        'last_name' => 'Doe'
      )
    end

    it 'no retorna el password_digest' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['data']).not_to have_key('password_digest')
    end

    it 'retorna mensaje de éxito' do
      post url, params: valid_params
      json = JSON.parse(response.body)

      expect(json['status']['code']).to eq(201)
      expect(json['status']['message']).to include('registrado exitosamente')
    end

    it 'genera un confirmation_token' do
      post url, params: valid_params
      user = User.last

      expect(user.confirmation_token).to be_present
      expect(user.confirmation_sent_at).to be_present
    end

    it 'envía email de confirmación' do
      expect {
        post url, params: valid_params
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
    end

    it 'el usuario no está confirmado inicialmente' do
      post url, params: valid_params
      user = User.last

      expect(user.confirmed_at).to be_nil
    end
  end

  describe 'con parámetros inválidos' do
    context 'cuando falta el email' do
      let(:invalid_params) do
        {
          user: {
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'no crea el usuario' do
        expect {
          post url, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna errores de validación' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
        expect(json['status']['code']).to eq(422)
      end
    end

    context 'cuando el email ya existe' do
      before do
        User.create!(
          email: 'test@example.com',
          password: 'password123',
          first_name: 'Existing',
          last_name: 'User'
        )
      end

      it 'no crea el usuario' do
        expect {
          post url, params: valid_params
        }.not_to change(User, :count)
      end

      it 'retorna status 422' do
        post url, params: valid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'retorna error de email duplicado' do
        post url, params: valid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/email/i))
      end
    end

    context 'cuando el password es muy corto' do
      let(:invalid_params) do
        {
          user: {
            email: 'test@example.com',
            password: '123',
            password_confirmation: '123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'no crea el usuario' do
        expect {
          post url, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'retorna error de longitud de password' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/password.*6/i))
      end
    end

    context 'cuando password y password_confirmation no coinciden' do
      let(:invalid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'different123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'no crea el usuario' do
        expect {
          post url, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'retorna status 422' do
        post url, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'cuando el email tiene formato inválido' do
      let(:invalid_params) do
        {
          user: {
            email: 'invalid-email',
            password: 'password123',
            password_confirmation: 'password123',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      it 'no crea el usuario' do
        expect {
          post url, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'retorna error de formato de email' do
        post url, params: invalid_params
        json = JSON.parse(response.body)

        expect(json['errors']).to include(a_string_matching(/email/i))
      end
    end
  end

  describe 'estructura de respuesta' do
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
  end
end
