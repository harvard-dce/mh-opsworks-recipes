# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-selinux

# Figuring out all the exceptions and selinux rules we would need to 
# define for opencast to run is beyond the scope of what i'm capable of doing.
# Setting this to permissive will still log warnings which we can monitor
# if there's a specific thing we're worried about.

file "/etc/selinux/config" do
  content "SELINUX=permissive\n"
end

execute "set selinux to permissive" do
  command "setenforce 0"
end
