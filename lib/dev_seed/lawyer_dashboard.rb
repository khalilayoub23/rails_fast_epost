# frozen_string_literal: true

# Dev helper to generate realistic data for the lawyer dashboard.
# Usage:
#   bin/rails runner "DevSeed::LawyerDashboard.run"
#   bin/rails runner "DevSeed::LawyerDashboard.run(email: 'lawyer@example.com', tasks: 12)"

module DevSeed
  class LawyerDashboard
    def self.run(email: "lawyer@example.com", tasks: 10)
      new(email:, tasks:).run
    end

    def initialize(email:, tasks:)
      @email = email
      @tasks_count = Integer(tasks)
    end

    def run
      raise "Refusing to seed outside development" unless Rails.env.development?

      lawyer = User.find_by(email: @email)
      raise "No user found with email=#{@email.inspect}" unless lawyer

      lawyer_profile = Lawyer.find_by(email: lawyer.email) || Lawyer.create!(
        name: lawyer.email.split("@").first.to_s.titleize,
        email: lawyer.email,
        phone: "0500000000",
        license_number: "LIC-#{SecureRandom.hex(6)}",
        specialization: :customs,
        active: true
      )

      seed_customer
      seed_tasks_for(lawyer_profile)

      puts "Seeded #{@tasks_count} tasks + payments for #{lawyer.email}"
    end

    private

    def seed_customer
      return if Customer.exists?

      Customer.create!(
        name: "Demo Customer",
        email: "customer@example.com",
        phone: "0500000000",
        address: "1 Demo Street"
      )
    rescue ActiveModel::UnknownAttributeError
      # Customer schema may differ between environments; create a minimal record.
      Customer.create!(name: "Demo Customer")
    end

    def seed_tasks_for(lawyer_profile)
      customer = Customer.first
      carrier = Carrier.default_system_carrier

      @tasks_count.times do |i|
        task = Task.new
        task.lawyer = lawyer_profile if task.respond_to?(:lawyer=)

        # Try to fill commonly-present fields; ignore if schema differs.
        task.barcode = "LAW-#{Time.zone.now.to_i}-#{i}" if task.respond_to?(:barcode=)
        task.package_type = "document" if task.respond_to?(:package_type=)
        task.start = "Tel Aviv" if task.respond_to?(:start=)
        task.target = "Jerusalem" if task.respond_to?(:target=)
        task.customer = customer if task.respond_to?(:customer=) && customer
        task.carrier = carrier if task.respond_to?(:carrier=) && carrier

        task.save!(validate: false)

        next unless defined?(Payment)

        amount_cents = [ 1999, 3499, 4999, 7999 ].sample
        status = %w[pending failed created].sample

        payment = Payment.new
        payment.task = task if payment.respond_to?(:task=)
        payment.payable = (customer || carrier) if payment.respond_to?(:payable=)
        payment.category = "service_fee" if payment.respond_to?(:category=)
        payment.payment_type = "per_task" if payment.respond_to?(:payment_type=)
        payment.amount_cents = amount_cents if payment.respond_to?(:amount_cents=)
        payment.currency = "ILS" if payment.respond_to?(:currency=)
        payment.gateway_status = status if payment.respond_to?(:gateway_status=)
        payment.provider = "dev_seed" if payment.respond_to?(:provider=)
        payment.save!(validate: false)

        # Create some succeeded payments for dashboard totals without triggering after_commit automation.
        if rand < 0.7
          payment.update_columns(gateway_status: "succeeded", updated_at: Time.current)
        end

        PaymentsTask.create!(payment: payment, task: task) if defined?(PaymentsTask)
      end
    end
  end
end
