class SettlementsController < ApplicationController
  def index
    @months = SettlementService.list_months(pair: current_pair)
  end

  def show
    @detail = SettlementService.get_month_detail(pair: current_pair, viewer: current_user, year_month: params[:year_month])
  end

  def request_settlement
    SettlementService.request_settlement(pair: current_pair, requester: current_user, year_month: params[:year_month])
    redirect_to settlement_month_path(params[:year_month])
  end

  def approve
    settlement = find_settlement
    SettlementService.approve(settlement: settlement, approver: current_user)
    redirect_to settlement_month_path(settlement.settlement_month.strftime("%Y-%m"))
  end

  def cancel
    settlement = find_settlement
    SettlementService.cancel(settlement: settlement, user: current_user)
    redirect_to settlement_month_path(settlement.settlement_month.strftime("%Y-%m"))
  end

  private

  def find_settlement
    settlement = Settlement.find(params[:id])
    PairService.verify_member!(pair: settlement.pair, user: current_user)
    settlement
  end
end
