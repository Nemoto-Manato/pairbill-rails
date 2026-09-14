class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login
  before_action :require_pair
  helper_method :current_user, :logged_in?, :current_pair, :unread_notification_count

  rescue_from BusinessError, with: :handle_business_error
  rescue_from ForbiddenError, with: :handle_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path
  end

  # ペア未所属のユーザーが請求・精算・通知などの画面へアクセスした場合、ペア設定画面へ誘導する。
  def require_pair
    return unless logged_in?
    return if current_pair.present?
    return if pair_setup_exempt?

    redirect_to "/pair/setup"
  end

  def pair_setup_exempt?
    controller_name.in?(%w[pairs pair_invitations profiles sessions users])
  end

  def current_pair
    current_user&.pair
  end

  def unread_notification_count
    return nil unless logged_in?

    current_user.notifications.where(read: false).count
  end

  def handle_business_error(exception)
    flash[:error_message] = exception.message
    redirect_back fallback_location: "/dashboard"
  end

  def handle_forbidden(exception)
    Rails.logger.warn("403 Forbidden: uri=#{request.path}, message=#{exception.message}")
    render "errors/forbidden", status: :forbidden
  end

  def handle_not_found(exception)
    Rails.logger.info("404 Not Found: uri=#{request.path}, message=#{exception.message}")
    render "errors/not_found", status: :not_found
  end
end
