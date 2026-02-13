# frozen_string_literal: true

# CreateCatalogs Class
class CreateCatalogs < ActiveRecord::Migration[8.1]
   def change
      create_table :catalogs do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :value
         t.string :code
         t.references :group_catalog_id, null: false, foreign_key: { name: 'fk_catalogs_group_catalog', to_table: :group_catalogs }

         t.timestamps
      end

      add_index :catalogs, :uuid, unique: true
      add_index :catalogs, :active
   end
end
