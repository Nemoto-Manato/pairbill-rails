class PairMember < ApplicationRecord
  belongs_to :pair
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :pair_id, uniqueness: { scope: :user_id }
end
