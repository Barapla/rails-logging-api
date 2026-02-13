# frozen_string_literal: true

# CreateResources Class
class CreateResources < ActiveRecord::Migration[8.1]
   def change
      create_table :resources do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :name
         t.string :code

         t.timestamps
      end

      add_index :resources, :uuid, unique: true
      add_index :resources, :active
   end
end
