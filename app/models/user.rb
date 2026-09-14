class User < ApplicationRecord
  has_secure_password

  has_one :pair_member, dependent: :destroy
  has_one :pair, through: :pair_member
  has_many :notifications, dependent: :destroy

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                     format: { with: URI::MailTo::EMAIL_REGEXP },
                     uniqueness: { case_sensitive: false }
  validates :password, length: { in: 8..72 }, if: -> { password.present? }
end
