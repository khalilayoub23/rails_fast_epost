module Admin
  class MonitoringController < ApplicationController
    before_action :require_admin!

    def index
      @stats = {
        jobs: job_statistics,
        webhooks: webhook_statistics,
        tasks: task_statistics,
        payments: payment_statistics,
        system: system_statistics
      }
    end

    def jobs
      @jobs = SolidQueue::Job
        .order(created_at: :desc)
        .limit(100)
        .group_by(&:queue_name)
    end

    def job_details
      @job = SolidQueue::Job.find(params[:id])
    end

    def webhooks
      # Recent webhook-like events (we'll use Payment gateway updates as proxy)
      @recent_payments = Payment
        .where("updated_at > ?", 24.hours.ago)
        .order(updated_at: :desc)
        .limit(50)
    end

    def health_check
      @health = {
        database: check_database,
        cache: check_cache,
        queue: check_queue,
        stripe: check_stripe_connection
      }

      render json: @health
    end

    private

    def job_statistics
      {
        total: SolidQueue::Job.count,
        pending: SolidQueue::Job.where(finished_at: nil).count,
        completed: SolidQueue::Job.where.not(finished_at: nil).count,
        recent_failures: SolidQueue::FailedExecution.where("created_at > ?", 24.hours.ago).count
      }
    end

    def webhook_statistics
      {
        total_payments: Payment.count,
        pending: Payment.where(gateway_status: :pending).count,
        succeeded: Payment.where(gateway_status: :succeeded).count,
        failed: Payment.where(gateway_status: :failed).count,
        recent_updates: Payment.where("updated_at > ?", 1.hour.ago).count
      }
    end

    def task_statistics
      {
        total: Task.count,
        pending: Task.pending.count,
        in_transit: Task.in_transit.count,
        delivered: Task.delivered.count,
        failed: Task.failed.count,
        returned: Task.returned.count
      }
    end

    def payment_statistics
      {
        total_amount: Payment.sum(:amount_cents) / 100.0,
        avg_amount: (Payment.average(:amount_cents)&.to_f || 0) / 100.0,
        recent_revenue: Payment.where("created_at > ?", 7.days.ago).sum(:amount_cents) / 100.0,
        providers: Payment.group(:provider).count
      }
    end

    def system_statistics
      {
        users: User.count,
        customers: Customer.count,
        carriers: Carrier.count,
        uptime: uptime_seconds,
        rails_version: Rails.version,
        ruby_version: RUBY_VERSION
      }
    end

    def check_database
      ActiveRecord::Base.connection.execute("SELECT 1")
      { status: "healthy", latency: measure_latency { ActiveRecord::Base.connection.execute("SELECT 1") } }
    rescue => e
      { status: "unhealthy", error: e.message }
    end

    def check_cache
      Rails.cache.write("health_check", Time.current.to_i)
      value = Rails.cache.read("health_check")
      { status: "healthy", latency: measure_latency { Rails.cache.read("health_check") } }
    rescue => e
      { status: "unhealthy", error: e.message }
    end

    def check_queue
      count = SolidQueue::Job.where(finished_at: nil).count
      { status: "healthy", pending_jobs: count }
    rescue => e
      { status: "unhealthy", error: e.message }
    end

    def check_stripe_connection
      secret_key = Rails.configuration.x.stripe.secret_key
      return { status: "not_configured" } unless secret_key.present?

      require "stripe"
      Stripe.api_key = secret_key
      Stripe::Account.retrieve
      { status: "healthy" }
    rescue => e
      { status: "unhealthy", error: e.message }
    end

    def measure_latency(&block)
      start = Time.current
      block.call
      ((Time.current - start) * 1000).round(2) # milliseconds
    end

    def uptime_seconds
      File.read("/proc/uptime").split.first.to_f.round(0)
    rescue
      nil
    end
  end
end
