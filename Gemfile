source 'http://rubygems.org'

gem 'rails', '~> 4.2.0'
gem 'pg'

gem 'jquery-ui-rails'
gem 'devise'
gem 'dynamic_form'
gem 'will_paginate'
# Using userstamp from git for now, because 2.0.2 (Rails 3.2 compatible) has
# not been uploaded to rubygems as of this writing.
gem "userstamp",
  :git => "https://github.com/delynn/userstamp.git",
  :ref => "777633a"
gem 'validates_timeliness'
gem 'csv_builder'
gem 'point_in_time',        :git => 'https://github.com/rideconnection/point_in_time'

# Deploy with Capistrano
gem "capistrano",     :require => false # We need it to be installed, but it's
gem "capistrano-ext", :require => false # not a runtime dependency
gem "rvm-capistrano", :require => false

group :production do
  gem 'exception_notification'
end

group :development do
  gem 'thin'
end

group :test, :development do
  gem 'sqlite3', :require => 'sqlite3'
  gem 'byebug'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'fixjour'
  gem 'faker'
end
