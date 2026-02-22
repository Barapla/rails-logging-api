# spec/services/authentication/authenticate_user_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authentication::AuthenticateUserService, type: :service do
  subject(:service) { described_class.new(email, password) }

  let(:user) { create(:user, :confirmed, password: 'password123') }

  describe '#call' do
    context 'con credenciales válidas' do
      let(:email) { user.email }
      let(:password) { 'password123' }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
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

      it 'el token JWT tiene expiración futura' do
        service.call
        decoded = JsonWebTokenService.decode(service.result[:token])
        expect(decoded[:exp]).to be > Time.current.to_i
      end

      it 'retorna el usuario en result' do
        service.call
        expect(service.result[:user]).to eq(user)
      end

      it 'no retorna errores' do
        service.call
        expect(service.errors).to be_empty
      end
    end

    context 'con credenciales inválidas' do
      context 'cuando el email no existe' do
        let(:email) { 'noexiste@example.com' }
        let(:password) { 'password123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de credenciales inválidas' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*password.*incorrectos|credenciales.*inválidas/i))
        end

        it 'no retorna token JWT' do
          service.call
          expect(service.result).to be_nil
        end
      end

      context 'cuando el password es incorrecto' do
        let(:email) { user.email }
        let(:password) { 'wrong_password' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de credenciales inválidas' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*password.*incorrectos|credenciales.*inválidas/i))
        end

        it 'no retorna token JWT' do
          service.call
          expect(service.result).to be_nil
        end
      end

      context 'cuando el email es nil' do
        let(:email) { nil }
        let(:password) { 'password123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido|necesario/i))
        end
      end

      context 'cuando el password es nil' do
        let(:email) { user.email }
        let(:password) { nil }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de password requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/password.*requerido|necesario/i))
        end
      end

      context 'cuando ambos son nil' do
        let(:email) { nil }
        let(:password) { nil }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido/i))
        end
      end

      context 'cuando el email está vacío' do
        let(:email) { '' }
        let(:password) { 'password123' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de email requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*requerido/i))
        end
      end

      context 'cuando el password está vacío' do
        let(:email) { user.email }
        let(:password) { '' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de password requerido' do
          service.call
          expect(service.errors).to include(a_string_matching(/password.*requerido/i))
        end
      end
    end

    context 'con usuario no confirmado' do
      let(:unconfirmed_user) { create(:user, password: 'password123') }
      let(:email) { unconfirmed_user.email }
      let(:password) { 'password123' }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'agrega error de cuenta no confirmada' do
        service.call
        expect(service.errors).to include(a_string_matching(/confirmar.*cuenta|cuenta.*confirmada/i))
      end

      it 'no retorna token JWT' do
        service.call
        expect(service.result).to be_nil
      end
    end

    context 'con usuario inactivo' do
      let(:inactive_user) { create(:user, :confirmed, :inactive, password: 'password123') }
      let(:email) { inactive_user.email }
      let(:password) { 'password123' }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'agrega error de cuenta inactiva' do
        service.call
        expect(service.errors).to include(a_string_matching(/inactiva|desactivada/i))
      end

      it 'no retorna token JWT' do
        service.call
        expect(service.result).to be_nil
      end
    end

    context 'case insensitivity del email' do
      let(:email) { user.email.upcase }
      let(:password) { 'password123' }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'encuentra al usuario correctamente' do
        service.call
        decoded = JsonWebTokenService.decode(service.result[:token])
        expect(decoded[:user_id]).to eq(user.id)
      end
    end

    context 'con espacios en el email' do
      let(:email) { "  #{user.email}  " }
      let(:password) { 'password123' }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'encuentra al usuario correctamente' do
        service.call
        decoded = JsonWebTokenService.decode(service.result[:token])
        expect(decoded[:user_id]).to eq(user.id)
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:email) { 'test@example.com' }
    let(:password) { 'password123' }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
