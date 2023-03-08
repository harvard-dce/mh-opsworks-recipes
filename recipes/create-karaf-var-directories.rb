# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-karaf-var-directories

# NOTE: We do this here because karaf needs these to exist and be writable by
# the opencast user, but /var/run and /var/lock get wiped on each reboot.
# It doesn't work to wait and create them at deploy time because
# if there's no new OC version being deployed the create doesn't happen.

# create the directories karaf needs for pid/lock
[
  '/var/run/opencast',
  '/var/lock/opencast'
].each do |karaf_directory|
  directory karaf_directory do
    owner 'opencast'
    group 'opencast'
    mode '755'
    recursive true
    action :create
  end
end
