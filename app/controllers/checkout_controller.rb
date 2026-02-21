require "bigdecimal"
require "securerandom"

class CheckoutController < ApplicationController
  ALLOWED_CURRENCIES = %w[USD EUR ILS].freeze

  skip_before_action :authenticate_user!
  layout "public"

  def new
  end

  def create
    ensure_stripe_ready!
    amount_cents = parse_amount_cents
    currency = checkout_currency

    if amount_cents <= 0
      flash[:alert] = "Amount must be greater than zero."
      redirect_to new_checkout_path and return
    end

    unless ALLOWED_CURRENCIES.include?(currency)
      flash[:alert] = "Unsupported currency."
      redirect_to new_checkout_path and return
    end

    customer = find_or_create_checkout_customer
    task = build_checkout_task(customer)

    success_token = SecureRandom.hex(12)
    cancel_token = SecureRandom.hex(12)
    metadata = checkout_metadata(customer, task).merge(
      "success_url" => success_template_url(success_token),
      "success_token" => success_token,
      "cancel_url" => cancel_template_url(cancel_token),
      "cancel_token" => cancel_token
    )

    payment = Gateways::StripeGateway.create_payment!(
      amount_cents: amount_cents,
      currency: currency,
      task: task,
      payable: customer,
      metadata: metadata
    )

    if payment.payment_url.present?
      redirect_to payment.payment_url, allow_other_host: true, status: :see_other
    else
      flash[:notice] = "Payment created. We'll confirm by email shortly."
      redirect_to checkout_success_path
    end
  rescue => e
    Rails.logger.error("[Checkout] Failed to create Stripe payment: #{e.message}")
    flash[:alert] = "Payment error: #{e.message}"
    redirect_to new_checkout_path
  end

  def success
    @session_id = params[:session_id]
    @payment = find_success_payment(session_id: @session_id, token: params[:token])
  end

  def cancel
    @session_id = params[:session_id]
    @payment = find_cancel_payment(token: params[:token])
  end

  def confirm_cancel
    @payment = find_cancel_payment(token: params[:token])
    if @payment.present? && @payment.gateway_status != "succeeded"
      @payment.update!(gateway_status: "canceled")
    end

    redirect_to checkout_cancel_path(token: params[:token], session_id: params[:session_id])
  end

  private

  def checkout_params
    params.permit(:service_type, :amount, :currency, :name, :email, :phone, :service_description)
  end

  def parse_amount_cents
    amount = BigDecimal(checkout_params[:amount].to_s)
    (amount * 100).to_i
  rescue ArgumentError, TypeError
    0
  end

  def checkout_currency
    checkout_params[:currency].to_s.upcase.presence || "USD"
  end

  def ensure_stripe_ready!
    secret = Rails.configuration.x.try(:stripe).try(:secret_key)
    raise "Stripe is not configured" if secret.blank?
  end

  def find_or_create_checkout_customer
    email = checkout_params[:email].to_s.downcase
    raise "Email is required" if email.blank?
    raise "Full name is required" if checkout_params[:name].blank?
    raise "Phone number is required" if checkout_params[:phone].blank?

    Customer.find_or_initialize_by(email: email).tap do |customer|
      customer.name = checkout_params[:name].presence || customer.name || "Checkout Customer"
      phones = Array(checkout_params[:phone]).compact_blank
      customer.phones = (Array(customer.phones) | phones)
      customer.category ||= :individual
      customer.address = checkout_params[:service_description].presence || customer.address || "Checkout submission"
      customer.save!
    end
  end

  def build_checkout_task(customer)
    Task.create!(
      customer: customer,
      carrier: default_carrier,
      task_type: "delivery_and_pickup",
      poa_enabled: false,
      package_type: checkout_params[:service_type].presence || "general_service",
      start: "Online checkout",
      target: checkout_params[:service_description].presence || "Fast Epost service",
      status: :pending,
      barcode: generate_barcode,
      delivery_time: Time.current
    )
  end

  def default_carrier
    Carrier.default_system_carrier
  end

  def generate_barcode
    loop do
      code = "CHK#{SecureRandom.hex(5).upcase}"
      break code unless Task.exists?(barcode: code)
    end
  end

  def checkout_metadata(customer, task)
    {
      "service_type" => checkout_params[:service_type],
      "service_description" => checkout_params[:service_description],
      "customer_email" => customer.email,
      "customer_name" => customer.name,
      "customer_phone" => customer.phones&.first,
      "submitted_name" => checkout_params[:name],
      "submitted_email" => checkout_params[:email],
      "submitted_phone" => checkout_params[:phone],
      "task_id" => task.id
    }.compact
  end

  def success_template_url(token)
    "#{checkout_success_url}?session_id={CHECKOUT_SESSION_ID}&token=#{token}"
  rescue
    "#{ENV["APP_BASE_URL"].presence || "http://localhost:3000"}/checkout/success?session_id={CHECKOUT_SESSION_ID}&token=#{token}"
  end

  def cancel_template_url(token)
    "#{checkout_cancel_url}?token=#{token}"
  rescue
    "#{ENV["APP_BASE_URL"].presence || "http://localhost:3000"}/checkout/cancel?token=#{token}"
  end

  def find_success_payment(session_id:, token: nil)
    return nil if session_id.blank? || token.blank?

    payment = Payment.find_by(checkout_session_id: session_id)
    return nil unless payment

    stored_token = payment.metadata.to_h["success_token"].presence || payment.metadata.to_h["cancel_token"].presence
    return nil unless token_matches?(stored_token, token)

    payment
  end

  def find_cancel_payment(token: nil)
    return nil if token.blank?

    payment = Payment.where("metadata ->> 'cancel_token' = ?", token).first
    return nil unless payment

    return nil unless token_matches?(payment.metadata.to_h["cancel_token"], token)

    payment
  end

  def token_matches?(expected, provided)
    expected = expected.to_s
    provided = provided.to_s
    return false if expected.blank? || provided.blank?
    return false unless expected.bytesize == provided.bytesize

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end
end
