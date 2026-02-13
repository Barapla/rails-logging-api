# frozen_string_literal: true

# CreatePermissions Class
class CreatePermissions < ActiveRecord::Migration[8.1]
   def change
      create_table :permissions do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :name
         t.string :code

         t.timestamps
      end

      add_index :permissions, :uuid, unique: true
      add_index :permissions, :active
   end
end
