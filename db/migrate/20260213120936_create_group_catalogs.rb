# frozen_string_literal: true

# CreateGroupCatalogs Class
class CreateGroupCatalogs < ActiveRecord::Migration[8.1]
   def change
      create_table :group_catalogs do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :name
         t.string :code

         t.timestamps
      end

      add_index :group_catalogs, :uuid, unique: true
      add_index :group_catalogs, :active
   end
end
