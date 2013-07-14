if Rails.env.production?
  #Exception Notification
  Whatever::Application.config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => APP_CONFIG[:exception_email_prefix],
      :sender_address => APP_CONFIG[:exception_sender_address],
      :exception_recipients => APP_CONFIG[:exception_recipients]
    }
end
