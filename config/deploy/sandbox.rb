# Define your release to be deployed to integration environment here.
# Release number for integration environment is supposed to be odd numbers.
set :branch, 'CBG_1_10_2'

# Define your repository server for integration environment here.
#   production SVN - svn.prod.laxigames.com
#   development SVN - svn.mo.laxino.com
set :repo_host, 'git.platform.gamesource.local'

# Define your application servers for integration environment here.
#   int - Integration
#   stg - Staging
#   prd - Production
role :app, 'mo-snd-cms-app01.platform.gamesource.local'

role :cronjob_app, 'mo-snd-cms-app01.platform.gamesource.local'

#role :cronjob_app, 'int-cons-vapp03.rnd.laxino.com'

# Define your database servers for integration environment here.
# role :db,  "int-cons-db01.rnd.laxino.com", :primary => true

# Define your application cluster with Nginx settings here
# These variables will be used in generating Nginx/Thin config files
set :nginx_worker_processes, 2
set :cluster_port, 10066
set :virtual_server_name, 'mo-snd-cms-vapp01.platform.gamesource.local'
set :num_of_servers, 2

set :keep_releases, 2
after 'deploy', 'deploy:cleanup'
