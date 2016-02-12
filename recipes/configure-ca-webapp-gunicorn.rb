# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-ca-webapp-gunicorn

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ca_webapp_info = node.fetch(:ca_webapp, {})
app_name = ca_webapp_info.fetch(:ca_webapp_name, "webapp")

execute "install gunicorn" do
  command "source /home/web/sites/#{app_name}/venv/bin/activate && pip install gunicorn"
  user "web"
  creates "/home/web/sites/#{app_name}/venv/bin/gunicorn"
end

template "/home/web/sites/#{app_name}/gunicorn_start.sh" do
  source "ca-webapp-gunicorn_start.sh.erb"
  owner "web"
  group "web"
  mode "775"
  variables({
    ca_webapp_name: app_name
  })
end

directory "/home/web/sock" do
  owner "web"
  group "web"
  mode "775"
end
