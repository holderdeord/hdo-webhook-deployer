load 'deploy'
require 'bundler/capistrano'

set :domain, "deploy.holderdeord.no"
set :application, "hdo-webhook-deployer"
set :deploy_to, "/webapps/#{application}"

set :user, "hdo"
set :use_sudo, false

set :scm, :git
set :repository,  "git://github.com/holderdeord/hdo-webhook-deployer.git"
set :branch, 'master'
set :git_shallow_clone, 1
set :default_shell, "/bin/bash -l"

role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :deploy_via, :remote_cache

if ENV['HIPCHAT_API_TOKEN']
  require "hipchat/capistrano"

  set :hipchat_token,     ENV["HIPCHAT_API_TOKEN"]
  set :hipchat_room_name, "Teknisk"
  set :hipchat_announce,  false
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  # Assumes you are using Passenger
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    # mkdir -p is making sure that the directories are there for some SCM's that don't save empty folders
    run <<-CMD
      mkdir -p #{latest_release}/tmp &&
      ln -nfs #{shared_path}/log #{latest_release}/log &&
      ln -nfs #{shared_path}/config/production.json #{latest_release}/config/production.json
    CMD

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = %w(images css).map { |p| "#{latest_release}/public/#{p}" }.select { |e| File.exist?(e) }.join(" ")
      unless asset_paths.strip.empty?
        run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
      end

    end
  end
end
