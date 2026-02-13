# frozen_string_literal: true

# CreateStatuses Class
class CreateStatuses < ActiveRecord::Migration[8.1]
    def change
        create_table :statuses do |t|
            t.string :uuid, null: false, default: -> { 'gen_random_uuid()' }
            t.boolean :active, default: true
            t.string :name
            t.string :code
            t.references :group_catalogs, null: false, foreign_key: { name: 'fk_statuses_group_catalogs', to_table: :group_catalogs }


            t.timestamps
        end

        add_index :statuses, :uuid, unique: true
        add_index :statuses, :active
    end
end
