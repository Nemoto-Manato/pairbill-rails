class ClaimService
  PAGE_SIZE = 20

  Result = Struct.new(:items, :total_count, :page, :page_size) do
    def total_pages
      [ (total_count.to_f / page_size).ceil, 1 ].max
    end

    def has_previous?
      page > 1
    end

    def has_next?
      page < total_pages
    end
  end

  def self.search(pair:, viewer:, direction:, year_month:, status:, category_id:, page:)
    scope = pair.claims.includes(:claimant, :recipient, :category)
    scope = scope.where(claimant_id: viewer.id) if direction == "SENT"
    scope = scope.where(recipient_id: viewer.id) if direction == "RECEIVED"

    if year_month.present?
      begin
        month_start = Date.strptime(year_month, "%Y-%m")
        scope = scope.where(expense_date: month_start.beginning_of_month..month_start.end_of_month)
      rescue ArgumentError
        nil
      end
    end

    scope = scope.where(status: status) if status.present?
    scope = scope.where(category_id: category_id) if category_id.present?

    total = scope.count
    page = [ page.to_i, 1 ].max
    items = scope.order(expense_date: :desc, id: :desc).offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
    Result.new(items.to_a, total, page, PAGE_SIZE)
  end

  def self.register(claim:, claimant:, pair:)
    partner = PairService.partner_for(pair: pair, user: claimant)
    raise BusinessError, "相手がまだペアに参加していないため、請求を登録できません。" if partner.nil?
    raise BusinessError, "自分自身を請求相手に指定することはできません。" if claim.recipient_id == claimant.id
    raise ForbiddenError, "請求相手が不正です。" unless partner.id == claim.recipient_id

    assert_month_not_locked!(pair, claim.expense_date)
    claim.save!

    NotificationService.notify(
      user_id: partner.id, type: :claim_created, title: "新しい請求が届きました",
      message: "#{claimant.display_name}さんから#{format_amount(claim.amount)}円の請求が届きました。",
      claim: claim
    )
    claim
  end

  def self.verify_editable!(claim:, editor:)
    raise ForbiddenError, "請求者本人のみ編集できます。" unless claim.claimant_id == editor.id
    raise BusinessError, "承認待ちの請求のみ編集できます。" unless claim.pending?
    assert_month_not_locked!(claim.pair, claim.expense_date)
  end

  def self.update!(claim:)
    assert_month_not_locked!(claim.pair, claim.expense_date)
    claim.save!
  end

  def self.destroy!(claim:, editor:)
    raise ForbiddenError, "請求者本人のみ削除できます。" unless claim.claimant_id == editor.id
    raise BusinessError, "承認待ちの請求のみ削除できます。" unless claim.pending?
    assert_month_not_locked!(claim.pair, claim.expense_date)
    claim.destroy!
  end

  def self.approve!(claim:, approver:)
    raise ForbiddenError, "請求相手のみ承認できます。" unless claim.recipient_id == approver.id
    raise BusinessError, "既に処理済みの請求です。" unless claim.pending?
    assert_month_not_locked!(claim.pair, claim.expense_date)

    claim.update!(status: "approved", responded_at: Time.current)
    NotificationService.notify(
      user_id: claim.claimant_id, type: :claim_approved, title: "請求が承認されました",
      message: "#{approver.display_name}さんが#{format_amount(claim.amount)}円の請求を承認しました。",
      claim: claim
    )
    claim
  end

  def self.reject!(claim:, approver:, reason:)
    raise ForbiddenError, "請求相手のみ却下できます。" unless claim.recipient_id == approver.id
    raise BusinessError, "既に処理済みの請求です。" unless claim.pending?
    assert_month_not_locked!(claim.pair, claim.expense_date)

    claim.update!(status: "rejected", rejection_reason: reason, responded_at: Time.current)
    NotificationService.notify(
      user_id: claim.claimant_id, type: :claim_rejected, title: "請求が却下されました",
      message: "#{approver.display_name}さんが#{format_amount(claim.amount)}円の請求を却下しました。",
      claim: claim
    )
    claim
  end

  def self.assert_month_not_locked!(pair, expense_date)
    month_start = expense_date.beginning_of_month
    locked = Settlement.where(pair_id: pair.id, settlement_month: month_start,
                               status: [ :pending_approval, :completed ]).exists?
    raise BusinessError, "対象月は精算申請中または精算済みのため、請求を変更できません。" if locked
  end

  def self.format_amount(amount)
    ActiveSupport::NumberHelper.number_to_delimited(amount)
  end
end
