if Rails.env.production? || true
  #Exception Notification
  Lowdown::Application.config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => APP_CONFIG[:exception_email_prefix],
      :sender_address => APP_CONFIG[:exception_sender_address],
      :exception_recipients => APP_CONFIG[:exception_recipients]
    }
end
