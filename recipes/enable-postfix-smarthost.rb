# Cookbook Name:: mh-opsworks-recipes
# Recipe:: enable-postfix-smarthost

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('postfix')

smtp_info = node.fetch(:smtp_auth, {})
hostname = node[:opsworks][:instance][:hostname]

template %Q|/etc/postfix/main.cf| do
  source 'postfix-main.cf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    hostname: hostname,
    relay_host: smtp_info[:relay_host]
  })
end

template %Q|/etc/postfix/sasl_passwd| do
  source 'postfix-sasl_passwd.erb'
  owner 'root'
  group 'root'
  mode '600'
  variables({
    relay_host: smtp_info[:relay_host],
    username: smtp_info[:username],
    password: smtp_info[:password]
  })
end

execute 'postmap the sasl_passwd file' do
  command %Q|postmap hash:/etc/postfix/sasl_passwd|
  retries 5
  retry_delay 5
end

execute 'tell postfix where CA cert is' do
  command %Q|postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt'|
  retries 5
  retry_delay 5
end

service 'postfix' do
  action :reload
  retries 5
  retry_delay 5
end
