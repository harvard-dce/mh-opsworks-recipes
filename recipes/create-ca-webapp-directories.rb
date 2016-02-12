# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-python-webapps-directories

[
  "/home/web/sites",
  "/home/web/sock",
  "/home/web/logs"
].each do |webapps_directory|
  directory webapps_directory do
    owner "web"
    group "web"
    mode "755"
    recursive true
  end
end
