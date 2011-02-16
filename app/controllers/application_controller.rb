class ApplicationController < ActionController::Base
  include Userstamp

  protect_from_forgery

  helper :all
  helper_method :current_user_session, :current_user

  def current_user
    unless defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    return @current_user
  end

  private

  def current_user_session
    unless defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    return @current_user_session
  end
    
  def require_user
    if current_user
      if current_user.login_count == 1 && controller_name != 'users' 
        flash[:notice] = "Since this is your first time here, please change your password"
        redirect_to :controller=>'users', :action=>'show_change_password'
        return false
      end
      return current_user
    else
      session[:return_to] = request.request_uri
      flash[:notice] = "Please log in"
      redirect_to :controller=>'user_session', :action=>'new'
      return false
    end
  end

  def require_admin_user 
    if require_user
      if ! current_user.is_admin
        print "\n\naccess denied\n\n"
        flash[:notice] = "Access denied"
        redirect_to "/"
        return false
      end
    end
    return false
  end

  def bind(args)
    return ActiveRecord::Base.__send__(:sanitize_sql_for_conditions, args, '')
  end

end
