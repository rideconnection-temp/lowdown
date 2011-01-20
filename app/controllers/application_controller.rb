class ApplicationController < ActionController::Base
  protect_from_forgery

  helper :all
  helper_method :current_user_session, :current_user

  private

  def current_user_session
    unless defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    return @current_user_session
  end


  def current_user
    unless defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    return @current_user
  end
    
  def require_user
    unless current_user
      session[:return_to] = request.request_uri
      flash[:notice] = "Please log in"
      redirect_to :controller=>'user_session', :action=>'new'
      return false
    end
  end
 
end
