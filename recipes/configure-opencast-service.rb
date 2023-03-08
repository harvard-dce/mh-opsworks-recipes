# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-opencast-service

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

unless dont_start_opencast_automatically?
  service 'opencast' do
    action :start
    supports start: true, stop: true, restart: true, status: true
    start_command   "/bin/systemctl start opencast"
    stop_command   "/bin/systemctl stop opencast"
    restart_command  "/bin/systemctl restart opencast"
    status_command  "/bin/systemctl status opencast"
    provider Chef::Provider::Service::Systemd
  end
end
