class PairService
  def self.create_pair(user:, pair_name:)
    raise BusinessError, "既にペアに所属しています。" if user.pair_member.present?

    pair = nil
    ActiveRecord::Base.transaction do
      pair = Pair.create!(pair_name: pair_name.presence || Pair::DEFAULT_NAME, created_by: user.id)
      PairMember.create!(pair: pair, user: user, joined_at: Time.current)
    end
    pair
  end

  def self.partner_for(pair:, user:)
    return nil if pair.nil?

    pair.members.where.not(id: user.id).first
  end

  def self.verify_member!(pair:, user:)
    return if pair && PairMember.exists?(pair_id: pair.id, user_id: user.id)

    raise ForbiddenError, "このペアのメンバーではありません。"
  end
end
