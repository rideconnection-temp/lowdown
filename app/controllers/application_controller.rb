class ApplicationController < ActionController::Base
  include Userstamp

  protect_from_forgery

  helper :all
  before_filter :authenticate_user!, :allow_active_users_only, :set_cache_buster

  def test_exception_notification
    raise 'Testing, 1 2 3.'
  end

  private 

  def has_real_changes?(record)
    record.changes.values.each {|change| return true unless (change[0].blank? && change[1].blank?) || change[0] == change[1] }
    return false
  end

  def require_admin_user
    if !user_signed_in? || !current_user.is_admin
      return redirect_to root_url
    end
  end

  def allow_active_users_only
    if user_signed_in? && !current_user.active?
      scope = Devise::Mapping.find_scope!(current_user)
      current_user = nil
      warden.logout(scope)

      return redirect_to root_url
    end
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
