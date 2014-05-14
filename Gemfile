source 'http://rubygems.org'

gem 'rails', '4.0.5'
gem 'pg'

gem 'jquery-ui-rails',      '~> 4.2.1'
gem 'devise',               '~> 3.0.0'
gem 'dynamic_form',         '~> 1.1.4'
gem 'will_paginate',        '~> 3.0.2'
# Using userstamp from git for now, because 2.0.2 (Rails 3.2 compatible) has
# not been uploaded to rubygems as of this writing.
gem "userstamp",
  :git => "git://github.com/delynn/userstamp.git",
  :ref => "777633a"
gem 'validates_timeliness', '~> 3.0.7'
gem 'csv_builder',          '~> 2.1.0'
gem 'point_in_time',        :git => 'git://github.com/rideconnection/point_in_time'

# Deploy with Capistrano
gem "capistrano",     :require => false # We need it to be installed, but it's
gem "capistrano-ext", :require => false # not a runtime dependency
gem "rvm-capistrano", :require => false

group :production do
  gem 'exception_notification', '~> 4.0'
end

group :development do
  gem 'thin'
end

group :test, :development do
  gem 'sqlite3', :require => 'sqlite3'
  gem 'debugger'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'fixjour'
  gem 'faker'
end
