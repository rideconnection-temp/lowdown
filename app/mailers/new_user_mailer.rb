class NewUserMailer < ActionMailer::Base
  default :from => "novalis@openplans.org"


  def new_user_email(user, password)
    @user = user
    @password = password
    @url = root_url
    mail(:to => user.email,  :subject => "Welcome to Lowdown")
 end


end
