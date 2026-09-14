require "test_helper"

class InvitationServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(display_name: "自分", email: "#{SecureRandom.hex(6)}@example.com", password: "password123")
    @pair = Pair.create!(pair_name: "テストペア", created_by: @user.id)
    PairMember.create!(pair: @pair, user: @user, joined_at: Time.current)
  end

  test "ペアが既に2人いる場合は発行できない" do
    other = User.create!(display_name: "相手", email: "#{SecureRandom.hex(6)}@example.com", password: "password123")
    PairMember.create!(pair: @pair, user: other, joined_at: Time.current)

    assert_raises(BusinessError) do
      InvitationService.issue(pair: @pair, issuer: @user)
    end
  end

  test "既にペアに所属している場合は参加できない" do
    invitation = InvitationService.issue(pair: @pair, issuer: @user)

    already_paired = User.create!(display_name: "別ペア所属", email: "#{SecureRandom.hex(6)}@example.com", password: "password123")
    other_pair = Pair.create!(pair_name: "別のペア", created_by: already_paired.id)
    PairMember.create!(pair: other_pair, user: already_paired, joined_at: Time.current)

    assert_raises(BusinessError) do
      InvitationService.join(user: already_paired, raw_code: invitation.invitation_code)
    end
  end

  test "期限切れのコードは使用できない" do
    invitation = InvitationService.issue(pair: @pair, issuer: @user)
    invitation.update!(expires_at: 1.hour.ago)

    new_user = User.create!(display_name: "新規", email: "#{SecureRandom.hex(6)}@example.com", password: "password123")

    assert_raises(BusinessError) do
      InvitationService.join(user: new_user, raw_code: invitation.invitation_code)
    end
    assert_equal "expired", invitation.reload.status
  end

  test "有効なコードで参加できる" do
    invitation = InvitationService.issue(pair: @pair, issuer: @user)
    new_user = User.create!(display_name: "新規", email: "#{SecureRandom.hex(6)}@example.com", password: "password123")

    InvitationService.join(user: new_user, raw_code: invitation.invitation_code)

    assert_equal 2, @pair.reload.members.count
    assert_equal "used", invitation.reload.status
  end
end
