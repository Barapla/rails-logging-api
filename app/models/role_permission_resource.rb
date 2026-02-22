# app/models/role_permission_resource.rb
# frozen_string_literal: true

class RolePermissionResource < ApplicationRecord
  include SoftDeletable
  belongs_to :role
  belongs_to :permission
  belongs_to :resource

  validates :role, presence: true
  validates :permission, presence: true
  validates :resource, presence: true
  validates :role_id, uniqueness: {
    scope: [ :permission_id, :resource_id ],
    message: "ya tiene este permiso asignado para este recurso"
  }

  # Invalidar cache cuando se modifiquen permisos
  after_save :invalidate_role_cache
  after_destroy :invalidate_role_cache

  private

  def invalidate_role_cache
    Permissions::CacheService.invalidate_role_cache(role_id)
  end
end
