set :application, 'photo-scrapper'
set :repo_url, 'git@github.com:vdaubry/photo-scrapper.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/srv/www/photo-scrapper'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 2

set :ssh_options, { :forward_agent => true, :paranoid => false }



namespace :deploy do

  desc 'Copy config from local workstation'
  task :copy_production do
    on roles :all do
      execute :mkdir, '-p', "#{shared_path}/config"
      execute "echo \"APP_ENV='production'\" > #{release_path}/config/application.rb"
      upload! 'private-conf/.env',            "#{release_path}/private-conf/.env"
      upload! 'private-conf/websites.yml',    "#{release_path}/private-conf/websites.yml"
      upload! 'private-conf/forums.yml',      "#{release_path}/private-conf/forums.yml"
      upload! 'private-conf/tumblr.yml',  "#{release_path}/private-conf/tumblr.yml"
    end
  end

  after :publishing, :copy_production

end
