max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# preload_app!

plugin :tmp_restart

before_fork do
  require 'puma_worker_killer'

  PumaWorkerKiller.config do |config|
    config.ram           = ENV.fetch("PWK_RAM_MB", 512).to_i
    config.frequency     = 30
    config.percent_usage = 0.90
    config.rolling_restart_frequency = 6 * 3600
    config.reaper_status_logs = true
  end

  PumaWorkerKiller.start
end
