# chef-letsencrypt
Chef cookbook to set up Let's Encrypt SSL certificates

## Installation

Install Let's Encrypt:

```
letsencrypt_install
```

If you're running Nginx and want to set up auto-renewal of certificates:

```
letsencrypt_nginx do
  nginx_binary "path_to_your_nginx_binary"
end
```

Configure a certificate:

```
letsencrypt_configure do
  domain "example.com"
  config_path "/etc/letsencrypt/configs/example.com.conf"
  email "email@example.com"
  hostnames "example.com,www.example.com"
  webroot_path "/var/www"
end
```
