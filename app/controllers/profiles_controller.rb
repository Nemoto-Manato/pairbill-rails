class ProfilesController < ApplicationController
  skip_before_action :require_pair

  def edit
  end

  def update
    if current_user.update(display_name: params[:display_name])
      redirect_to "/settings/profile", notice: "表示名を更新しました。"
    else
      flash.now[:error_message] = current_user.errors.full_messages.join("、")
      render :edit, status: :unprocessable_entity
    end
  end
end
