class Claim < ApplicationRecord
  enum :status, { pending: "PENDING", approved: "APPROVED", rejected: "REJECTED" }

  belongs_to :pair
  belongs_to :claimant, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :category

  validates :expense_date, presence: true
  validates :amount, presence: true,
                      numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9_999_999 }
  validates :description, presence: true, length: { maximum: 100 }
  validates :rejection_reason, length: { maximum: 100 }, allow_blank: true

  validate :expense_date_not_in_future

  private

  def expense_date_not_in_future
    return if expense_date.blank?

    errors.add(:expense_date, "は未来日を指定できません") if expense_date > Date.current
  end
end
