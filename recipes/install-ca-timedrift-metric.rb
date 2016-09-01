# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ca-timedrift-metric

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = get_capture_agent_manager_info
app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name

template %Q|/usr/local/bin/ca_timedrift.sh| do
  source 'ca-timedrift-metric-script.erb'
  mode "0755"
  manage_symlink_source true
  variables({
    ca_stats_user: capture_agent_manager_info[:ca_stats_user],
    ca_stats_passwd: capture_agent_manager_info[:ca_stats_passwd],
    ca_stats_json_url: capture_agent_manager_info[:ca_stats_json_url]
  })
end

# install ssh key to capture agents
file "/home/#{usr_name}/.ssh/dce-epiphan" do
  owner usr_name
  group usr_name
  content capture_agent_manager_info[:ca_private_ssh_key]
  mode '0600'
end


cron_d "ca_timedrift_metrics" do
  user usr_name
  hour "*"
  # Redirect stderr and stdout to logger. The command is silent on succesful runs
  command %Q(/usr/local/bin/ca_timedrift.sh 2>&1 | logger -t info)
  path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
end

