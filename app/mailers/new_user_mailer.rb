class NewUserMailer < ActionMailer::Base

  def new_user_email(user)
    @user = user
    @url = root_url
    mail(to: user.email, from: EMAIL_FROM, subject: "Welcome to the Service Database")
  end

end
