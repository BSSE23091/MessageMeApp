class UsersController < ApplicationController
  before_action :require_user, only: [:index, :show] # protect certain actions if needed

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to chatroom_path, notice: "Welcome, #{@user.username}!"
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
