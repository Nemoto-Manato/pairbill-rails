class SettlementService
  STATUS_LABELS = {
    "pending_approval" => "精算承認待ち",
    "completed" => "精算済み",
    "cancelled" => "取消済み",
    "unsettled" => "未精算"
  }.freeze

  SummaryResult = Struct.new(:year_month_value, :year_month_label, :status, :status_label, keyword_init: true)

  DetailResult = Struct.new(
    :year_month_value, :year_month_label, :settlement_id, :status, :status_label,
    :self_display_name, :self_receivable_total, :partner_display_name, :partner_receivable_total,
    :payer_display_name, :payee_display_name, :payment_amount, :approved_claim_count,
    :requested_by_display_name, :requested_at, :approved_by_display_name, :completed_at, :cancelled_at,
    :can_request, :can_approve, :can_cancel,
    keyword_init: true
  ) do
    def settled_flat?
      payment_amount.to_i.zero?
    end
  end

  def self.list_months(pair:)
    claim_months = pair.claims.distinct.pluck(:expense_date).map(&:beginning_of_month)
    settlement_months = pair.settlements.pluck(:settlement_month)
    months = (claim_months + settlement_months).uniq.sort.reverse

    months.map do |month|
      active = active_settlement(pair, month)
      status = active ? active.status : "unsettled"
      SummaryResult.new(
        year_month_value: month.strftime("%Y-%m"),
        year_month_label: "#{month.year}年#{month.month}月",
        status: status,
        status_label: STATUS_LABELS[status]
      )
    end
  end

  def self.get_month_detail(pair:, viewer:, year_month:)
    partner = PairService.partner_for(pair: pair, user: viewer)
    month_start = Date.strptime(year_month, "%Y-%m").beginning_of_month
    month_end = month_start.end_of_month
    active = active_settlement(pair, month_start)

    if active
      build_detail_from_settlement(active, viewer, partner, year_month, month_start)
    else
      build_live_detail(pair, viewer, partner, year_month, month_start, month_end)
    end
  end

  # 精算申請時は、対象月の承認待ち件数を再確認したうえで集計し、精算レコードを保存する。
  # ペア行をロックして、同一対象月への二重申請を防止する。
  def self.request_settlement(pair:, requester:, year_month:)
    month_start = Date.strptime(year_month, "%Y-%m").beginning_of_month
    month_end = month_start.end_of_month

    settlement = nil
    ActiveRecord::Base.transaction do
      locked_pair = Pair.lock.find(pair.id)

      if active_settlement(locked_pair, month_start)
        raise BusinessError, "この対象月は既に精算申請中または精算済みです。"
      end

      partner = PairService.partner_for(pair: locked_pair, user: requester)
      raise BusinessError, "相手がまだペアに参加していないため精算できません。" if partner.nil?

      pending_count = locked_pair.claims.where(status: :pending, expense_date: month_start..month_end).count
      raise BusinessError, "承認待ちの請求があるため精算できません。" if pending_count.positive?

      requester_total = locked_pair.claims.where(claimant_id: requester.id, status: :approved,
                                                   expense_date: month_start..month_end).sum(:amount)
      partner_total = locked_pair.claims.where(claimant_id: partner.id, status: :approved,
                                                expense_date: month_start..month_end).sum(:amount)
      approved_count = locked_pair.claims.where(status: :approved, expense_date: month_start..month_end).count
      raise BusinessError, "承認済みの請求がないため精算できません。" if approved_count.zero?

      payer_id = payee_id = nil
      payment_amount = 0
      if requester_total > partner_total
        payer_id, payee_id, payment_amount = partner.id, requester.id, requester_total - partner_total
      elsif requester_total < partner_total
        payer_id, payee_id, payment_amount = requester.id, partner.id, partner_total - requester_total
      end

      settlement = Settlement.create!(
        pair: locked_pair, settlement_month: month_start, requested_by: requester.id,
        payer_id: payer_id, payee_id: payee_id, payment_amount: payment_amount,
        requester_receivable_total: requester_total, partner_receivable_total: partner_total,
        approved_claim_count: approved_count, status: "pending_approval", requested_at: Time.current
      )

      NotificationService.notify(
        user_id: partner.id, type: :settlement_requested, title: "精算の承認をお願いします",
        message: "#{requester.display_name}さんが#{month_start.year}年#{month_start.month}月の精算を申請しました。",
        settlement: settlement
      )
    end
    settlement
  end

  def self.approve(settlement:, approver:)
    raise BusinessError, "この精算は既に処理されています。" unless settlement.pending_approval?
    raise ForbiddenError, "申請者本人は精算を承認できません。" if settlement.requested_by == approver.id

    settlement.update!(status: "completed", approved_by: approver.id, completed_at: Time.current)
    NotificationService.notify(
      user_id: settlement.requested_by, type: :settlement_completed, title: "精算が完了しました",
      message: "#{approver.display_name}さんが精算を承認し、対象月が確定しました。", settlement: settlement
    )
    settlement
  end

  def self.cancel(settlement:, user:)
    raise BusinessError, "この精算は既に処理されています。" unless settlement.pending_approval?
    raise ForbiddenError, "申請者本人のみ取り消せます。" unless settlement.requested_by == user.id

    settlement.update!(status: "cancelled", cancelled_at: Time.current)
    settlement
  end

  def self.active_settlement(pair, month_start)
    pair.settlements.where(settlement_month: month_start, status: [ :pending_approval, :completed ]).first
  end
  private_class_method :active_settlement

  def self.build_detail_from_settlement(active, viewer, partner, year_month, month_start)
    viewer_is_requester = active.requested_by == viewer.id
    self_total = viewer_is_requester ? active.requester_receivable_total : active.partner_receivable_total
    partner_total = viewer_is_requester ? active.partner_receivable_total : active.requester_receivable_total

    DetailResult.new(
      year_month_value: year_month,
      year_month_label: "#{month_start.year}年#{month_start.month}月",
      settlement_id: active.id,
      status: active.status,
      status_label: STATUS_LABELS[active.status],
      self_display_name: viewer.display_name,
      self_receivable_total: self_total,
      partner_display_name: partner&.display_name,
      partner_receivable_total: partner_total,
      payer_display_name: resolve_name(active.payer_id, viewer, partner),
      payee_display_name: resolve_name(active.payee_id, viewer, partner),
      payment_amount: active.payment_amount,
      approved_claim_count: active.approved_claim_count,
      requested_by_display_name: viewer_is_requester ? viewer.display_name : partner&.display_name,
      requested_at: active.requested_at,
      approved_by_display_name: resolve_name(active.approved_by, viewer, partner),
      completed_at: active.completed_at,
      cancelled_at: active.cancelled_at,
      can_request: false,
      can_approve: active.pending_approval? && !viewer_is_requester,
      can_cancel: active.pending_approval? && viewer_is_requester
    )
  end
  private_class_method :build_detail_from_settlement

  def self.build_live_detail(pair, viewer, partner, year_month, month_start, month_end)
    self_total = pair.claims.where(claimant_id: viewer.id, status: :approved,
                                    expense_date: month_start..month_end).sum(:amount)
    partner_total = partner ? pair.claims.where(claimant_id: partner.id, status: :approved,
                                                 expense_date: month_start..month_end).sum(:amount) : 0
    approved_count = pair.claims.where(status: :approved, expense_date: month_start..month_end).count
    pending_count = pair.claims.where(status: :pending, expense_date: month_start..month_end).count

    payer_name = payee_name = nil
    payment_amount = 0
    if partner && self_total != partner_total
      if self_total > partner_total
        payer_name, payee_name, payment_amount = partner.display_name, viewer.display_name, self_total - partner_total
      else
        payer_name, payee_name, payment_amount = viewer.display_name, partner.display_name, partner_total - self_total
      end
    end

    DetailResult.new(
      year_month_value: year_month,
      year_month_label: "#{month_start.year}年#{month_start.month}月",
      settlement_id: nil,
      status: "unsettled",
      status_label: STATUS_LABELS["unsettled"],
      self_display_name: viewer.display_name,
      self_receivable_total: self_total,
      partner_display_name: partner&.display_name,
      partner_receivable_total: partner_total,
      payer_display_name: payer_name,
      payee_display_name: payee_name,
      payment_amount: payment_amount,
      approved_claim_count: approved_count,
      can_request: partner.present? && pending_count.zero? && approved_count >= 1,
      can_approve: false,
      can_cancel: false
    )
  end
  private_class_method :build_live_detail

  def self.resolve_name(user_id, viewer, partner)
    return nil if user_id.nil?
    return viewer.display_name if user_id == viewer.id
    return partner.display_name if partner && user_id == partner.id

    User.find(user_id).display_name
  end
  private_class_method :resolve_name
end
