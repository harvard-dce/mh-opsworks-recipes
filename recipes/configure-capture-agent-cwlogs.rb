# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-cwlogs

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = get_capture_agent_manager_info
stack = stack_shortname
ca_stats_user = capture_agent_manager_info[:ca_stats_user]
ca_stats_pass = capture_agent_manager_info[:ca_stats_passwd]
ca_stats_url = capture_agent_manager_info[:ca_stats_json_url]
ca_manager_user = capture_agent_manager_info[:capture_agent_manager_usr_name]
ca_key_file = "/home/#{ca_manager_user}/.ssh/dce-epiphan"

cookbook_file 'rsync_ca_cwlogs.sh' do
  path "/usr/local/bin/rsync_ca_cwlogs.sh"
  owner "root"
  group "root"
  mode "700"
end

directory '/var/log/capture_agents' do
  owner 'root'
  group 'root'
  mode '755'
end

# install ssh key to capture agents
file ca_key_file do
  owner ca_manager_user
  group ca_manager_user
  content capture_agent_manager_info[:ca_private_ssh_key]
  mode '0600'
end

cron_d 'rsync_ca_cwlogs' do
  minute "*/2"
  command %Q(/usr/bin/run-one /usr/local/bin/rsync_ca_cwlogs.sh 2>&1 | logger -t rsync-ca-cwlogs)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  environment ({
    CA_STATUS_USER_PASS: "#{ca_stats_user}:#{ca_stats_pass}",
    CA_STATUS_URL: ca_stats_url,
    CA_LOGS_BASE_DIR: "/var/log/capture_agents",
    CA_KEY_FILE: ca_key_file,
    LOG_AGENT_CONFIG_DIR: "/var/awslogs/etc/config",
    STACK_SHORTNAME: stack
  })
end

create_log_group(stack + "_capture-agent-messages")
create_log_group(stack + "_capture-agent-mhpearl")
