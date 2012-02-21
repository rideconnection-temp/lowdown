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

  def test_exception_notification
      raise 'Testing, 1 2 3.'
  end

  private 

  def render_csv(file_name, template_name = nil)
    headers["Content-Type"] ||= 'text/csv'
    headers["Content-Disposition"] = "attachment; filename=\"#{file_name}.csv\"" 
    if template_name.nil?
      render :layout => false
    else
      render template_name, :layout => false
    end
  end
end
