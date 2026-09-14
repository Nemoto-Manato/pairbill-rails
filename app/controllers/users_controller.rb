class UsersController < ApplicationController
  skip_before_action :require_login
  skip_before_action :require_pair

  def new
    @user = User.new
  end

  def create
    if params[:user][:password] != params[:user][:password_confirmation]
      @user = User.new(display_name: params[:user][:display_name], email: params[:user][:email])
      @user.errors.add(:password_confirmation, "がパスワードと一致しません")
      render :new, status: :unprocessable_entity
      return
    end

    @user = User.new(user_params)
    if @user.save
      redirect_to login_path, notice: "会員登録が完了しました。ログインしてください。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:display_name, :email, :password).tap do |p|
      p[:email] = p[:email]&.downcase
    end
  end
end
