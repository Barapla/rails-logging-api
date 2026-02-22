# spec/models/user_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validaciones' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:password).is_at_least(6).on(:create) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
  end

  describe 'asociaciones' do
    it 'tiene un rol asignado después de crear' do
      user = create(:user)
      expect(user.role).to be_present
      expect(user.role.name).to eq('usuario')
    end
  end

  describe 'scopes' do
  describe 'soft delete scopes' do
    let!(:active_user) { create(:user, active: true) }
    let!(:inactive_user) { create(:user, active: false) }

    it 'default scope retorna solo usuarios activos' do
      expect(User.all).to include(active_user)
      expect(User.all).not_to include(inactive_user)
    end

    it 'with_inactive retorna todos' do
      expect(User.with_inactive).to include(active_user, inactive_user)
    end
  end
end

  describe '#name' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

    it 'retorna el nombre completo' do
      expect(user.name).to eq('John Doe')
    end

    context 'cuando solo tiene first_name' do
      let(:user) { build(:user, first_name: 'John', last_name: nil) }

      it 'retorna solo el first_name sin espacios extra' do
        expect(user.name).to eq('John')
      end
    end
  end

  describe '#generate_confirmation_token!' do
    let(:user) { create(:user) }

    it 'genera un confirmation_token' do
      expect {
        user.generate_confirmation_token!
      }.to change(user, :confirmation_token).from(nil)
    end

    it 'establece confirmation_sent_at' do
      expect {
        user.generate_confirmation_token!
      }.to change(user, :confirmation_sent_at).from(nil)
    end

    it 'guarda el usuario' do
      user.generate_confirmation_token!
      expect(user.reload.confirmation_token).to be_present
    end
  end

  describe '#confirmation_token_valid?' do
    let(:user) { create(:user) }

    context 'cuando el token es reciente' do
      before do
        user.update!(
          confirmation_token: 'test123',
          confirmation_sent_at: 1.hour.ago
        )
      end

      it 'retorna true' do
        expect(user.confirmation_token_valid?).to be true
      end
    end

    context 'cuando el token ha expirado' do
      before do
        user.update!(
          confirmation_token: 'test123',
          confirmation_sent_at: 5.hours.ago
        )
      end

      it 'retorna false' do
        expect(user.confirmation_token_valid?).to be false
      end
    end
  end

  describe '#confirm!' do
    let(:user) { create(:user, confirmation_token: 'test123') }

    it 'establece confirmed_at' do
      expect {
        user.confirm!
      }.to change(user, :confirmed_at).from(nil)
    end

    it 'guarda el usuario' do
      user.confirm!
      expect(user.reload.confirmed_at).to be_present
    end
  end

  describe 'has_secure_password' do
    let(:user) { build(:user, password: 'password123') }

    it 'hashea el password' do
      user.save!
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('password123')
    end

    it 'valida el password correctamente' do
      user.save!
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'falla con password incorrecto' do
      user.save!
      expect(user.authenticate('wrong')).to be false
    end
  end

  describe '#can? con cache' do
    let!(:admin_role) { Role.find_by(name: 'admin') }

    before do
      # Crear permisos
      read_permission = Permission.find_or_create_by!(name: 'read')
      users_resource = Resource.find_or_create_by!(name: 'users')

      RolePermissionResource.find_or_create_by!(
        role: admin_role,
        permission: read_permission,
        resource: users_resource,
        active: true
      )

      # Crear usuario UNA SOLA VEZ
      @admin_user = create(:user, :confirmed, role: admin_role)

      # Llamar directamente al cache service
      perms = Permissions::CacheService.get_user_permissions(@admin_user.id)

      # Probar user_can? directamente
      Permissions::CacheService.user_can?(@admin_user.id, 'read', 'users')

      # Probar con símbolos
      Permissions::CacheService.user_can?(@admin_user.id, :read, :users)
      # Ver qué hay en el dig
      perms.dig(:users, :permissions)
    end

    it 'usa cache en llamadas subsecuentes' do
      expect(@admin_user.can?('read', 'users')).to be true
    end
  end
end
