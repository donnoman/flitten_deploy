set :application, "flitten"
set :repository,  "git@github.com:donnoman/flitten.git"
set :branch, "testing"
set :user, "root"

set :deploy_to, "/app/#{application}"

set :scm, :git

role :web, "server", :no_release => true     # Your HTTP server, Apache/etc
role :app, "server"                          # This may be the same as your `Web` server
role :db,  "server", :primary => true, :no_release => true


after "deploy:setup" do
  deprec.ree.install
end


# Deploy scripts were separated from the app to allow them to be checked out
# separately and run locally against a specific role. ie: mysql and reverse proxies
# don't need the source code, but may need the deploy scripts.

# I'm considering a third repository that is nothing but rake tasks to run
# against localhost. It can be a submodule in the application repo.  This 
# Rake repo could be checked out on the other roles, and this repo could 
# be put back into the applications source repo.

# Deploy script scope at this time is limited to:
# - installing required tools to checkout the app
# - installing required tools to run bundler then rake
# - creating required directory structure
# - placing the source code onto the remote box
# - placing secrets onto the remote server
# - monitoring/reporting
# - starting/stopping subsystem

# Deprec is a big wildcard it may be too useful.

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

# namespace :deploy do
#   task :start {}
#   task :stop {}
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end