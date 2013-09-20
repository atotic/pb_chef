class Chef::Provider::PookioGit < Chef::Provider::Git
  def run_options(run_opts={})
    ret = super(run_opts)
    ret[:environment] = {} unless ret[:environment]
    ret[:environment]['HOME'] = '/home/pookio'
    ret
  end
end
secrets = data_bag_item('pookio', 'secrets')[node['pookio']['rack_env']]

bash 'update apt' do
  code "apt-get update"
end

# A few dependencies we'll need:
package 'imagemagick'
package 'graphicsmagick'
package 'exiv2'
package 'daemon'
package 'pdftk'
package 'libxss-dev'
package 'chromium-browser'

# xvfb is a virtual X display for Chrome:
package 'xvfb'

service 'xvfb' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: true
end

cookbook_file 'xvfb_initd.sh' do
  path "/etc/init.d/xvfb"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[xvfb]"
  notifies :restart, "service[xvfb]"
end

# TODO: Chrome installation.

# Postgres database for the app:
bash 'create-postgres-user' do
  user 'postgres'
  code <<-EOQ
echo "CREATE USER #{secrets['postgres_user']} WITH PASSWORD '#{secrets['postgres_pw']}';"  | psql &&
echo "CREATE DATABASE pookio_development OWNER #{secrets['postgres_user']};"               | psql &&
echo "GRANT ALL PRIVILEGES ON DATABASE pookio_development TO #{secrets['postgres_user']};" | psql &&
echo "CREATE DATABASE pookio_production OWNER #{secrets['postgres_user']};"                | psql &&
echo "GRANT ALL PRIVILEGES ON DATABASE pookio_production TO #{secrets['postgres_user']};"  | psql
  EOQ
  only_if do
    system("invoke-rc.d postgresql status | grep main") and not system("echo 'SELECT NOW();' | PGPASSWORD='#{secrets['postgres_pw']}' psql -U #{secrets['postgres_user']} -h localhost pookio_production")
  end
  action :run
end

# The pookio user will run the app servers:
group 'pookio' do
  gid '2001'
end

user 'pookio' do
  home '/home/pookio'
  shell '/bin/bash'
  supports manage_home: true
  uid '2001'
  gid 'pookio'
end

# Make sure pookio can read the file at $SSH_AUTH_SOCK
# so it can `git clone` etc.:
group "deploy" do
  action :modify
  members ['pookio']
  append true
end

# A place for the app to live:
directory '/var/www' do
  owner 'root'
  group 'root'
  mode '0755'
end

directory node['pookio']['root'] do
  owner 'pookio'
  group 'pookio'
  mode '0755'
end

# Some gems:
# %w{bundler rake}.each do |gem|
%w{bundler}.each do |gem|
  bash "install #{gem} gem" do
    user 'root'
    code "source /etc/profile.d/rbenv.sh && gem install #{gem} && rbenv rehash"
  end
end

# Chrome:

git "#{node['pookio']['root']}/pb_chrome" do
  repo 'ssh://git@github.com/atotic/pb_chrome.git'
  ssh_wrapper node['ssh_agent_forwarding']['ssh_wrapper']
  action :sync
  user 'pookio'
  provider Chef::Provider::PookioGit
  notifies :restart, "service[chrome]"
end

bash 'download_chrome_binary' do
  cwd "#{node['pookio']['root']}/pb_chrome"
  user 'pookio'
  code <<-EOF
    set -e
    rm -rf "#{node['pookio']['root']}/pb_chrome/bin"
    mkdir -p "#{node['pookio']['root']}/pb_chrome/bin"
    curl --fail --location http://www.totic.org/chrome.ubuntu1304.tar.gz -o /tmp/chrome.ubuntu1304.tar.gz
    cd bin && tar xzvf /tmp/chrome.ubuntu1304.tar.gz && mv linux linux_64
  EOF
  not_if { ::File.exists?("#{node['pookio']['root']}/pb_chrome/bin/linux_64/chrome") }
end

service 'chrome' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: false
end

template 'chrome_initd.sh' do
  path "/etc/init.d/chrome"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[chrome]"
end

# Templates:

git "#{node['pookio']['root']}/pb_templates" do
  repo 'ssh://git@github.com/atotic/pb_templates.git'
  ssh_wrapper node['ssh_agent_forwarding']['ssh_wrapper']
  action :sync
  user 'pookio'
  provider Chef::Provider::PookioGit
end

# Servers:

service 'pookio' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: false
end

template 'pookio_initd.sh' do
  path "/etc/init.d/pookio"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[pookio]"
end

service 'comet' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: false
end

template 'comet_initd.sh' do
  path "/etc/init.d/comet"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[comet]"
end

service 'pdf_saver_server' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: false
end

template 'pdf_saver_server_initd.sh' do
  path "/etc/init.d/pdf_saver_server"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[pdf_saver_server]"
end

service 'delayed_job' do
  action :nothing
  supports start: true, stop: true, restart: true, reload: false
end

template 'delayed_job_initd.sh' do
  path "/etc/init.d/delayed_job"
  owner "root"
  group "root"
  mode "0755"
  notifies :enable, "service[delayed_job]"
end

deploy "#{node['pookio']['root']}/pb_server" do
  repo 'ssh://git@github.com/atotic/pb_server.git'
  git_ssh_wrapper node['ssh_agent_forwarding']['ssh_wrapper']
  scm_provider Chef::Provider::PookioGit
  user 'pookio'

  before_symlink do
    directory "#{node['pookio']['root']}/pb_server/shared/log" do
      owner 'pookio'
      group 'pookio'
      mode '0755'
    end
  end

  purge_before_symlink ['log']
  create_dirs_before_symlink []
  symlinks(
    'log' => 'log'
  )

  before_migrate do
    template 'secrets.sh' do
      path "#{node['pookio']['root']}/pb_server/shared/secrets.sh"
      owner 'pookio'
      group 'pookio'
      mode '0600'
      variables secrets: secrets
    end

    bash 'bundle-install' do
      user 'pookio'
      cwd release_path
      code "source /etc/profile.d/rbenv.sh && bundle install --binstubs --path=#{node['pookio']['root']}/pb_server/shared/bundle"
      environment 'HOME' => '/home/pookio',
                  'BUNDLE_APP_CONFIG' => './.bundle'
    end

    directory node['pookio']['root'] + '/pb_server/shared/pb_data'
  end

  migrate true
  migration_command "bash -c 'source /etc/profile.d/rbenv.sh && source #{node['pookio']['root']}/pb_server/shared/secrets.sh && bundle exec rake db:migrate --trace RACK_ENV=#{node['pookio']['rack_env']}'"

  before_restart do
    bash "run-scss" do
      user 'pookio'
      cwd release_path
      code <<-EOF
        source /etc/profile.d/rbenv.sh
        source #{node['pookio']['root']}/pb_server/shared/secrets.sh
        bundle exec rake deploy:less --trace
      EOF
      environment 'HOME' => '/home/pookio',
                  'BUNDLE_APP_CONFIG' => './.bundle'
    end
  end

  keep_releases 5

  notifies :restart, 'service[chrome]'
  notifies :restart, 'service[comet]'
  notifies :restart, 'service[pookio]'
  notifies :restart, 'service[delayed_job]'
  notifies :restart, 'service[pdf_saver_server]'
end

# nginx

bash 'enable-nginx-site' do
  action :nothing
  code <<-EOF
    /usr/sbin/nxensite pookio
  EOF
end

template 'nginx-pookio' do
  path "#{node['nginx']['dir']}/sites-available/pookio"
  owner "root"
  group "root"
  mode "0755"
  notifies :run, "bash[enable-nginx-site]"
  notifies :restart, "service[nginx]"
end
