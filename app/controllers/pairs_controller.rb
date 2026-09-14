class PairsController < ApplicationController
  skip_before_action :require_pair

  def setup
    redirect_to("/pair/invitation") and return if current_pair.present?
  end

  def create
    PairService.create_pair(user: current_user, pair_name: params[:pair_name])
    redirect_to "/pair/invitation"
  end
end
