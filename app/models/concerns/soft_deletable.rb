# app/models/concerns/soft_deletable.rb
# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Scope por defecto: solo mostrar activos
    default_scope { where(active: true) }

    # Scope para incluir inactivos explícitamente
    scope :with_inactive, -> { unscope(where: :active) }
    scope :only_inactive, -> { unscope(where: :active).where(active: false) }
    scope :active_records, -> { where(active: true) }
  end

  # Soft delete - marcar como inactivo
  def soft_delete
    update_column(:active, false)
  end

  # Alias más semántico
  def archive
    soft_delete
  end

  # Restaurar registro
  def restore
    update_column(:active, true)
  end

  # Verificar si está eliminado
  def deleted?
    !active?
  end

  # Sobrescribir destroy para hacer soft delete
  def destroy
    soft_delete
  end

  # Destrucción real (usar con cuidado)
  def destroy!
    self.class.unscoped { delete }
  end

  class_methods do
    # Soft delete en batch
    def soft_delete_all
      update_all(active: false)
    end

    # Restaurar en batch
    def restore_all
      with_inactive.update_all(active: true)
    end
  end
end
