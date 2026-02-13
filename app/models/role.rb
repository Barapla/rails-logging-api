class Role < ApplicationRecord
    has_many :users, dependent: :nullify
    has_many :role_permission_resources, dependent: :destroy
    has_many :permissions, through: :role_permission_resources
    has_many :resources, through: :role_permission_resources

    validates :name, presence: true

    scope :active, -> { where(active: true) }
end
