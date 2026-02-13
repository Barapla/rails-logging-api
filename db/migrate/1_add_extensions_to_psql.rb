class AddExtensionsToPsql < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'pgcrypto'
  end
end
