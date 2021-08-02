# Cookbook Name:: oc-opsworks-recipes
# Recipe:: symlink-nginx-log-dir

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

install_package('rsync')

new_root = node[:nginx_log_root_dir] || node[:opencast_repo_root]
old_root = node[:old_nginx_log_root_dir] || '/var/log/'

# says "if the dir exists and is a symlink"
guard_clause = %Q|[ -e '#{old_root}/nginx' ] && [ -L '#{old_root}/nginx' ]|

directory %Q|#{new_root}/nginx| do
  action :create
  owner 'nobody'
  group 'nobody'
  mode '755'
  not_if guard_clause
end

execute "rsync logs" do
  command %Q|rsync -a #{old_root}/nginx/ #{new_root}/nginx|
  not_if guard_clause
end

ruby_block "mv old directory out of the way" do
  block do
    ::File.rename("#{old_root}/nginx/", "#{old_root}/nginx_old")
  end
  not_if guard_clause
end

execute "rsync logs again" do
  command %Q|rsync -a #{old_root}/nginx_old/ #{new_root}/nginx|
  not_if guard_clause
end

link %Q|#{old_root}/nginx| do
  to %Q|#{new_root}/nginx|
  not_if guard_clause
end

execute 'service nginx reload'
