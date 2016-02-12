# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-capture-agent-manager-user

group "capture_agent_manager" do
  append true
  gid 2133
end

user "capture_agent_manager" do
  supports manage_home: true
  comment "capture agent manager user"
  uid 2133
  gid "capture_agent_manager"
  shell "/bin/false"
  home "/home/capture_agent_manager"
end

directory "/home/capture_agent_manager/.ssh" do
  owner "capture_agent_manager"
  group "capture_agent_manager"
  mode "700"
end
