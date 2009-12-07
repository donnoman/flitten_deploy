require 'deprec'

set :application, "flitten"
set :repository,  "git@github.com:donnoman/flitten.git"
set :branch, "master"
set :user, "root"

set :deploy_to, "/app/#{application}"
set :deploy_via, :remote_cache

ssh_options[:forward_agent] = true

set :scm, :git

set :ruby_vm_type, :mri
set :app_server_type, :webroar
set :web_server_type, :none
set :webroar_import_configuration, false

require 'config/secrets'

role :web, '', :no_release => true
#role :web, "server.flitten.com", :no_release => true     # Your HTTP server, Apache/etc
role :app, "server.flitten.com"                          # This may be the same as your `Web` server
role :db,  "server.flitten.com", :primary => true, :no_release => true


# We hook into start so these task chains are only inserted when the :only task
# has been used on the command line.
on :start, :only => [:deploy,"deploy:migrations"] do
  after "deploy:update_code" do
    bundler.dependencies.default
    bundler.bundle
  end
end

on :start, :only => ["deploy:setup"] do
  top.deprec.rails.install_stack
end

namespace :bundler do
  # These dependencies can change as items are added to the bundle
  namespace :dependencies do
    task :default do
      flitten
      flitten_deploy
    end
    desc "System Dependencies to compile bundled gems for flitten"
    task :flitten, :except => {:no_release => true} do
      apt.install({:base => %w(libxml2-dev libxslt-dev libxslt-ruby)}, :stable, :roles => [:app])
    end
    desc "System Dependencies to compile bundled gems for flitten deploy scripts"
    task :flitten_deploy, :except => {:no_release => true} do
      #none yet
    end
  end

  task :bundle, :except => {:no_release => true} do
    run "cd #{latest_release}; gem bundle --cached"
  end
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

# Disabling this until I build a unicorn deprec plugin
namespace :deploy do
  %w(start stop restart migrate).each do |name|
    task name.to_sym do
      #nothing
    end
  end
end

namespace :deprec do
  namespace :rails do
    task :install_stack do
      top.deprec.ruby.install
      top.deprec.git.install
      top.deprec.app.install        # Uses value of app_server_type
      gem2.update_system #Bundler requires an updated rubygems
      gem2.install "bundler", "0.7.0"
    end
    task :activate_services do
      top.deprec.app.activate
    end
    task :setup_database, :roles => :db do
      #nothing
    end
  end
end