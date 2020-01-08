default_action :create

property :domain,             String, name_attribute: true

property :binary,             String, default: '/opt/certbot/certbot-auto'
property :installation_dir,   String, default: '/etc/letsencrypt'

property :config_path,        String
property :rsa_key_size,       Integer, default: 4096
property :email,              String
property :hostnames,          String
property :webroot_path,       String

action :create do
  template new_resource.template_path do
    source 'cert.conf.erb'
    owner 'root'
    group 'root'
    mode 0755

    variables(
      binary:       new_resource.binary,
      config_path:  new_resource.config_path,
      rsa_key_size: new_resource.rsa_key_size,
      email:        new_resource.email,
      hostnames:    new_resource.hostnames,
      webroot_path: new_resource.webroot_path
    )
    
    not_if do
      new_resource.webroot_path.to_s.empty?
    end
  end
  
  execute "install letsencrypt certificates for #{new_resource.domain}" do
    command "#{new_resource.binary} --non-interactive --config #{new_resource.config_path} certonly"
    user    "root"
    
    not_if do
      new_resource.webroot_path.to_s.empty?
    end
  end
end

action :delete do
  files                   =   [
    "#{new_resource.installation_dir}/configs/#{new_resource.domain}.conf",
    "#{new_resource.installation_dir}/renewal/#{new_resource.domain}.conf",
    "#{new_resource.installation_dir}/live/#{new_resource.domain}",
    "#{new_resource.installation_dir}/archive/#{new_resource.domain}"
  ]
  
  files.each do |remove_file|
    file remove_file do
      action :delete
      only_if { ::File.exists?(remove_file) }
    end
  end
end
