# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-capture-agent-manager-user

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

username = get_capture_agent_manager_usr_name

group username do
  append true
  gid 2133
end

user username do
  supports manage_home: true
  comment "capture agent manager user"
  uid 2133
  gid 2133
  shell "/bin/false"
  home "/home/#{username}"
end

directory "/home/#{username}/.ssh" do
  owner username
  group username
  mode "700"
end
