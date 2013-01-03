source 'http://rubygems.org'

gem 'rails', '~> 3.0.10'
gem 'pg'

gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'devise', '~> 1.4.9'
gem 'dynamic_form', :git => 'git://github.com/rails/dynamic_form.git'
gem 'will_paginate', '~> 3.0.2'
gem 'userstamp', '~> 2.0.1'
gem 'validates_timeliness', '~> 3.0.7'
gem 'jquery-rails', '~> 1.0.12'
gem 'csv_builder', '~> 2.1.0'

# Deploy with Capistrano
gem "capistrano",     :require => false # We need it to be installed, but it's
gem "capistrano-ext", :require => false # not a runtime dependency
gem "rvm-capistrano", :require => false

group :production do
  gem 'exception_notification', '~> 3.0'
end

group :test, :development do
  gem "debugger"
  gem 'rspec-rails', '~> 2.7.0'
  gem 'capybara'
  gem 'fixjour'
  gem 'faker'
  gem 'automatic_foreign_key'
end
