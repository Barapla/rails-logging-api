# spec/services/confirmations/confirm_user_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Confirmations::ConfirmUserService, type: :service do
  subject(:service) { described_class.new(token) }

  describe '#call' do
    context 'con token válido' do
      let(:user) { create(:user, :with_confirmation_token) }
      let(:token) { user.confirmation_token }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'confirma al usuario' do
        expect {
          service.call
        }.to change { user.reload.confirmed_at }.from(nil)
      end

      it 'establece confirmed_at con timestamp actual' do
        travel_to Time.current do
          service.call
          expect(user.reload.confirmed_at).to be_within(1.second).of(Time.current)
        end
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

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token no presente' do
          service.call
          expect(service.errors).to include('Token no está presente')
        end

        it 'no confirma ningún usuario' do
          expect {
            service.call
          }.not_to change { User.where.not(confirmed_at: nil).count }
        end

        it 'result es nil' do
          service.call
          expect(service.result).to be_nil
        end
      end

      context 'cuando el token es string vacío' do
        let(:token) { '' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token no presente' do
          service.call
          expect(service.errors).to include('Token no está presente')
        end
      end

      context 'cuando el token es solo espacios' do
        let(:token) { '   ' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token no presente' do
          service.call
          expect(service.errors).to include('Token no está presente')
        end
      end

      context 'cuando el token no existe en la base de datos' do
        let(:token) { 'token_inexistente_12345' }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token inválido' do
          service.call
          expect(service.errors).to include('Token inválido o expirado')
        end

        it 'no confirma ningún usuario' do
          expect {
            service.call
          }.not_to change { User.where.not(confirmed_at: nil).count }
        end
      end

      context 'cuando el token ha expirado' do
        let(:user) do
          create(:user,
            confirmation_token: 'expired_token',
            confirmation_sent_at: 5.hours.ago
          )
        end
        let(:token) { user.confirmation_token }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'agrega error de token expirado' do
          service.call
          expect(service.errors).to include(a_string_matching(/expirado/i))
        end

        it 'no confirma al usuario' do
          expect {
            service.call
          }.not_to change { user.reload.confirmed_at }
        end
      end

      context 'cuando el token expira justo en el límite (4 horas)' do
        let(:user) do
          create(:user,
            confirmation_token: 'token_at_limit',
            confirmation_sent_at: 4.hours.ago
          )
        end
        let(:token) { user.confirmation_token }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end
      end

      context 'cuando el token es válido justo antes del límite' do
        let(:user) do
          create(:user,
            confirmation_token: 'token_valid',
            confirmation_sent_at: (4.hours - 1.minute).ago
          )
        end
        let(:token) { user.confirmation_token }

        it 'retorna success true' do
          service.call
          expect(service.success?).to be true
        end

        it 'confirma al usuario' do
          expect {
            service.call
          }.to change { user.reload.confirmed_at }.from(nil)
        end
      end
    end

    context 'cuando el usuario ya está confirmado' do
      let(:user) do
        create(:user, :confirmed,
          confirmation_token: 'already_confirmed_token',
          confirmation_sent_at: 1.hour.ago
        )
      end
      let(:token) { user.confirmation_token }

      it 'retorna success true (idempotente)' do
        service.call
        expect(service.success?).to be true
      end

      it 'mantiene el confirmed_at original' do
        original_confirmed_at = user.confirmed_at
        service.call
        expect(user.reload.confirmed_at).to be_within(1.second).of(original_confirmed_at)
      end

      it 'retorna el usuario en result' do
        service.call
        expect(service.result[:user]).to eq(user)
      end

      it 'retorna un token JWT válido' do
        service.call
        expect(service.result[:token]).to be_present
      end
    end

    context 'cuando falla la confirmación del usuario' do
      let(:user) { create(:user, :with_confirmation_token) }
      let(:token) { user.confirmation_token }

      before do
        allow_any_instance_of(User).to receive(:confirm!).and_return(false)
      end

      it 'retorna success false' do
        service.call
        expect(service.success?).to be false
      end

      it 'agrega error de confirmación fallida' do
        service.call
        expect(service.errors).to include('No se pudo confirmar la cuenta')
      end

      it 'no genera token JWT' do
        service.call
        expect(service.result).to be_nil
      end
    end

    context 'manejo de errores de base de datos' do
      let(:token) { 'test_token' }

      before do
        allow(User).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it 'propaga la excepción' do
        expect {
          service.call
        }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:token) { 'test' }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a #success?' do
      expect(service).to respond_to(:success?)
    end

    it 'responde a #failure?' do
      expect(service).to respond_to(:failure?)
    end

    it 'responde a #errors' do
      expect(service).to respond_to(:errors)
    end

    it 'responde a #result' do
      expect(service).to respond_to(:result)
    end

    it 'responde a #call' do
      expect(service).to respond_to(:call)
    end
  end
end
