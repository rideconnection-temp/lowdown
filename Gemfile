source 'http://rubygems.org'

gem 'rails', '3.0.10'
gem 'pg'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3-ruby', :require => 'sqlite3'
gem "devise"
gem 'dynamic_form', :git => 'git://github.com/rails/dynamic_form.git'
gem 'will_paginate', '~> 3.0'
gem 'userstamp'
gem 'validates_timeliness'
gem 'jquery-rails', '>= 1.0.12'
gem 'csv_builder'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

group :production do
  gem 'exception_notification',
      :git => "git://github.com/rails/exception_notification.git",
      :require => "exception_notifier"
end

group :test, :development do
  gem 'ruby-debug19'
  gem "rspec-rails"
  gem "capybara"
  gem "fixjour"
  gem "faker"
  gem 'automatic_foreign_key'
end
