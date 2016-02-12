# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-python-manager-directories

[
  "/home/capture_agent_manager/sites",
  "/home/capture_agent_manager/sock",
  "/home/capture_agent_manager/logs"
].each do |capture_agent_manager_directory|
  directory capture_agent_manager_directory do
    owner "capture_agent_manager"
    group "capture_agent_manager"
    mode "755"
    recursive true
  end
end
