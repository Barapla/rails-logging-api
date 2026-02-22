# spec/services/users/update_profile_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::UpdateProfileService, type: :service do
  subject(:service) { described_class.new(user, attributes) }

  let(:user) { create(:user, :confirmed) }

  describe '#call' do
    context 'con atributos válidos' do
      let(:attributes) do
        {
          first_name: 'Nuevo',
          last_name: 'Nombre'
        }
      end

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'actualiza los atributos del usuario' do
        service.call
        user.reload

        expect(user.first_name).to eq('Nuevo')
        expect(user.last_name).to eq('Nombre')
      end

      it 'retorna el usuario actualizado' do
        service.call
        expect(service.result).to eq(user)
      end

      it 'no retorna errores' do
        service.call
        expect(service.errors).to be_empty
      end
    end

    context 'actualizando email' do
      let(:attributes) { { email: 'nuevo@example.com' } }

      it 'actualiza el email' do
        service.call
        expect(user.reload.email).to eq('nuevo@example.com')
      end
    end

    context 'actualizando password' do
      let(:attributes) do
        {
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      end

      it 'actualiza el password' do
        service.call
        user.reload
        expect(user.authenticate('newpassword123')).to eq(user)
      end

      it 'el password antiguo ya no funciona' do
        old_digest = user.password_digest
        service.call
        expect(user.reload.password_digest).not_to eq(old_digest)
      end
    end

    context 'con atributos inválidos' do
      context 'cuando el email ya existe' do
        let(:existing_user) { create(:user) }
        let(:attributes) { { email: existing_user.email } }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'retorna errores de validación' do
          service.call
          expect(service.errors).to include(a_string_matching(/email/i))
        end

        it 'no actualiza el usuario' do
          old_email = user.email
          service.call
          expect(user.reload.email).to eq(old_email)
        end
      end

      context 'cuando el email es inválido' do
        let(:attributes) { { email: 'invalid-email' } }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'retorna error de formato' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*invalid/i))
        end
      end

      context 'cuando el password es muy corto' do
        let(:attributes) do
          {
            password: '123',
            password_confirmation: '123'
          }
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'retorna error de longitud' do
          service.call
          expect(service.errors).to include(a_string_matching(/password.*short/i))
        end
      end

      context 'cuando password y password_confirmation no coinciden' do
        let(:attributes) do
          {
            password: 'newpassword123',
            password_confirmation: 'different123'
          }
        end

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'retorna error de confirmación' do
          service.call
          expect(service.errors).to include(a_string_matching(/password confirmation.*match/i))
        end
      end

      context 'cuando el email está vacío' do
        let(:attributes) { { email: '' } }

        it 'retorna success false' do
          service.call
          expect(service.success?).to be false
        end

        it 'retorna error de presencia' do
          service.call
          expect(service.errors).to include(a_string_matching(/email.*blank/i))
        end
      end
    end

    context 'actualizando múltiples campos' do
      let(:attributes) do
        {
          first_name: 'Juan',
          last_name: 'Pérez',
          email: 'juan.perez@example.com'
        }
      end

      it 'actualiza todos los campos' do
        service.call
        user.reload

        expect(user.first_name).to eq('Juan')
        expect(user.last_name).to eq('Pérez')
        expect(user.email).to eq('juan.perez@example.com')
      end
    end

    context 'sin cambios' do
      let(:attributes) { {} }

      it 'retorna success true' do
        service.call
        expect(service.success?).to be true
      end

      it 'no genera errores' do
        service.call
        expect(service.errors).to be_empty
      end
    end
  end

  describe 'herencia de BaseService' do
    let(:attributes) { { first_name: 'Test' } }

    it 'hereda de BaseService' do
      expect(service).to be_a(BaseService)
    end

    it 'responde a los métodos de BaseService' do
      expect(service).to respond_to(:success?, :failure?, :errors, :result, :call)
    end
  end
end
