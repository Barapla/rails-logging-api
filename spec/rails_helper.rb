# spec/rails_helper.rb
# Asegúrate de tener estas configuraciones

require 'spec_helper'
require 'mock_redis'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Configuración de FactoryBot
require 'factory_bot_rails'

# Configuración de Shoulda Matchers
require 'shoulda/matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  # Limpieza de base de datos
  config.use_transactional_fixtures = true

  config.include ActiveJob::TestHelper

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    redis_mock = MockRedis.new
    stub_const('REDIS', redis_mock)
  end

  config.before(:suite) do
    # Cargar seeds una sola vez antes de todos los tests
    require_relative '../db/seeds'
  end
end

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
