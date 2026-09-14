class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def mark_read
    notification = Notification.find(params[:id])
    raise ForbiddenError, "この通知を閲覧する権限がありません。" unless notification.user_id == current_user.id

    notification.update!(read: true, read_at: Time.current) unless notification.read?

    if notification.related_claim_id
      redirect_to claim_path(notification.related_claim_id)
    elsif notification.related_settlement_id
      settlement = Settlement.find(notification.related_settlement_id)
      redirect_to settlement_month_path(settlement.settlement_month.strftime("%Y-%m"))
    else
      redirect_to notifications_path
    end
  end
end
