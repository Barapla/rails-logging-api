# app/policies/base_policy.rb
# frozen_string_literal: true

class BasePolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Acciones estándar CRUD
  def index?
    user.can?("read", resource_name)
  end

  def show?
    user.can?("read", resource_name)
  end

  def create?
    user.can?("create", resource_name)
  end

  def update?
    user.can?("update", resource_name)
  end

  def destroy?
    user.can?("delete", resource_name)
  end

  # Scope para filtrar registros según permisos
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  private

  def resource_name
    # Inferir nombre del resource desde el record
    # User -> 'users', Event -> 'events'
    record.is_a?(Class) ? record.name.pluralize.underscore : record.class.name.pluralize.underscore
  end
end
