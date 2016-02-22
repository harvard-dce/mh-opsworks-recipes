# Cookbook Name:: mh-opsworks-recipes
# Recipe:: set-bash-as-default-shell

execute 'set sh to bash and not dash' do
  command %Q(echo "dash dash/sh boolean false" | debconf-set-selections && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash)
  not_if "ls -fali /bin/sh | grep -qie bash"
  retries 5
  retry_delay 5
end

cookbook_file "bash.bashrc" do
  path "/etc/bash.bashrc"
  owner "root"
  group "root"
  mode "644"
end
