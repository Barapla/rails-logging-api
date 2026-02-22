class Role < ApplicationRecord
    include SoftDeletable
    has_many :users, dependent: :nullify
    has_many :role_permission_resources, dependent: :destroy
    has_many :permissions, through: :role_permission_resources
    has_many :resources, through: :role_permission_resources

    # Invalidar cache si se elimina el rol
    before_destroy :invalidate_users_cache

    validates :name, presence: true

    scope :active, -> { where(active: true) }

    private

    def invalidate_users_cache
        Permissions::CacheService.invalidate_role_cache(id)
    end
end
