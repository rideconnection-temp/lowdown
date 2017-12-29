source 'http://rubygems.org'

gem 'rails', '~> 4.2.0'
gem 'pg'

gem 'jquery-ui-rails', '~> 5.0.0'
gem 'devise',          '~> 3.5.0'
gem 'dynamic_form',    '~> 1.1.0'
gem 'will_paginate',   '~> 3.1.0'
# Using userstamp from git for now, because 2.0.2 (Rails 3.2 compatible) has
# not been uploaded to rubygems as of this writing.
gem "userstamp",
    git: 'https://github.com/stricte/userstamp.git',
    branch: 'rails4'
gem 'jc-validates_timeliness',  '~> 3.1.0'
gem 'csv_builder',              '~> 2.1.0'
gem 'point_in_time',
    git: 'https://github.com/rideconnection/point_in_time'

group :staging, :production do
  gem 'exception_notification', '~> 4.1.0'
  gem 'therubyracer',           '~> 0.12.0', platforms: :ruby
end

group :development do
  gem 'thin'
  gem 'spring'

  # Use Capistrano for deployment
  gem 'capistrano',             '~> 3.4.0'
  gem 'capistrano-rvm',         '~> 0.1', require: false
  gem 'capistrano-rails',       '~> 1.1', require: false
  gem 'capistrano-secrets-yml', '~> 1.0.0', require: false
end

group :test, :development do
  gem 'sqlite3', require: 'sqlite3'
  gem 'byebug'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'fixjour'
  gem 'faker'
end
