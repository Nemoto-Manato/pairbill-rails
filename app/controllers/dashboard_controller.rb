class DashboardController < ApplicationController
  def show
    @dashboard = DashboardService.build(user: current_user)
  end
end
