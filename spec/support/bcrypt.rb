# spec/support/bcrypt.rb
# frozen_string_literal: true

# Reduce el costo de bcrypt en tests para acelerar la suite
RSpec.configure do |config|
  config.before(:suite) do
    # Reduce de 12 (default) a 4 (mínimo seguro para tests)
    BCrypt::Engine.cost = BCrypt::Engine::MIN_COST
  end
end
