require "test_helper"

module Api
  module V1
    module Payments
      class PaymentIntentsControllerTest < ActiveSupport::TestCase
        setup do
          @controller = PaymentIntentsController.new
        end

        test "secret_matches? returns false for mismatched length" do
          assert_not @controller.send(:secret_matches?, "expected-secret", "short")
        end

        test "secret_matches? returns false for blank values" do
          assert_not @controller.send(:secret_matches?, "", "provided")
          assert_not @controller.send(:secret_matches?, "expected", "")
        end

        test "secret_matches? returns true for equal values" do
          assert @controller.send(:secret_matches?, "same-length", "same-length")
        end
      end
    end
  end
end
