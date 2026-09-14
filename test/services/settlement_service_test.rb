require "test_helper"

class SettlementServiceTest < ActiveSupport::TestCase
  setup do
    @category = Category.first || Category.create!(category_name: "食費", display_order: 1)
    @pair, @user_a, @user_b = create_pair!
  end

  def approved_claim!(claimant:, recipient:, amount:)
    @pair.claims.create!(
      claimant_id: claimant.id, recipient_id: recipient.id, category_id: @category.id,
      expense_date: Date.current, amount: amount, description: "テスト", status: "approved",
      responded_at: Time.current
    )
  end

  test "差額を正しく計算する（20000と12000なら8000円）" do
    approved_claim!(claimant: @user_a, recipient: @user_b, amount: 20_000)
    approved_claim!(claimant: @user_b, recipient: @user_a, amount: 12_000)

    settlement = SettlementService.request_settlement(pair: @pair, requester: @user_a,
                                                        year_month: Date.current.strftime("%Y-%m"))

    assert_equal @user_b.id, settlement.payer_id
    assert_equal @user_a.id, settlement.payee_id
    assert_equal 8_000, settlement.payment_amount
  end

  test "双方同額の場合は支払額ゼロ" do
    approved_claim!(claimant: @user_a, recipient: @user_b, amount: 10_000)
    approved_claim!(claimant: @user_b, recipient: @user_a, amount: 10_000)

    settlement = SettlementService.request_settlement(pair: @pair, requester: @user_a,
                                                        year_month: Date.current.strftime("%Y-%m"))

    assert_equal 0, settlement.payment_amount
    assert_nil settlement.payer_id
  end

  test "承認待ちの請求がある場合は申請できない" do
    approved_claim!(claimant: @user_a, recipient: @user_b, amount: 5_000)
    @pair.claims.create!(
      claimant_id: @user_a.id, recipient_id: @user_b.id, category_id: @category.id,
      expense_date: Date.current, amount: 1_000, description: "承認待ち", status: "pending"
    )

    assert_raises(BusinessError) do
      SettlementService.request_settlement(pair: @pair, requester: @user_a,
                                            year_month: Date.current.strftime("%Y-%m"))
    end
  end

  test "申請者本人は承認できない" do
    approved_claim!(claimant: @user_a, recipient: @user_b, amount: 5_000)
    settlement = SettlementService.request_settlement(pair: @pair, requester: @user_a,
                                                        year_month: Date.current.strftime("%Y-%m"))

    assert_raises(ForbiddenError) do
      SettlementService.approve(settlement: settlement, approver: @user_a)
    end
  end
end
