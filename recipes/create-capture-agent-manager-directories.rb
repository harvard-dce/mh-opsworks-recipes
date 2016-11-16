# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-python-manager-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

usr_name = get_capture_agent_manager_usr_name

[
  %Q|home/#{usr_name}/sites|,
  %Q|home/#{usr_name}/db|,
  %Q|home/#{usr_name}/logs|
].each do |capture_agent_manager_directory|
  directory capture_agent_manager_directory do
    owner usr_name
    group usr_name
    mode "755"
    recursive true
  end
end

database_s3_resource = get_capture_agent_manager_database_s3_resource
database_filepath = get_capture_agent_manager_database_filepath
execute "pull db file from s3" do
  command %Q(aws s3 cp #{database_s3_resource} - | sqlite3 #{database_filepath})
  creates database_filepath
end

cron_d "db backup" do
  minute "0"
  hour "3"
  user "root"
  command %Q(sqlite3 #{database_filepath} .dump | aws s3 cp - #  #{database_s3_resource})
end
