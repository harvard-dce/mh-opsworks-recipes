# Cookbook Name:: oc-opsworks-recipes
# Recipe:: rsyslog-to-loggly

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

install_package('rsyslog-gnutls')
loggly_info = node.fetch(:loggly, { token: '', url: '' })
instance_attributes = node[:opsworks].fetch(:instance, {})

loggly_token = loggly_info[:token]
loggly_url = loggly_info[:url]
layer = instance_attributes.fetch(:layers, []).first
hostname = instance_attributes[:hostname]
local_stack_and_hostname = stack_and_hostname
local_stack_shortname = stack_shortname


if loggly_token != '' && loggly_url != ''
  ruby_block 'ensure rsyslog listens for local udp' do
    block do
      editor = Chef::Util::FileEdit.new('/etc/rsyslog.conf')
      editor.search_file_replace_line(/\#\$ModLoad imudp/, '$ModLoad imudp')
      editor.search_file_replace_line(/\#\$UDPServerRun 514/, '$UDPServerRun 514')
      editor.write_file
    end
  end

  directory '/etc/rsyslog.d/keys/' do
    owner 'root'
    group 'root'
    mode '755'
    recursive true
  end

  cookbook_file 'loggly-ca.crt' do
    path '/etc/rsyslog.d/keys/loggly-ca.crt'
    owner 'root'
    group 'root'
    mode '644'
  end

  template '/etc/rsyslog.d/22-loggly.conf' do
    source '22-loggly.conf.erb'
    variables({
      loggly_token: loggly_token,
      loggly_url: loggly_url,
      layer: layer || 'unassigned',
      hostname: hostname,
      stack_and_hostname: local_stack_and_hostname,
      stack_shortname: local_stack_shortname
    })
  end
  execute 'service rsyslog restart'
end
