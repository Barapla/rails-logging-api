# app/policies/user_policy.rb
# frozen_string_literal: true

class UserPolicy < BasePolicy
  def index?
    user.can?("read", "users")
  end

  def show?
    # Admin puede ver todos, usuarios regulares solo su propio perfil
    user.can?("read", "users") || own_record?
  end

  def create?
    user.can?("create", "users")
  end

  def update?
    # Admin puede actualizar todos, usuarios regulares solo su perfil
    user.can?("update", "users") || own_record?
  end

  def destroy?
    # Solo admin puede eliminar Y no puede eliminarse a sí mismo
    user.can?("delete", "users") && !own_record?  # ← Ya estaba bien
  end

  class Scope < BasePolicy::Scope
    def resolve
      if user.can?("read", "users")
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  private

  def own_record?
    return false if record.is_a?(Class)  # ← Agregar esta validación
    record.id == user.id
  end

  def resource_name
    "users"
  end
end
