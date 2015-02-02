class NewUserMailer < ActionMailer::Base
  default from: EMAIL_FROM

  def new_user_email(user)
    @user = user
    @url = root_url
    mail(to: user.email,  subject: "Welcome to the Service Database")
  end

end
