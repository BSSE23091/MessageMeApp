class ApplicationController < ActionController::Base
  # Make these methods available in views
  helper_method :current_user, :logged_in?

  # Returns the currently logged-in user (if any)
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Returns true if a user is logged in
  def logged_in?
    current_user.present?
  end

  # Redirects to login if user is not logged in
  def require_user
    unless logged_in?
      flash[:alert] = "You must log in to access this section"
      redirect_to login_path
    end
  end
end
