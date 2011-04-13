class ApplicationController < ActionController::Base
  include Userstamp

  protect_from_forgery

  helper :all
  before_filter :authenticate_user!

  def require_admin_user
    if !user_signed_in? || !current_user.is_admin
      return redirect_to "/"
    end
  end


end
