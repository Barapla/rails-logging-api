# spec/services/authentication/logout_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authentication::LogoutService, type: :service do
  subject(:service) { described_class.new(token) }

  let(:user) { create(:user, :confirmed) }
  let(:valid_token) { JsonWebTokenService.encode(user_id: user.id) }

  describe '#call' do
    context 'con token válido' do
      let(:token) { valid_token }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'agrega el token a la blacklist' do
        service.call
        expect(REDIS.exists?("blacklist:#{token}")).to be true
      end

      it 'el token no puede ser usado después' do
        service.call
        decoded = JsonWebTokenService.decode(token)
        expect(decoded).to be_nil
      end

      it 'no retorna errores' do
        service.call
        expect(service.errors).to be_empty
      end
    end

    context 'con token inválido' do
      let(:token) { 'invalid_token' }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'retorna error de token inválido' do
        service.call
        expect(service.errors).to include(a_string_matching(/inválido/i))
      end

      it 'no agrega nada a la blacklist' do
        service.call
        expect(REDIS.exists?("blacklist:#{token}")).to be false
      end
    end

    context 'con token vacío' do
      let(:token) { '' }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'retorna error de token no proporcionado' do
        service.call
        expect(service.errors).to include(a_string_matching(/no proporcionado/i))
      end
    end

    context 'con token nil' do
      let(:token) { nil }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'retorna error de token no proporcionado' do
        service.call
        expect(service.errors).to include(a_string_matching(/no proporcionado/i))
      end
    end

    context 'con token expirado' do
      let(:token) { JsonWebTokenService.encode({ user_id: user.id }, 1.hour.ago) }

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'retorna error de token inválido' do  # ← Cambia "expirado" a "inválido"
        service.call
        expect(service.errors).to include(a_string_matching(/inválido/i))
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:token) { valid_token }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
