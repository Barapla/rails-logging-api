# spec/services/passwords/forgot_password_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Passwords::ForgotPasswordService, type: :service do
  subject(:service) { described_class.new(email) }

  let(:user) { create(:user, :confirmed) }

  describe '#call' do
    context 'con email válido' do
      let(:email) { user.email }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'genera un reset_password_token' do
        expect {
          service.call
        }.to change { user.reload.reset_password_token }.from(nil)
      end

      it 'establece reset_password_sent_at' do
        expect {
          service.call
        }.to change { user.reload.reset_password_sent_at }.from(nil)
      end

      it 'el token es único' do
        service.call
        first_token = user.reload.reset_password_token

        service.call
        second_token = user.reload.reset_password_token

        expect(second_token).not_to eq(first_token)
      end

      it 'enqueue un email de reset' do
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

    context 'con email inválido' do
      context 'cuando el email no existe' do
        let(:email) { 'noexiste@example.com' }

        it 'retorna success true (por seguridad)' do
          service.call
          expect(service.success?).to be true
        end

        it 'no genera ningún token' do
          expect {
            service.call
          }.not_to change { User.where.not(reset_password_token: nil).count }
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
      let(:inactive_user) { create(:user, :confirmed, :inactive) }
      let(:email) { inactive_user.email }

      it 'retorna success true (por seguridad)' do
        service.call
        expect(service.success?).to be true
      end

      it 'no genera token' do
        expect {
          service.call
        }.not_to change { inactive_user.reload.reset_password_token }
      end

      it 'no enqueue email' do
        expect {
          service.call
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context 'con usuario no confirmado' do
      let(:unconfirmed_user) { create(:user) }
      let(:email) { unconfirmed_user.email }

      it 'retorna success true (por seguridad)' do
        service.call
        expect(service.success?).to be true
      end

      it 'no genera token' do
        expect {
          service.call
        }.not_to change { unconfirmed_user.reload.reset_password_token }
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
        expect {
          service.call
        }.to change { user.reload.reset_password_token }.from(nil)
      end
    end

    context 'con espacios en el email' do
      let(:email) { "  #{user.email}  " }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'encuentra al usuario correctamente' do
        expect {
          service.call
        }.to change { user.reload.reset_password_token }.from(nil)
      end
    end

    context 'múltiples solicitudes del mismo usuario' do
      let(:email) { user.email }

      it 'regenera el token cada vez' do
        service.call
        first_token = user.reload.reset_password_token

        new_service = described_class.new(email)
        new_service.call
        second_token = user.reload.reset_password_token

        expect(second_token).not_to eq(first_token)
      end

      it 'actualiza reset_password_sent_at' do
        service.call
        first_sent_at = user.reload.reset_password_sent_at

        sleep 1

        new_service = described_class.new(email)
        new_service.call
        second_sent_at = user.reload.reset_password_sent_at

        expect(second_sent_at).to be > first_sent_at
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
