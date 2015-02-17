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
    git: 'https://github.com/stricte/userstamp.git',
    branch: 'rails4'
gem 'jc-validates_timeliness'
gem 'csv_builder'
gem 'point_in_time',
    git: 'https://github.com/rideconnection/point_in_time'

group :staging, :production do
  gem 'exception_notification'
  gem 'therubyracer', platforms: :ruby
end

group :development do
  gem 'thin'
  gem 'spring'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.3'
  gem 'capistrano-rvm', '~> 0.1.2', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-passenger', '~> 0.0.1', require: false
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
