class Permission < ApplicationRecord
    has_many :role_permission_resources, dependent: :destroy
    has_many :roles, through: :role_permission_resources
    has_many :resources, through: :role_permission_resources

    validates :name, presence: true

    scope :active, -> { where(active: true) }
end
