# app/controllers/concerns/soft_deletable_controller.rb
# frozen_string_literal: true

module SoftDeletableController
  extend ActiveSupport::Concern

  # Permitir buscar con inactivos usando parámetro ?include_inactive=true
  def apply_soft_delete_scope(relation)
    if params[:include_inactive] == "true"
      relation.with_inactive
    elsif params[:only_inactive] == "true"
      relation.only_inactive
    else
      relation
    end
  end
end
