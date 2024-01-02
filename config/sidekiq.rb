require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  config.logger = Rails.logger if Rails.env.test?
  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes.to_i
end

Sidekiq.configure_server do |config|
  # accepts :expiration (optional)
  Sidekiq::Status.configure_server_middleware config, expiration: 60.minutes.to_i

  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 60.minutes.to_i
end