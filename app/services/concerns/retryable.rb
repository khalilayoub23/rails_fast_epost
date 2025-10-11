# Concern for adding retry logic with exponential backoff to service objects
# Usage: include Retryable in your service class
module Retryable
  extend ActiveSupport::Concern

  # Retry a block of code with exponential backoff
  # Options:
  #   - max_attempts: Maximum number of retry attempts (default: 3)
  #   - base_interval: Initial wait time in seconds (default: 1.0)
  #   - multiplier: Backoff multiplier (default: 2.0)
  #   - max_interval: Maximum wait time between retries (default: 30.0)
  #   - on: Array of exception classes to retry (default: [StandardError])
  #   - on_retry: Proc called after each failed attempt
  def with_retry(max_attempts: 3, base_interval: 1.0, multiplier: 2.0, max_interval: 30.0, on: [ StandardError ], &block)
    ::Retriable.retriable(
      tries: max_attempts,
      base_interval: base_interval,
      multiplier: multiplier,
      max_interval: max_interval,
      on: on,
      on_retry: ->(exception, try, elapsed_time, next_interval) {
        Rails.logger.warn(
          "[#{self.class.name}] Retry attempt #{try}/#{max_attempts} " \
          "after #{elapsed_time.round(2)}s. " \
          "Next retry in #{next_interval.round(2)}s. " \
          "Error: #{exception.class} - #{exception.message}"
        )
      }
    ) do
      yield
    end
  rescue *on => e
    Rails.logger.error(
      "[#{self.class.name}] All #{max_attempts} retry attempts failed. " \
      "Final error: #{e.class} - #{e.message}"
    )
    raise
  end

  # Retry network-related errors (common for API calls)
  def with_network_retry(max_attempts: 3, &block)
    network_errors = [
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Net::OpenTimeout,
      Net::ReadTimeout,
      SocketError,
      Timeout::Error
    ]

    # Add Stripe-specific errors if Stripe is loaded
    network_errors += [ ::Stripe::APIConnectionError, ::Stripe::RateLimitError ] if defined?(::Stripe)

    with_retry(
      max_attempts: max_attempts,
      base_interval: 2.0,
      multiplier: 2.0,
      max_interval: 60.0,
      on: network_errors,
      &block
    )
  end

  # Retry with custom backoff for rate limiting
  def with_rate_limit_retry(max_attempts: 5, &block)
    with_retry(
      max_attempts: max_attempts,
      base_interval: 5.0,
      multiplier: 2.5,
      max_interval: 120.0,
      on: [ Stripe::RateLimitError ],
      &block
    )
  end
end
