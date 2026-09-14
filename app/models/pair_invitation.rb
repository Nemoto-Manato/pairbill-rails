class PairInvitation < ApplicationRecord
  enum :status, { active: "ACTIVE", used: "USED", expired: "EXPIRED", cancelled: "CANCELLED" }

  belongs_to :pair
  belongs_to :issuer, class_name: "User", foreign_key: :issued_by
  belongs_to :used_by_user, class_name: "User", foreign_key: :used_by, optional: true

  validates :invitation_code, presence: true, uniqueness: true, length: { maximum: 20 }

  def expired_by_time?
    active? && expires_at.present? && expires_at.past?
  end
end
