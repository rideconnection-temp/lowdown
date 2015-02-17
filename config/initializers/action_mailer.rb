# Needed for sending new users' confirmation email
Lowdown::Application.config.action_mailer.default_url_options = { :host => APP_CONFIG[:mailer_host] }
