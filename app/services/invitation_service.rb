class InvitationService
  CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
  CODE_LENGTH = 8
  EXPIRY_HOURS = 24

  def self.issue(pair:, issuer:)
    if pair.members.count >= 2
      raise BusinessError, "ペアは既に2人参加しているため、招待コードを発行できません。"
    end

    PairInvitation.create!(
      pair: pair,
      invitation_code: generate_unique_code,
      issued_by: issuer.id,
      status: "active",
      expires_at: EXPIRY_HOURS.hours.from_now
    )
  end

  def self.cancel(invitation:, user:)
    raise BusinessError, "招待コードが見つかりません。" if invitation.nil?
    raise BusinessError, "自分が発行した招待コードのみ取り消せます。" unless invitation.issued_by == user.id
    raise BusinessError, "この招待コードは既に利用できない状態です。" unless invitation.active?

    invitation.update!(status: "cancelled")
  end

  # 招待コードを入力してペアへ参加する。
  # 同時参加による3人目の登録を防ぐため、ペア行をロックしたうえでメンバー数を再確認する。
  def self.join(user:, raw_code:)
    if user.pair_member.present?
      raise BusinessError, "既にペアに所属しているため、別のペアへ参加できません。"
    end

    code = raw_code.to_s.strip.upcase
    invitation = PairInvitation.find_by(invitation_code: code)
    raise BusinessError, "招待コードが正しくありません。" if invitation.nil?

    invitation.update!(status: "expired") if invitation.expired_by_time?
    unless invitation.active?
      raise BusinessError, "この招待コードは使用済み、期限切れ、または取消済みです。"
    end

    pair = nil
    ActiveRecord::Base.transaction do
      pair = Pair.lock.find(invitation.pair_id)
      raise BusinessError, "このペアは既に2人参加しています。" if pair.members.count >= 2

      PairMember.create!(pair: pair, user: user, joined_at: Time.current)
      invitation.update!(status: "used", used_by: user.id, used_at: Time.current)
    end
    pair
  end

  def self.list_for(pair:)
    pair.pair_invitations.order(created_at: :desc)
  end

  def self.generate_unique_code
    20.times do
      candidate = Array.new(CODE_LENGTH) { CODE_CHARS[SecureRandom.random_number(CODE_CHARS.length)] }.join
      return candidate unless PairInvitation.exists?(invitation_code: candidate)
    end
    raise "招待コードの生成に失敗しました。時間をおいて再度お試しください。"
  end
end
