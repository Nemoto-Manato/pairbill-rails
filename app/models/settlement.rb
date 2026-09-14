class Settlement < ApplicationRecord
  enum :status, { pending_approval: "PENDING_APPROVAL", completed: "COMPLETED", cancelled: "CANCELLED" }

  belongs_to :pair
  belongs_to :requester, class_name: "User", foreign_key: :requested_by
  belongs_to :payer, class_name: "User", optional: true
  belongs_to :payee, class_name: "User", optional: true
  belongs_to :approver, class_name: "User", foreign_key: :approved_by, optional: true

  def settled_flat?
    payment_amount.to_i.zero?
  end
end
