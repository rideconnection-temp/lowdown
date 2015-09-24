set :branch, 'master'
set :rails_env, 'staging'
server '184.154.158.74', roles: [:app, :web, :db], user: 'deployer'
