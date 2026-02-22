# lib/seeds/dynamic_seeder.rb
# frozen_string_literal: true

module Seeds
  class DynamicSeeder
    class << self
      def seed!(json_file)
        handle_errors do
          data = load_json(json_file)
          return unless data

          log_progress("📄 Procesando #{json_file}...")

          # Validar dependencias
          check_dependencies(data["dependencies"]) if data["dependencies"]

          # Obtener configuración
          model = data["model"].constantize
          unique_by = data["unique_by"] || [ "name" ]
          skip_if_exists = data["skip_if_exists"] || false
          belongs_to_config = data["belongs_to"] || {}
          nested_config = data["nested_attributes"] || {}

          # Procesar cada registro
          data["records"].each do |record_data|
            process_record(
              model: model,
              record_data: record_data,
              unique_by: unique_by,
              skip_if_exists: skip_if_exists,
              belongs_to_config: belongs_to_config,
              nested_config: nested_config
            )
          end

          log_progress("✓ #{json_file} completado\n")
        end
      end

      private

      def process_record(model:, record_data:, unique_by:, skip_if_exists:, belongs_to_config:, nested_config:)
        # 1. Separar atributos normales de relaciones
        attributes, nested_data = extract_attributes_and_nested(record_data, nested_config.keys)

        # 2. Resolver belongs_to (buscar IDs de padres)
        resolved_belongs_to = resolve_belongs_to(attributes, belongs_to_config)

        # 3. Combinar atributos con IDs resueltos
        final_attributes = attributes.except(*belongs_to_config.keys.map(&:to_s))
                                    .merge(resolved_belongs_to)

        # 4. Buscar o crear registro principal
        record = find_or_create_record(
          model: model,
          attributes: final_attributes,
          unique_by: unique_by,
          skip_if_exists: skip_if_exists
        )

        return unless record

        # 5. Procesar nested_attributes (has_many)
        process_nested_attributes(record, nested_data, nested_config) if nested_data.any?

        record
      end

      # Separa atributos normales de datos anidados
      def extract_attributes_and_nested(record_data, nested_keys)
        attributes = {}
        nested_data = {}

        record_data.each do |key, value|
          if nested_keys.include?(key.to_s) || nested_keys.include?(key.to_sym)
            nested_data[key] = value
          else
            attributes[key.to_s] = value
          end
        end

        [ attributes, nested_data ]
      end

      # Resuelve belongs_to: busca el padre y retorna su ID
      def resolve_belongs_to(attributes, belongs_to_config)
        resolved = {}

        belongs_to_config.each do |association_name, find_by_field|
          association_name = association_name.to_s
          lookup_value = attributes[association_name]

          next unless lookup_value

          # Obtener el modelo asociado
          association_class = association_name.classify.constantize

          # Buscar el registro padre
          parent_record = association_class.find_by(find_by_field => lookup_value)

          if parent_record
            # Obtener el nombre del foreign_key
            foreign_key = "#{association_name}_id"
            resolved[foreign_key] = parent_record.id
            log_progress("    → #{association_name}: '#{lookup_value}' → #{foreign_key}: #{parent_record.id}")
          else
            log_progress("    ⚠ No encontrado: #{association_class.name} con #{find_by_field}='#{lookup_value}'")
          end
        end

        resolved
      end

      # Busca o crea el registro
      def find_or_create_record(model:, attributes:, unique_by:, skip_if_exists:)
        # Construir hash de búsqueda con unique_by
        unique_attrs = unique_by.each_with_object({}) do |key, hash|
          key_str = key.to_s
          hash[key_str] = attributes[key_str] if attributes.key?(key_str)
        end

        if unique_attrs.empty?
          log_progress("  ⚠ No se encontraron atributos únicos para #{model.name}")
          return nil
        end

        # Buscar registro existente
        record = model.find_by(unique_attrs)

        if record && skip_if_exists
          log_progress("  ⊘ #{model.name} ya existe (skip): #{unique_attrs.values.join(', ')}")
          return record
        end

        # Inicializar o actualizar
        record ||= model.new
        record.assign_attributes(attributes)

        if record.save
          action = record.previously_new_record? ? "creado" : "actualizado"
          log_progress("  ✓ #{model.name} #{action}: #{unique_attrs.values.join(', ')}")
          record
        else
          log_progress("  ✗ Error en #{model.name}: #{record.errors.full_messages.join(', ')}")
          nil
        end
      end

      # Procesa has_many con accepts_nested_attributes_for
      def process_nested_attributes(parent_record, nested_data, nested_config)
        nested_data.each do |association_name, children_data|
          association_name = association_name.to_s
          config = nested_config[association_name] || nested_config[association_name.to_sym] || {}

          # Obtener configuración de la asociación anidada
          child_unique_by = config["unique_by"] || config[:unique_by] || [ "name" ]

          reflection = parent_record.class.reflect_on_association(association_name.to_sym)
          unless reflection
            log_progress("    ⚠ Asociación '#{association_name}' no encontrada en #{parent_record.class.name}")
            next
          end

          child_model = reflection.klass
          foreign_key = reflection.foreign_key

          children_data.each do |child_data|
            # Agregar foreign_key al hijo
            child_attrs = child_data.merge(foreign_key => parent_record.id)

            # Buscar o crear hijo
            find_or_create_record(
              model: child_model,
              attributes: child_attrs,
              unique_by: child_unique_by,
              skip_if_exists: false
            )
          end

          log_progress("    ✓ Procesados #{children_data.size} #{association_name}")
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

      def check_dependencies(dependencies)
        dependencies.each do |dep|
          model = dep.constantize
          if model.count.zero?
            raise "⚠ Dependencia no cumplida: #{dep} debe tener registros. Ejecuta los seeds en orden correcto."
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
        log_progress(e.backtrace.first(5).join("\n"))
        raise e unless Rails.env.development?
      end
    end
  end
end
