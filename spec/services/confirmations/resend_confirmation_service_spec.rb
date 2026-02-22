# spec/services/confirmations/resend_confirmation_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Confirmations::ResendConfirmationService, type: :service do
  subject(:service) { described_class.new(email) }

  let(:user) { create(:user) }

  describe '#call' do
    context 'con email válido de usuario no confirmado' do
      let(:email) { user.email }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'regenera el confirmation_token' do
        old_token = user.confirmation_token
        service.call
        expect(user.reload.confirmation_token).not_to eq(old_token)
      end

      it 'actualiza confirmation_sent_at' do
        user.generate_confirmation_token!
        old_sent_at = user.confirmation_sent_at
        service.call
        expect(user.reload.confirmation_sent_at).to be > old_sent_at
      end

      it 'el token es único' do
        service.call
        first_token = user.reload.confirmation_token

        new_service = described_class.new(email)
        new_service.call
        second_token = user.reload.confirmation_token

        expect(second_token).not_to eq(first_token)
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

      it 'result es nil (no expone información)' do
        service.call
        expect(service.result).to be_nil
      end
    end

    context 'con usuario ya confirmado' do
      let(:confirmed_user) { create(:user, :confirmed) }
      let(:email) { confirmed_user.email }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'agrega error de cuenta ya confirmada' do
        service.call
        expect(service.errors).to include(a_string_matching(/ya.*confirmada/i))
      end

      it 'no regenera token' do
        old_token = confirmed_user.confirmation_token
        service.call
        expect(confirmed_user.reload.confirmation_token).to eq(old_token)
      end

      it 'no enqueue email' do
        expect {
          service.call
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context 'con email inválido' do
      context 'cuando el email no existe' do
        let(:email) { 'noexiste@example.com' }

        it 'retorna success true (por seguridad)' do
          service.call
          expect(service.success?).to be true
        end

        it 'no enqueue ningún email' do
          expect {
            service.call
          }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
        end

        it 'no retorna errores (por seguridad)' do
          service.call
          expect(service.errors).to be_empty
        end
      end

      context 'cuando el email es nil' do
        let(:email) { nil }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido/i))
        end

        it 'no enqueue email' do
          expect {
            service.call
          }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
        end
      end

      context 'cuando el email está vacío' do
        let(:email) { '' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido/i))
        end
      end

      context 'cuando el email es solo espacios' do
        let(:email) { '   ' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido/i))
        end
      end
    end

    context 'con usuario inactivo' do
      let(:inactive_user) { create(:user, :inactive) }
      let(:email) { inactive_user.email }

      it 'retorna success true (por seguridad)' do
        service.call
        expect(service.success?).to be true
      end

      it 'no genera token' do
        expect {
          service.call
        }.not_to change { inactive_user.reload.confirmation_token }
      end

      it 'no enqueue email' do
        expect {
          service.call
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context 'case insensitivity del email' do
      let(:email) { user.email.upcase }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'encuentra al usuario correctamente' do
        old_token = user.confirmation_token
        service.call
        expect(user.reload.confirmation_token).not_to eq(old_token)
      end
    end

    context 'con espacios en el email' do
      let(:email) { "  #{user.email}  " }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'encuentra al usuario correctamente' do
        old_token = user.confirmation_token
        service.call
        expect(user.reload.confirmation_token).not_to eq(old_token)
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:email) { 'test@example.com' }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
