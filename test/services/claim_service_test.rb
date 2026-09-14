require "test_helper"

class ClaimServiceTest < ActiveSupport::TestCase
  setup do
    @category = Category.first || Category.create!(category_name: "食費", display_order: 1)
    @pair, @claimant, @recipient = create_pair!
  end

  def build_claim(overrides = {})
    @pair.claims.new({
      claimant_id: @claimant.id,
      recipient_id: @recipient.id,
      category_id: @category.id,
      expense_date: Date.current,
      amount: 1000,
      description: "テスト",
      status: "pending"
    }.merge(overrides))
  end

  test "自分自身を請求相手にできない" do
    claim = build_claim(recipient_id: @claimant.id)

    assert_raises(BusinessError) do
      ClaimService.register(claim: claim, claimant: @claimant, pair: @pair)
    end
  end

  test "対象月が精算済みの場合は登録できない" do
    Settlement.create!(
      pair: @pair, settlement_month: Date.current.beginning_of_month, requested_by: @claimant.id,
      payment_amount: 0, requester_receivable_total: 0, partner_receivable_total: 0,
      approved_claim_count: 1, status: "completed", requested_at: Time.current
    )
    claim = build_claim

    assert_raises(BusinessError) do
      ClaimService.register(claim: claim, claimant: @claimant, pair: @pair)
    end
  end

  test "請求相手以外は承認できない" do
    claim = build_claim.tap { |c| c.save!(validate: false) }

    assert_raises(ForbiddenError) do
      ClaimService.approve!(claim: claim, approver: @claimant)
    end
  end

  test "承認済みの請求は再承認できない" do
    claim = build_claim(status: "approved").tap { |c| c.save!(validate: false) }

    assert_raises(BusinessError) do
      ClaimService.approve!(claim: claim, approver: @recipient)
    end
  end

  test "請求者本人以外は編集できない" do
    claim = build_claim.tap { |c| c.save!(validate: false) }

    assert_raises(ForbiddenError) do
      ClaimService.verify_editable!(claim: claim, editor: @recipient)
    end
  end
end
