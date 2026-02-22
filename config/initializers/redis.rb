# config/initializers/redis.rb
# frozen_string_literal: true

if Rails.env.test?
  require "mock_redis"
  REDIS = MockRedis.new
else
  REDIS = Redis.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    timeout: 5,
    reconnect_attempts: 3
  )
end
