# lib/seeds/base_seeder.rb
# frozen_string_literal: true

module Seeds
  class BaseSeeder
    class << self
      def seed!(json_file)
        handle_errors do
          data = load_json(json_file)
          return unless data

          log_progress("Procesando #{json_file}...")

          check_dependencies(data["dependencies"]) if data["dependencies"]

          process_records(data)

          log_progress("✓ #{json_file} completado")
        end
      end

      protected

      def process_records(data)
        model = data["model"].constantize
        unique_by = data["unique_by"] || [ "name" ]

        data["records"].each do |record_data|
          find_or_create(model, record_data, unique_by: unique_by)
        end
      end

      def load_json(filename)
        file_path = Rails.root.join("db", "seeds", filename)
        unless File.exist?(file_path)
          log_progress("⚠ Archivo #{filename} no encontrado")
          return nil
        end
        JSON.parse(File.read(file_path))
      end

      def find_or_create(model, attributes, unique_by: [ "name" ])
        unique_attrs = unique_by.each_with_object({}) do |key, hash|
          hash[key] = attributes[key] if attributes.key?(key)
        end

        record = model.find_or_initialize_by(unique_attrs)
        record.assign_attributes(attributes.except(*unique_by))

        if record.save
          log_progress("  ✓ #{model.name}: #{unique_attrs.values.join(', ')}")
          record
        else
          log_progress("  ✗ Error: #{record.errors.full_messages.join(', ')}")
          nil
        end
      end

      def check_dependencies(dependencies)
        dependencies.each do |dep|
          model = dep.constantize
          if model.count.zero?
            raise "⚠ Dependencia no cumplida: #{dep} debe tener registros"
          end
        end
      end

      def log_progress(message)
        Rails.logger.info("[SEED] #{message}")
        puts "[SEED] #{message}" unless Rails.env.test?
      end

      def handle_errors(&block)
        ActiveRecord::Base.transaction(&block)
      rescue StandardError => e
        log_progress("❌ Error: #{e.message}")
        raise e unless Rails.env.development?
      end
    end
  end
end
