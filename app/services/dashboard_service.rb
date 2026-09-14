class DashboardService
  RECENT_CLAIM_COUNT = 5

  Result = Struct.new(
    :partner_display_name, :self_receivable_total, :partner_receivable_total,
    :payer_display_name, :payee_display_name, :payment_amount,
    :pending_for_me_count, :pending_for_partner_count,
    :recent_claims, :category_summary, :year_month_label,
    keyword_init: true
  ) do
    def settled_flat?
      payment_amount.to_i.zero?
    end
  end

  def self.build(user:)
    pair = user.pair
    partner = PairService.partner_for(pair: pair, user: user)

    month_start = Date.current.beginning_of_month
    month_end = Date.current.end_of_month

    self_total = pair.claims.where(claimant_id: user.id, status: :approved,
                                    expense_date: month_start..month_end).sum(:amount)
    partner_total = partner ? pair.claims.where(claimant_id: partner.id, status: :approved,
                                                 expense_date: month_start..month_end).sum(:amount) : 0

    payer_name = payee_name = nil
    payment_amount = 0
    if partner && self_total != partner_total
      if self_total > partner_total
        payer_name, payee_name, payment_amount = partner.display_name, user.display_name, self_total - partner_total
      else
        payer_name, payee_name, payment_amount = user.display_name, partner.display_name, partner_total - self_total
      end
    end

    pending_for_me = pair.claims.where(recipient_id: user.id, status: :pending).count
    pending_for_partner = partner ? pair.claims.where(recipient_id: partner.id, status: :pending).count : 0

    recent_claims = pair.claims.includes(:claimant, :recipient, :category)
                         .order(created_at: :desc).limit(RECENT_CLAIM_COUNT)

    amounts_by_category = pair.claims.where(status: :approved, expense_date: month_start..month_end)
                               .group(:category_id).sum(:amount)
    category_summary = Category.enabled.filter_map do |c|
      amount = amounts_by_category[c.id]
      [ c.category_name, amount ] if amount
    end

    Result.new(
      partner_display_name: partner&.display_name,
      self_receivable_total: self_total,
      partner_receivable_total: partner_total,
      payer_display_name: payer_name,
      payee_display_name: payee_name,
      payment_amount: payment_amount,
      pending_for_me_count: pending_for_me,
      pending_for_partner_count: pending_for_partner,
      recent_claims: recent_claims,
      category_summary: category_summary,
      year_month_label: "#{Date.current.year}年#{Date.current.month}月"
    )
  end
end
