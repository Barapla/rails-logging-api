# frozen_string_literal: true

# User Model
class User < ApplicationRecord
    include SoftDeletable
    has_secure_password

    belongs_to :role

    # Callbacks
    before_validation :assign_default_role, on: :create
    after_update :invalidate_permissions_cache, if: :saved_change_to_role_id?

    # Validations
    validates :email, presence: true, uniqueness: { conditions: -> { where(active: true) } }, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
    validates :role, presence: true

    # Método de autorización
    def can?(permission_name, resource_name)
        Permissions::CacheService.user_can?(id, permission_name, resource_name)
    end

    # Obtener todos los permisos (cacheados)
    def cached_permissions
        Permissions::CacheService.get_user_permissions(id)
    end

    def name
        [ first_name, last_name ].compact.join(" ")
    end

    def generate_password_token!
        self.reset_password_token = generate_token
        self.reset_password_sent_at = Time.zone.now
        save!
    end

    def password_token_valid?
        (self.reset_password_sent_at + 4.hours) > Time.zone.now
    end

    def reset_password!(password)
        self.reset_password_token = nil
        self.password = password
        save!
    end

    def generate_confirmation_token!
        self.confirmation_token = generate_token
        self.confirmation_sent_at = Time.zone.now
        save!
    end

    def confirmation_token_valid?
        (self.confirmation_sent_at + 4.hours) > Time.zone.now
    end

    def confirm!
        self.confirmed_at = Time.zone.now
        save!
    end

    private

    def invalidate_permissions_cache
        Permissions::CacheService.invalidate_user_cache(id)
    end

    def assign_default_role
        self.role ||= Role.find_by(name: "usuario")
    end

    def generate_token
        SecureRandom.random_number(1000...9999)
    end
end
