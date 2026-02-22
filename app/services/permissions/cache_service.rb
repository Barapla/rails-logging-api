# app/services/permissions/cache_service.rb
# frozen_string_literal: true

module Permissions
  class CacheService
    CACHE_TTL = 1.hour.to_i
    CACHE_PREFIX = "permissions"

    class << self
      def get_user_permissions(user_id)
        cache_key = user_permissions_key(user_id)

        cached = REDIS.get(cache_key)
        return JSON.parse(cached, symbolize_names: true) if cached

        permissions = fetch_and_cache_user_permissions(user_id)
        permissions
      end

      def user_can?(user_id, permission_name, resource_name)
        permissions = get_user_permissions(user_id)

        # Normalizar a símbolos
        resource_key = resource_name.to_sym
        permission_key = permission_name.to_sym

        # Buscar permisos del resource
        resource_permissions = permissions.dig(resource_key, :permissions) || []

        # Convertir a símbolos si son strings
        resource_permissions = resource_permissions.map(&:to_sym)

        # Verificar si tiene el permiso
        resource_permissions.include?(permission_key)
      end

      def invalidate_user_cache(user_id)
        cache_key = user_permissions_key(user_id)
        REDIS.del(cache_key)
      end

      def invalidate_role_cache(role_id)
        users = User.where(role_id: role_id)
        users.find_each do |user|
          invalidate_user_cache(user.id)
        end
      end

      def invalidate_all
        keys = REDIS.keys("#{CACHE_PREFIX}:user:*")
        REDIS.del(*keys) if keys.any?
      end

      private

      def fetch_and_cache_user_permissions(user_id)
        user = User.includes(role: { role_permission_resources: [ :permission, :resource ] })
                   .find(user_id)

        permissions_hash = {}

        user.role.role_permission_resources.where(active: true).each do |rpr|
          resource_name = rpr.resource.name.to_sym
          permission_name = rpr.permission.name.to_sym

          permissions_hash[resource_name] ||= { permissions: [] }
          permissions_hash[resource_name][:permissions] << permission_name
        end

        cache_key = user_permissions_key(user_id)
        REDIS.setex(cache_key, CACHE_TTL, permissions_hash.to_json)

        permissions_hash
      end

      def user_permissions_key(user_id)
        "#{CACHE_PREFIX}:user:#{user_id}"
      end
    end
  end
end
