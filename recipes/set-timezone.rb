# Cookbook Name:: mh-opsworks-recipes
# Recipe:: set-timezone

timezone = node.fetch(:timezone, 'America/New_York')

execute 'set timezone' do
  command %Q|timedatectl set-timezone "#{timezone}"|
  retries 5
  retry_delay 5
end
