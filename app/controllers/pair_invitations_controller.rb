class PairInvitationsController < ApplicationController
  skip_before_action :require_pair
  before_action :redirect_to_setup_unless_paired, except: [ :join ]

  def index
    @pair = current_pair
    @partner = PairService.partner_for(pair: @pair, user: current_user)
    @invitations = InvitationService.list_for(pair: @pair)
    @can_issue = @pair.members.count < 2
  end

  def create
    InvitationService.issue(pair: current_pair, issuer: current_user)
    redirect_to "/pair/invitation"
  end

  def join
    InvitationService.join(user: current_user, raw_code: params[:invitation_code])
    redirect_to "/dashboard"
  end

  def cancel
    invitation = PairInvitation.find(params[:id])
    InvitationService.cancel(invitation: invitation, user: current_user)
    redirect_to "/pair/invitation"
  end

  private

  def redirect_to_setup_unless_paired
    redirect_to "/pair/setup" if current_pair.blank?
  end
end
