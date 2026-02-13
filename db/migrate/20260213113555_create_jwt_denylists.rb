# frozen_string_literal: true

# CreateJwtDenylists Class
class CreateJwtDenylists < ActiveRecord::Migration[8.1]
   def change
      create_table :jwt_denylists do |t|
         t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
         t.boolean :active, default: true
         t.string :jti
         t.datetime :exp

         t.timestamps
      end

      add_index :jwt_denylists, :uuid, unique: true
      add_index :jwt_denylists, :jti
      add_index :jwt_denylists, :active
   end
end
