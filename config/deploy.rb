set :application, "Lowdown"
set :repository,  "http://github.com/chrispatterson/Lowdown.git"
set :deploy_to, "/home/deployer/rails/lowdown"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

set :user, "deployer"  # The server's user for deploys
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
