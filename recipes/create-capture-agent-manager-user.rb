# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-capture-agent-manager-user

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

usr_name = get_capture_agent_manager_usr_name

group usr_name do
  append true
  gid 2133
end

user usr_name do
  supports manage_home: true
  comment "capture agent manager user"
  uid 2133
  gid 2133
  shell "/bin/false"
  home "/home/#{usr_name}"
end

directory "/home/#{usr_name}/.ssh" do
  owner usr_name
  group usr_name
  mode "700"
end
