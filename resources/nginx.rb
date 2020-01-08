default_action :create

property :nginx_binary,       String, name_attribute: true

property :binary_dir,         String, default: '/opt/certbot'
property :binary,             String, default: lazy { "#{binary_dir}/certbot-auto" }

property :installation_dir,   String, default: '/etc/letsencrypt'
property :configs_dir,        String, default: lazy { "#{installation_dir}/configs" }
property :extras_dir,         String, default: lazy { "#{binary_dir}-extras" }
property :log_dir,            String, default: '/var/log/letsencrypt'

property :renew_script_path,  String, default: lazy { "#{extras_dir}/renew.certs.nginx.sh" }
property :renew_log_path,     String, default: lazy { "#{log_dir}/letsencrypt.renew.log" }

property :cron,               Hash, default: {enabled: true, minute: "0", hour: "2", day: "*", month: "*", weekday: "*"}

action :create do
  template new_resource.renew_script_path do
    source 'renew.certs.nginx.sh.erb'
    owner 'root'
    group 'root'
    mode 0500
    
    variables(
      binary:         new_resource.binary,
      nginx_binary:   new_resource.nginx_binary,
      renew_log_path: new_resource.renew_log_path
    )
    
    not_if do
      new_resource.nginx_binary.to_s.empty?
    end
  end

  # Install Cron
  cron "letsencrypt-renewal-cron" do
    minute    new_resource.cron[:minute]
    hour      new_resource.cron[:hour]
    day       new_resource.cron[:day]
    month     new_resource.cron[:month]
    weekday   new_resource.cron[:weekday]
    command   new_resource.renew_script_path
    action    new_resource.cron[:enabled] ? :create : :delete
    
    not_if do
      new_resource.nginx_binary.to_s.empty?
    end
  end
  
  # Generate example cert configuration
  example_domain = 'example.com'
  
  letsencrypt_configure example_domain do
    binary        new_resource.binary
    config_path   "#{new_resource.extras_dir}/#{example_domain}.conf"
    email         "email@#{example_domain}"
    hostnames     "#{example_domain},www.#{example_domain}"
    webroot_path  "/var/www/apps/shared"
  end

end
