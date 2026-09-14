class NotificationService
  def self.notify(user_id:, type:, title:, message:, claim: nil, settlement: nil)
    Notification.create!(
      user_id: user_id,
      notification_type: type,
      title: title,
      message: message,
      related_claim_id: claim&.id,
      related_settlement_id: settlement&.id,
      read: false
    )
  end
end
