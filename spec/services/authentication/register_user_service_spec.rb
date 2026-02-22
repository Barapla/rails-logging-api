# spec/services/authentication/register_user_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authentication::RegisterUserService, type: :service do
  subject(:service) { described_class.new(user_params) }

  let(:valid_params) do
    {
      email: 'newuser@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'John',
      last_name: 'Doe'
    }
  end

  describe '#call' do
    context 'con parámetros válidos' do
      let(:user_params) { valid_params }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'crea un nuevo usuario' do
        expect {
          service.call
        }.to change(User, :count).by(1)
      end

      it 'retorna el usuario creado en result' do
        service.call
        expect(service.result).to be_a(User)
        expect(service.result.email).to eq('newuser@example.com')
      end

      it 'genera un confirmation_token' do
        service.call
        expect(service.result.confirmation_token).to be_present
      end

      it 'establece confirmation_sent_at' do
        service.call
        expect(service.result.confirmation_sent_at).to be_present
      end

      it 'el usuario no está confirmado inicialmente' do
        service.call
        expect(service.result.confirmed_at).to be_nil
      end

      it 'enqueue un email de confirmación' do
        expect {
          service.call
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(:once)
      end

      it 'no retorna errores' do
        service.call
        expect(service.errors).to be_empty
      end

      it 'el usuario está activo por default' do
        service.call
        expect(service.result.active).to be true
      end
    end

    context 'con parámetros inválidos' do
      context 'cuando falta el email' do
        let(:user_params) do
          valid_params.merge(email: nil)
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'no crea el usuario' do
          expect {
            service.call
          }.not_to change(User, :count)
        end

        it 'agrega error de validación' do
          service.call
          expect(service.errors).to include(a_string_matching(/email/i))
        end

        it 'result es nil' do
          service.call
          expect(service.result).to be_nil
        end

        it 'no enqueue email' do
          expect {
            service.call
          }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
        end
      end

      context 'cuando el email ya existe' do
        before do
          create(:user, email: 'duplicate@example.com')
        end

        let(:user_params) do
          valid_params.merge(email: 'duplicate@example.com')
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'no crea el usuario' do
          expect {
            service.call
          }.not_to change(User, :count)
        end

        it 'agrega error de email duplicado' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*taken|ya.*tomado/i))
        end
      end

      context 'cuando el password es muy corto' do
        let(:user_params) do
          valid_params.merge(password: '123', password_confirmation: '123')
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de longitud de password' do
          service.call
          expect(service.errors).to include(a_string_matching(/password.*6/i))
        end
      end

      context 'cuando password y password_confirmation no coinciden' do
        let(:user_params) do
          valid_params.merge(password_confirmation: 'different123')
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de confirmación' do
          service.call
          expect(service.errors).to include(a_string_matching(/confirmation/i))
        end
      end

      context 'cuando el email tiene formato inválido' do
        let(:user_params) do
          valid_params.merge(email: 'invalid-email')
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de formato de email' do
          service.call
          expect(service.errors).to include(a_string_matching(/email/i))
        end
      end

      context 'con múltiples errores de validación' do
        let(:user_params) do
          {
            email: 'invalid',
            password: '123',
            password_confirmation: '456',
            first_name: nil,
            last_name: nil
          }
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega todos los errores' do
          service.call
          expect(service.errors.count).to be > 1
        end
      end
    end

    context 'cuando falla el envío de email' do
      let(:user_params) { valid_params }

      before do
        mailer_double = double('mailer')
        allow(mailer_double).to receive(:deliver_later).and_raise(StandardError.new('Email service error'))
        allow(UserMailer).to receive(:confirmation_instructions).and_return(mailer_double)
      end

      it 'propaga la excepción' do
        expect {
          service.call
        }.to raise_error(StandardError, 'Email service error')
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:user_params) { valid_params }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
