default_action :create

property :installation_dir,   String, name_attribute: true, default: '/etc/letsencrypt'
property :configs_dir,        String, default: lazy { "#{installation_dir}/configs" }
property :extras_dir,         String, default: lazy { "#{binary_dir}-extras" }
property :log_dir,            String, default: '/var/log/letsencrypt'

property :binary_dir,         String, default: '/opt/certbot'
property :binary,             String, default: lazy { "#{binary_dir}/certbot-auto" }

property :git_repo,           String, default: 'git://github.com/certbot/certbot.git'
property :git_branch,         String, default: 'master'

action :create do
  resources(execute: 'apt-get update').run_action(:run)

  %w{git bc}.each do |pkg|
    package pkg do
      action :install
    end
  end

  git new_resource.binary_dir do
    repository new_resource.git_repo
    reference new_resource.git_branch
    action :sync
  end

  # Run the certbot-auto client so that it can install required dependencies, configuration etc.
  execute 'run certbot-auto' do
    command "#{new_resource.binary} --non-interactive --os-packages-only"
    user 'root'
    retries 3
    retry_delay 3
  end

  dirs = [
    new_resource.extras_dir,
    new_resource.log_dir,
    new_resource.configs_dir
  ]

  dirs.each do |dir|
    directory dir do
      owner     'root'
      group     'root'
      mode      0775
      action    :create
      recursive true

      not_if do
        ::File.exists?(dir)
      end
    end
  end

  logrotate_app "letsencrypt" do
    cookbook "logrotate"
    path "#{new_resource.log_dir}/*.log"
    enable true
    frequency "daily"
    rotate 2
    options ["compress", "copytruncate", "delaycompress", "missingok"]
  end
end
