class DeliveryMailer < ApplicationMailer
  def signature_request(delivery, user, role)
    return if user.blank? || user.email.blank?

    @delivery = delivery
    @user = user
    @role = role
    mail(to: user.email, subject: t("mailers.delivery.signature_request.subject", default: "Signature requested for case #{delivery.case_number}"))
  end

  def signature_added_notification(delivery, role)
    @delivery = delivery
    @role = role
    recipients = recipients_for(delivery)
    return if recipients.empty?

    mail(to: recipients, subject: t("mailers.delivery.signature_added.subject", default: "#{role.titleize} signed case #{delivery.case_number}"))
  end

  def delivery_completed(delivery)
    @delivery = delivery
    recipients = recipients_for(delivery)
    return if recipients.empty?

    mail(to: recipients, subject: t("mailers.delivery.completed.subject", default: "Delivery #{delivery.case_number} completed"))
  end

  private

  def recipients_for(delivery)
    [ delivery.sender&.email, delivery.courier&.email, delivery.recipient&.email ].compact.uniq
  end
end
