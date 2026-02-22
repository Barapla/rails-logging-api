# app/services/base_service.rb
# frozen_string_literal: true

# Clase base para todos los Service Objects
# Proporciona estructura común para manejo de errores y resultados
class BaseService
  def initialize
    @errors = []
    @success = true
    @result = nil
  end

  # Método principal que debe ser implementado por cada servicio
  def call
    raise NotImplementedError, "#{self.class} debe implementar el método #call"
  end

  # Indica si el servicio ejecutó exitosamente
  def success?
    @success
  end

  # Indica si el servicio falló
  def failure?
    !@success
  end

  # Retorna el resultado del servicio
  def result
    @result
  end

  # Retorna los errores del servicio
  def errors
    @errors
  end

  private

  # Agrega un error al servicio
  def add_error(message)
    @errors << message
  end

  # Marca el servicio como fallido
  def fail!(message)
    add_error(message)
    @success = false
  end
end
