# spec/models/concerns/soft_deletable_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SoftDeletable, type: :model do
  # Usar User como ejemplo ya que incluye SoftDeletable
  let(:user) { create(:user) }

  describe 'default scope' do
    let!(:active_user) { create(:user, active: true) }
    let!(:inactive_user) { create(:user, active: false) }

    it 'solo retorna usuarios activos por defecto' do
      expect(User.all).to include(active_user)
      expect(User.all).not_to include(inactive_user)
    end

    it 'puede buscar usuarios inactivos explícitamente' do
      expect(User.with_inactive).to include(active_user, inactive_user)
    end

    it 'puede buscar solo usuarios inactivos' do
      expect(User.only_inactive).to include(inactive_user)
      expect(User.only_inactive).not_to include(active_user)
    end
  end

  describe '#soft_delete' do
    it 'marca el registro como inactivo' do
      expect {
        user.soft_delete
      }.to change { user.reload.active }.from(true).to(false)
    end

    it 'no elimina el registro de la base de datos' do
      user  # ← Forzar creación antes del expect

      expect {
        user.soft_delete
      }.not_to change { User.with_inactive.count }
    end

    it 'ya no aparece en queries por defecto' do
      user.soft_delete
      expect(User.all).not_to include(user)
    end
  end

  describe '#archive' do
    it 'es un alias de soft_delete' do
      expect {
        user.archive
      }.to change { user.reload.active }.from(true).to(false)
    end
  end

  describe '#destroy' do
    it 'hace soft delete en lugar de eliminar' do
      user  # ← Forzar creación antes del expect

      expect {
        user.destroy
      }.not_to change { User.with_inactive.count }
    end

    it 'marca como inactivo' do
      user.destroy
      expect(user.reload).not_to be_active
    end
  end

  describe '#destroy!' do
    it 'elimina realmente el registro' do
      user  # ← Forzar creación antes del expect
      user_id = user.id

      expect {
        user.destroy!
      }.to change { User.with_inactive.count }.by(-1)

      expect { User.with_inactive.find(user_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#restore' do
    before { user.soft_delete }

    it 'restaura un registro eliminado' do
      expect {
        user.restore
      }.to change { user.reload.active }.from(false).to(true)
    end

    it 'aparece de nuevo en queries por defecto' do
      user.restore
      expect(User.all).to include(user)
    end
  end

  describe '#deleted?' do
    it 'retorna true si está inactivo' do
      user.soft_delete
      expect(user).to be_deleted
    end

    it 'retorna false si está activo' do
      expect(user).not_to be_deleted
    end
  end

  describe '.soft_delete_all' do
    let!(:users) { create_list(:user, 3) }

    it 'marca todos como inactivos' do
      User.soft_delete_all
      expect(User.with_inactive.where(active: false).count).to eq(User.with_inactive.count)
    end

    it 'no aparecen en scope por defecto' do
      User.soft_delete_all
      expect(User.count).to eq(0)
    end
  end

  describe '.restore_all' do
    let!(:inactive_users) { create_list(:user, 3, active: false) }

    it 'restaura todos los registros inactivos' do
      initial_active_count = User.count  # ← Usuarios activos antes de restore

      User.restore_all

      # Ahora debe haber initial_active_count + 3 usuarios activos
      expect(User.count).to eq(initial_active_count + 3)
    end
  end

  describe 'validación de uniqueness con soft deletes' do
    let!(:deleted_user) { create(:user, email: 'test@example.com', active: false) }

    it 'permite crear usuario con mismo email si el anterior está eliminado' do
      new_user = build(:user, email: 'test@example.com')
      expect(new_user).to be_valid
    end
  end
end
