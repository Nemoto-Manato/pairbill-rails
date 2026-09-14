class Pair < ApplicationRecord
  DEFAULT_NAME = "ふたりのグループ"

  belongs_to :creator, class_name: "User", foreign_key: :created_by

  has_many :pair_members, dependent: :destroy
  has_many :members, through: :pair_members, source: :user
  has_many :pair_invitations, dependent: :destroy
  has_many :claims, dependent: :destroy
  has_many :settlements, dependent: :destroy

  validates :pair_name, presence: true, length: { maximum: 50 }
end
