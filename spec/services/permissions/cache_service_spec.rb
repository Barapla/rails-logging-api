# spec/services/permissions/cache_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permissions::CacheService, type: :service do
  let(:admin_role) { Role.find_by(name: 'admin') }
  let(:user_role) { Role.find_by(name: 'usuario') }
  let(:admin_user) { create(:user, :confirmed, role: admin_role) }
  let(:regular_user) { create(:user, :confirmed, role: user_role) }

  describe '.get_user_permissions' do
    it 'retorna los permisos del usuario' do
      permissions = described_class.get_user_permissions(admin_user.id)

      expect(permissions).to be_a(Hash)
      expect(permissions[:users]).to be_present
    end

    it 'cachea los permisos en Redis' do
      cache_key = "permissions:user:#{admin_user.id}"

      # Primera llamada
      described_class.get_user_permissions(admin_user.id)

      # Verificar que está en cache
      expect(REDIS.exists?(cache_key)).to be true
    end

    it 'usa el cache en la segunda llamada' do
      # Primera llamada - hit a DB
      expect(User).to receive(:includes).once.and_call_original
      described_class.get_user_permissions(admin_user.id)

      # Segunda llamada - desde cache
      expect(User).not_to receive(:includes)
      described_class.get_user_permissions(admin_user.id)
    end

    it 'expira el cache después del TTL' do
      cache_key = "permissions:user:#{admin_user.id}"

      described_class.get_user_permissions(admin_user.id)

      ttl = REDIS.ttl(cache_key)
      expect(ttl).to be > 0
      expect(ttl).to be <= Permissions::CacheService::CACHE_TTL
    end
  end

  describe '.user_can?' do
    it 'retorna true si el usuario tiene el permiso' do
      result = described_class.user_can?(admin_user.id, 'read', 'users')
      expect(result).to be true
    end

    it 'retorna false si el usuario NO tiene el permiso' do
      result = described_class.user_can?(regular_user.id, 'read', 'users')
      expect(result).to be false
    end

    it 'usa el cache para verificar permisos' do
      # Poblar cache
      described_class.get_user_permissions(admin_user.id)

      # No debe hacer query a DB
      expect(User).not_to receive(:includes)
      described_class.user_can?(admin_user.id, 'read', 'users')
    end
  end

  describe '.invalidate_user_cache' do
    it 'elimina el cache del usuario' do
      cache_key = "permissions:user:#{admin_user.id}"

      # Crear cache
      described_class.get_user_permissions(admin_user.id)
      expect(REDIS.exists?(cache_key)).to be true

      # Invalidar
      described_class.invalidate_user_cache(admin_user.id)
      expect(REDIS.exists?(cache_key)).to be false
    end
  end

  describe '.invalidate_role_cache' do
    it 'invalida el cache de todos los usuarios con ese rol' do
      user1 = create(:user, :confirmed, role: admin_role)
      user2 = create(:user, :confirmed, role: admin_role)

      # Crear cache para ambos
      described_class.get_user_permissions(user1.id)
      described_class.get_user_permissions(user2.id)

      # Invalidar rol
      described_class.invalidate_role_cache(admin_role.id)

      # Verificar que ambos fueron invalidados
      expect(REDIS.exists?("permissions:user:#{user1.id}")).to be false
      expect(REDIS.exists?("permissions:user:#{user2.id}")).to be false
    end
  end

  describe '.invalidate_all' do
    it 'invalida todo el cache de permisos' do
      user1 = create(:user, :confirmed, role: admin_role)
      user2 = create(:user, :confirmed, role: user_role)

      # Crear cache
      described_class.get_user_permissions(user1.id)
      described_class.get_user_permissions(user2.id)

      # Invalidar todo
      described_class.invalidate_all

      # Verificar que todo fue invalidado
      keys = REDIS.keys("permissions:user:*")
      expect(keys).to be_empty
    end
  end

  describe 'estructura del cache' do
    it 'cachea permisos agrupados por resource' do
      permissions = described_class.get_user_permissions(admin_user.id)

      expect(permissions[:users][:permissions]).to include(:read, :create, :update, :delete)
    end
  end

  describe 'invalidación automática' do
    it 'invalida cache cuando cambia el rol del usuario' do
      cache_key = "permissions:user:#{regular_user.id}"

      # Crear cache
      described_class.get_user_permissions(regular_user.id)
      expect(REDIS.exists?(cache_key)).to be true

      # Cambiar rol
      regular_user.update!(role: admin_role)

      # Verificar que se invalidó
      expect(REDIS.exists?(cache_key)).to be false
    end
  end
end
