# spec/services/passwords/reset_password_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Passwords::ResetPasswordService, type: :service do
  subject(:service) { described_class.new(token, password, password_confirmation) }

  let(:user) { create(:user, :confirmed) }

  before do
    user.generate_password_token!
  end

  describe '#call' do
    context 'con parámetros válidos' do
      let(:token) { user.reset_password_token }
      let(:password) { 'newpassword123' }
      let(:password_confirmation) { 'newpassword123' }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'cambia el password del usuario' do
        old_password_digest = user.password_digest
        service.call
        expect(user.reload.password_digest).not_to eq(old_password_digest)
      end

      it 'elimina el reset_password_token' do
        service.call
        expect(user.reload.reset_password_token).to be_nil
      end

      it 'permite autenticarse con el nuevo password' do
        service.call
        expect(user.reload.authenticate('newpassword123')).to eq(user)
      end

      it 'no permite autenticarse con el password anterior' do
        old_password = 'oldpassword123'
        user.update!(password: old_password, password_confirmation: old_password)
        user.generate_password_token!

        new_service = described_class.new(user.reset_password_token, 'newpassword123', 'newpassword123')
        new_service.call

        expect(user.reload.authenticate(old_password)).to be false
      end

      it 'retorna el usuario en result' do
        service.call
        expect(service.result[:user]).to eq(user)
      end

      it 'retorna un token JWT en result' do
        service.call
        expect(service.result[:token]).to be_present
        expect(service.result[:token]).to be_a(String)
      end

      it 'el token JWT contiene el user_id correcto' do
        service.call
        decoded = JsonWebTokenService.decode(service.result[:token])
        expect(decoded[:user_id]).to eq(user.id)
      end

      it 'no retorna errores' do
        service.call
        expect(service.errors).to be_empty
      end
    end

    context 'con token inválido' do
      context 'cuando el token es nil' do
        let(:token) { nil }
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { 'newpassword123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token no presente' do
          service.call
          expect(service.errors).to include(a_string_matching(/token.*presente/i))
        end

        it 'no cambia ningún password' do
          expect {
            service.call
          }.not_to change { user.reload.password_digest }
        end

        it 'result es nil' do
          service.call
          expect(service.result).to be_nil
        end
      end

      context 'cuando el token está vacío' do
        let(:token) { '' }
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { 'newpassword123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token no presente' do
          service.call
          expect(service.errors).to include(a_string_matching(/token.*presente/i))
        end
      end

      context 'cuando el token no existe en la base de datos' do
        let(:token) { 'token_inexistente' }
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { 'newpassword123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token inválido' do
          service.call
          expect(service.errors).to include(a_string_matching(/token.*inválido|expirado/i))
        end
      end

      context 'cuando el token ha expirado' do
        let(:token) { user.reset_password_token }
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { 'newpassword123' }

        before do
          user.update!(reset_password_sent_at: 5.hours.ago)
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token expirado' do
          service.call
          expect(service.errors).to include(a_string_matching(/expirado/i))
        end

        it 'no cambia el password' do
          expect {
            service.call
          }.not_to change { user.reload.password_digest }
        end
      end
    end

    context 'con password inválido' do
      let(:token) { user.reset_password_token }

      context 'cuando el password es muy corto' do
        let(:password) { '123' }
        let(:password_confirmation) { '123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de longitud' do
          service.call
          expect(service.errors).to include(a_string_matching(/password.*6/i))
        end

        it 'no cambia el password' do
          expect {
            service.call
          }.not_to change { user.reload.password_digest }
        end
      end

      context 'cuando password y confirmation no coinciden' do
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { 'different123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de confirmación' do
          service.call
          expect(service.errors).to include(a_string_matching(/confirmation/i))
        end
      end

      context 'cuando el password es nil' do
        let(:password) { nil }
        let(:password_confirmation) { 'newpassword123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de password requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/password/i))
        end
      end

      context 'cuando el password_confirmation es nil' do
        let(:password) { 'newpassword123' }
        let(:password_confirmation) { nil }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end
      end
    end

    context 'validación del token en el límite de expiración' do
      let(:token) { user.reset_password_token }
      let(:password) { 'newpassword123' }
      let(:password_confirmation) { 'newpassword123' }

      context 'cuando el token expira exactamente en 4 horas' do
        before do
          user.update!(reset_password_sent_at: 4.hours.ago)
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end
      end

      context 'cuando el token es válido justo antes de expirar' do
        before do
          user.update!(reset_password_sent_at: (4.hours - 1.minute).ago)
        end

        it 'retorna success true' do
          service.call
          expect(service.success?).to be true
        end

        it 'cambia el password' do
          expect {
            service.call
          }.to change { user.reload.password_digest }
        end
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:token) { 'test' }
    let(:password) { 'password123' }
    let(:password_confirmation) { 'password123' }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
