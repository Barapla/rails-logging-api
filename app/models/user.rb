class User < ApplicationRecord
  belongs_to :role, optional: true

  # Include default devise modules. Others available are:
  # , :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  # Método para verificar si el usuario tiene un permiso específico sobre un recurso
  def can?(permission_name, resource_name)
    return false unless role

    role.role_permission_resources
        .joins(:permission, :resource)
        .where(permissions: { name: permission_name })
        .where(resources: { name: resource_name })
        .where(active: true)
        .exists?
  end
end
