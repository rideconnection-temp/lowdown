# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'lowdown'
set :repo_url, 'git://github.com/rideconnection/lowdown.git'
set :deploy_via, :remote_cache
set :deploy_to, '/home/deployer/rails/lowdown'

# RVM options
set :rvm_type, :user
set :rvm_ruby_version, '2.2.2@lowdown'
set :rvm_roles, [:app, :web]

# Passenger options
set :passenger_rvm_ruby_version, '2.2.1@passenger'

# Rails options
set :conditionally_migrate, false

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml','config/app_config.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 20

namespace :deploy do
  after :migrate, :seed
  after :publishing, :restart
end
