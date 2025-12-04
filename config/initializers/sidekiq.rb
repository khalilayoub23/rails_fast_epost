return unless defined?(Sidekiq)

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
namespace = ENV.fetch("SIDEKIQ_NAMESPACE", "fast-epost")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, namespace: namespace }
  config.logger.level = Logger::INFO if ENV["RAILS_LOG_LEVEL"].blank?
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, namespace: namespace }
end

Sidekiq.default_job_options = Sidekiq.default_job_options.merge(
  retry: 3,
  backtrace: 5,
  queue: :default
)
