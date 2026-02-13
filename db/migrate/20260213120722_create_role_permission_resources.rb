# frozen_string_literal: true

# CreateRolePermissionResources Class
class CreateRolePermissionResources < ActiveRecord::Migration[8.1]
   def change
      create_table :role_permission_resources do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.references :role, null: false, foreign_key: { name: 'fk_role_permission_resources_role', to_table: :roles }
         t.references :permission, null: false, foreign_key: { name: 'fk_role_permission_resources_permission', to_table: :permissions }
         t.references :resource, null: false, foreign_key: { name: 'fk_role_permission_resources_resource', to_table: :resources }

         t.timestamps
         end

      add_index :role_permission_resources, :uuid, unique: true
      add_index :role_permission_resources, :active
      add_index :role_permission_resources,
              [ :role_id, :permission_id, :resource_id ],
              unique: true
   end
end
