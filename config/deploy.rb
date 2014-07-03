#-----Get Capistrano working with RVM-----
require "rvm/capistrano"  # Load RVM's capistrano plugin.    
set :rvm_ruby_string, '1.9.3-p547'
set :rvm_type, :user  # Don't use system-wide RVM
#---------------------------------------------

#-----Get Capistrano working with Bundler-----
require 'bundler/capistrano'
#---------------------------------------------

#-----Basic Recipe-----
set :application, "lowdown"
set :repository,  "git://github.com/rideconnection/lowdown.git"
set :deploy_to, "/home/deployer/rails/lowdown"
set :asset_env, "RAILS_RELATIVE_URL_ROOT=/service"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

set :user, "deployer"  # The server's user for deployments
set :use_sudo, false

role :web, "184.154.79.122"
role :app, "184.154.79.122"
role :db,  "184.154.79.122", :primary => true # This is where Rails migrations will run

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

task :link_database_yml do
  puts "    (Link in database.yml file)"
  run  "ln -nfs #{deploy_to}/shared/config/database.yml #{latest_release}/config/database.yml"
  puts "    Link in app_config.yml file"
  run  "ln -nfs #{deploy_to}/shared/config/app_config.yml #{latest_release}/config/app_config.yml"
end

before "deploy:assets:precompile", :link_database_yml
