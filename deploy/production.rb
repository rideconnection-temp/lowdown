set :branch, 'stable'
set :rails_env, 'production'
server '184.154.79.122', roles: [:app, :web, :db], user: 'deployer'
