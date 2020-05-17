default_action :create

property :installation_dir,   String, name_attribute: true
property :configs_dir,        String, default: lazy { "#{installation_dir}/configs" }
property :log_dir,            String, default: '/var/log/letsencrypt'

property :binary_dir,         String, default: '/opt/certbot'
property :binary,             String, default: lazy { "#{binary_dir}/certbot-auto" }

property :extras_dir,         String, default: lazy { "#{binary_dir}-extras" }

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
  
  # Ubuntu >= 20.04
  %w{python3-dev python3-venv gcc libaugeas0 libssl-dev libffi-dev ca-certificates openssl}.each do |pkg|
    package pkg do
      action :install
       only_if { platform?('ubuntu') && Chef::VersionConstraint.new('>= 20.04').include?(node['platform_version']) }
    end
  end

  execute 'prepare python3 environment' do
    command "cd #{new_resource.binary_dir} && python3 tools/venv3.py"
    user 'root'
    only_if { platform?('ubuntu') && Chef::VersionConstraint.new('>= 20.04').include?(node['platform_version']) }
  end
  
  # Ubuntu <= 18.04
  execute 'run certbot-auto' do
    command "#{new_resource.binary} --non-interactive --os-packages-only"
    user 'root'
    retries 3
    retry_delay 3
    only_if { platform?('ubuntu') && Chef::VersionConstraint.new('<= 18.04').include?(node['platform_version']) }
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
