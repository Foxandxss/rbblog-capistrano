set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
#set :rvm_path, '/usr/local/rvm'
#set :rvm_bin_path, '/usr/local/rvm/bin'

before 'deploy:setup', 'rvm:create_gemset' # only create gemset
after "deploy:finalize_update", "bundle"

desc "Install the bundle"
task :bundle do
  run "bundle install --gemfile #{release_path}/Gemfile --without development test"
end

require 'rvm/capistrano'

set :application, "capistrano"

set :scm, :git
set :repository,  "git@github.com:Foxandxss/rbblog-#{application}.git"
set :use_sudo, false

server "foxandxss.net", :app, :web, :db, primary: true

set :user, "http"
set :deploy_to, "/srv/http/ruby/thin/#{application}"
set :deploy_via, :remote_cache

default_run_options[:pty] = true

namespace :deploy do
  %w[start stop restart].each do |command|
    task command, roles: :app, except: {no_release: true} do
      sudo "/etc/init.d/thin #{command} #{application}"
    end
  end

  task :restart_nginx, roles: :app do
    sudo "/etc/init.d/nginx restart"
  end

  after "deploy:setup_config", "deploy:restart_nginx"

  task :setup_config, roles: :app do
    run "mkdir #{shared_path}/config"
    top.upload("config/nginx.conf", "#{shared_path}/config/nginx.conf", via: :scp)
    top.upload("config/thin.yml", "#{shared_path}/config/thin.yml", via: :scp)
    top.upload("config/database.yml", "#{shared_path}/config/database.yml", via: :scp)
    top.upload(".rvmrc", "#{shared_path}/.rvmrc", via: :scp)
    sudo "mv #{shared_path}/config/nginx.conf /etc/nginx/sites-available/capistrano.example.com"
    sudo "ln -nfs /etc/nginx/sites-available/capistrano.example.com /etc/nginx/sites-enabled/capistrano.example.com.conf"
  end

  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/thin.yml #{release_path}/config/thin.yml"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/.rvmrc #{release_path}/.rvmrc"
  end

  after "deploy:finalize_update", "deploy:symlink_config"
end