# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb
# frozen_string_literal: true

# Crear rol por defecto
# frozen_string_literal: true

require_relative '../lib/seeds/dynamic_seeder'

puts "\n🌱 Iniciando seeds...\n"

# Cargar configuración
config_path = Rails.root.join('db/seeds/seed_order.yml')
config = YAML.load_file(config_path)

# Ejecutar grupos de seeds
config['groups'].each do |group_name, group_config|
  puts "\n📦 #{group_config['description']}"
  puts "─" * 50

  group_config['files'].each do |file|
    Seeds::DynamicSeeder.seed!(file)
  end
end

puts "\n✅ Todos los seeds completados exitosamente\n"
