# Cookbook Name:: oc-opsworks-recipes
# Recipe:: enable-postfix-smarthost

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

smtp_info = node.fetch(:smtp_auth, {})
hostname = node[:opsworks][:instance][:hostname]
postfix_cert_path = "/etc/ssl/certs/postfix.pem"
mail_name = stack_shortname

template %Q|/etc/postfix/main.cf| do
  source 'postfix-main.cf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    mail_name: mail_name,
    hostname: hostname,
    origin: "#{hostname}.localdomain",
    relay_host: smtp_info[:relay_host],
    postfix_cert_path: postfix_cert_path
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
  command %Q|postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt'|
  retries 5
  retry_delay 5
end

# creates a file containing both key and cert
execute 'create dummy key/cert' do
  command %Q|/etc/pki/tls/certs/make-dummy-cert #{postfix_cert_path}|
  retries 5
  retry_delay 5
end

file postfix_cert_path do
  mode '400'
  owner 'root'
  group 'root'
end

service 'postfix' do
  supports :reload => true
  action [:reload, :start]
  retries 5
  retry_delay 5
end
