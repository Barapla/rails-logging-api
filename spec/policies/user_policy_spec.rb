# spec/policies/user_policy_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class.new(user, target_user) }

  let(:admin_role) { Role.find_by(name: 'admin') }
  let(:user_role) { Role.find_by(name: 'usuario') }

  describe 'para usuario admin' do
    let(:user) { create(:user, :confirmed, role: admin_role) }
    let(:target_user) { create(:user, :confirmed, role: user_role) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    context 'intentando eliminarse a sí mismo' do
      let(:target_user) { user }

      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'para usuario regular' do
    let(:user) { create(:user, :confirmed, role: user_role) }
    let(:target_user) { create(:user, :confirmed, role: user_role) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:create) }

    context 'accediendo a su propio perfil' do
      let(:target_user) { user }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end

    context 'accediendo a otro usuario' do
      it { is_expected.not_to permit_action(:show) }
      it { is_expected.not_to permit_action(:update) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'Scope' do
    let!(:admin_user) { create(:user, :confirmed, role: admin_role) }
    let!(:regular_users) { create_list(:user, 3, :confirmed, role: user_role) }

    context 'para admin' do
      it 'retorna todos los usuarios' do
        scope = UserPolicy::Scope.new(admin_user, User).resolve
        expect(scope.count).to eq(User.count)
      end
    end

    context 'para usuario regular' do
      let(:regular_user) { regular_users.first }

      it 'solo retorna el usuario mismo' do
        scope = UserPolicy::Scope.new(regular_user, User).resolve
        expect(scope).to contain_exactly(regular_user)
      end
    end
  end
end
