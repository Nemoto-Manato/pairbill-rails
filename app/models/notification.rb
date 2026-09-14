class Notification < ApplicationRecord
  enum :notification_type, {
    claim_created: "CLAIM_CREATED",
    claim_approved: "CLAIM_APPROVED",
    claim_rejected: "CLAIM_REJECTED",
    settlement_requested: "SETTLEMENT_REQUESTED",
    settlement_completed: "SETTLEMENT_COMPLETED"
  }

  belongs_to :user
  belongs_to :claim, foreign_key: :related_claim_id, optional: true
  belongs_to :settlement, foreign_key: :related_settlement_id, optional: true
end
