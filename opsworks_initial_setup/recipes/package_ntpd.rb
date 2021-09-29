# Cookbook Name:: opsworks_initial_setup
# Recipe:: package_ntpd

# The opsworks service forces the installation of ntpd in their opsworks_initial_setup
# cookbook, but we want to use a service called chrony, so here we have to override
# their recipe.
execute 'override' do
	command 'echo "Overriding ntp installation"'
end
