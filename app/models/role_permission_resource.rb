class RolePermissionResource < ApplicationRecord
    belongs_to :role
    belongs_to :permission
    belongs_to :resource

    validates :role, presence: true
    validates :permission, presence: true
    validates :resource, presence: true
    validates :role_id, uniqueness: { scope: [ :permission_id, :resource_id ] }

    scope :active, -> { where(active: true) }
end
