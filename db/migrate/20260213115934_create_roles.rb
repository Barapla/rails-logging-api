# frozen_string_literal: true

# CreateRoles Class
class CreateRoles < ActiveRecord::Migration[8.1]
   def change
      create_table :roles do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :name
         t.string :code

         t.timestamps
      end

      add_index :roles, :uuid, unique: true
      add_index :roles, :active
   end
end
