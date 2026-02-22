class UserRole < ApplicationRecord
  include SoftDeletable
  belongs_to :user_id
  belongs_to :role_id
end
