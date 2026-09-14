class Category < ApplicationRecord
  has_many :claims

  validates :category_name, presence: true, uniqueness: true, length: { maximum: 30 }
  validates :display_order, presence: true

  scope :enabled, -> { where(enabled: true).order(:display_order) }
end
