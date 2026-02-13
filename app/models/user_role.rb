class UserRole < ApplicationRecord
  belongs_to :user_id
  belongs_to :role_id
end
