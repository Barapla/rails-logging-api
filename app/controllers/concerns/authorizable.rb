# app/controllers/concerns/authorizable.rb
# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  included do
    rescue_from NotAuthorizedError, with: :user_not_authorized
  end

  class NotAuthorizedError < StandardError
    attr_reader :action, :record

    def initialize(action, record)
      @action = action
      @record = record
      record_name = record.is_a?(Class) ? record.name : record.class.name  # ← Arreglar aquí
      super("No autorizado: acción '#{action}' en '#{record_name}'")
    end
  end

  def authorize!(record, action = nil)
    action ||= action_from_params
    policy = policy(record)

    unless policy.public_send("#{action}?")
      raise NotAuthorizedError.new(action, record)
    end
  end

  def policy(record)
    policy_class = policy_class_for(record)
    policy_class.new(@current_user, record)
  end

  def policy_scope(scope)
    policy_class = policy_class_for(scope)
    policy_class::Scope.new(@current_user, scope).resolve
  end

  private

  def policy_class_for(record)
    klass = record.is_a?(Class) ? record : record.class
    "#{klass.name}Policy".constantize
  rescue NameError
    BasePolicy
  end

  def action_from_params
    case action_name
    when "index" then "index"
    when "show" then "show"
    when "new", "create" then "create"
    when "edit", "update" then "update"
    when "destroy" then "destroy"
    else
      action_name
    end
  end

  def user_not_authorized(exception)
    record_name = exception.record.is_a?(Class) ? exception.record.name : exception.record.class.name

    # Intentar inferir el permiso RBAC desde la acción
    permission = case exception.action.to_s  # ← Asegurar que sea string
    when "index", "show" then "read"
    when "create", "new" then "create"
    when "update", "edit" then "update"
    when "destroy" then "delete"
    else exception.action
    end

    render json: {
      status: {
        code: 403,
        message: "No tienes permiso para realizar esta acción"
      },
      errors: [
        "Permiso requerido: '#{permission}' en '#{record_name.pluralize.underscore}'"
      ]
    }, status: :forbidden
  end
end
