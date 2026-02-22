class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :role, null: false, foreign_key: true
  end

  def down
    remove_references :users, :role
  end
end
