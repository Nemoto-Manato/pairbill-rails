class ClaimsController < ApplicationController
  before_action :set_claim, only: [ :show, :edit, :update, :destroy, :approve, :reject ]

  def index
    @categories = Category.enabled
    @year_month = params[:year_month].presence || Date.current.strftime("%Y-%m")
    @direction = params[:direction]
    @status = params[:status]
    @category_id = params[:category_id]
    @result = ClaimService.search(
      pair: current_pair, viewer: current_user, direction: @direction,
      year_month: @year_month, status: @status, category_id: @category_id,
      page: params[:page] || 1
    )
  end

  def new
    @partner = PairService.partner_for(pair: current_pair, user: current_user)
    @claim = current_pair.claims.new(recipient_id: @partner&.id)
    @categories = Category.enabled
  end

  def create
    @partner = PairService.partner_for(pair: current_pair, user: current_user)
    @claim = current_pair.claims.new(claim_params)
    @claim.claimant_id = current_user.id
    @claim.status = "pending"

    if @claim.valid?
      ClaimService.register(claim: @claim, claimant: current_user, pair: current_pair)
      redirect_to claim_path(@claim)
    else
      @categories = Category.enabled
      render :new, status: :unprocessable_entity
    end
  end

  def show
    PairService.verify_member!(pair: @claim.pair, user: current_user)
  end

  def edit
    ClaimService.verify_editable!(claim: @claim, editor: current_user)
    @categories = Category.enabled
  end

  def update
    ClaimService.verify_editable!(claim: @claim, editor: current_user)
    @claim.assign_attributes(claim_params)

    if @claim.valid?
      ClaimService.update!(claim: @claim)
      redirect_to claim_path(@claim)
    else
      @categories = Category.enabled
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ClaimService.destroy!(claim: @claim, editor: current_user)
    redirect_to claims_path
  end

  def approve
    ClaimService.approve!(claim: @claim, approver: current_user)
    redirect_to claim_path(@claim)
  end

  def reject
    ClaimService.reject!(claim: @claim, approver: current_user, reason: params[:rejection_reason])
    redirect_to claim_path(@claim)
  end

  private

  def set_claim
    @claim = Claim.find(params[:id])
    PairService.verify_member!(pair: @claim.pair, user: current_user)
  end

  def claim_params
    params.require(:claim).permit(:expense_date, :recipient_id, :amount, :category_id, :description)
  end
end
