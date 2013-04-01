class ApplicationController < ActionController::Base
  include Userstamp

  protect_from_forgery

  helper :all
  before_filter :authenticate_user!

  def require_admin_user
    if !user_signed_in? || !current_user.is_admin
      return redirect_to root_url
    end
  end

  def test_exception_notification
    raise 'Testing, 1 2 3.'
  end

  private 

  def has_real_changes?(record)
    record.changes.values.each {|change| return true unless change[0].blank? && change[1].blank? }
    return false
  end
end
