require "test_helper"

module Gateways
  class LocalGatewayTest < ActiveSupport::TestCase
    setup do
      @task = tasks(:one)
      @customer = customers(:one)
      @old_secret = ENV["LOCALPAY_APP_SECRET"]
      ENV["LOCALPAY_APP_SECRET"] = "local_secret_test"
    end

    teardown do
      ENV["LOCALPAY_APP_SECRET"] = @old_secret
    end

    test "rejects wrong-length webhook signature safely" do
      payment = Gateways::LocalGateway.create_payment!(
        amount_cents: 1200,
        currency: "USD",
        task: @task,
        payable: @customer,
        metadata: {}
      )

      payload = { "external_id" => payment.external_id, "status" => "succeeded" }
      raw_body = payload.to_json

      error = assert_raises(RuntimeError) do
        Gateways::LocalGateway.process_webhook!(
          payload: payload,
          headers: {
            "X-Signature" => "short",
            "__raw_body__" => raw_body
          }
        )
      end

      assert_equal "Invalid signature", error.message
    end
  end
end
