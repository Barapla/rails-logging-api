# frozen_string_literal: true

# CreateUserRoles Class
class CreateUserRoles < ActiveRecord::Migration[8.1]
   def change
      create_table :user_roles do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.references :user_id, null: false, foreign_key: { name: 'fk_user_roles_user', to_table: :users }
         t.references :role_id, null: false, foreign_key: { name: 'fk_user_roles_role', to_table: :roles }

         t.timestamps
      end

      add_index :user_roles, :uuid, unique: true
      add_index :user_roles, :active
   end
end
