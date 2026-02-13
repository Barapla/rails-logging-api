# frozen_string_literal: true

# UserSerializer
class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :uuid, :email, :first_name, :last_name, :created_at

  attribute :role do |user|
    if user.role
      {
        id: user.role.id,
        name: user.role.name
      }
    end
  end
end
