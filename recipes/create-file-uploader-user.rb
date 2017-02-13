# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-file_uploader-user

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

shared_storage_root = get_shared_storage_root
storage_info = get_storage_info
export_root = storage_info[:export_root]
public_ssh_key = node.fetch(
  :file_uploader_public_ssh_key,
  %Q|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDes9sir/DFtawDGx3dXJPAkOrU7RaCB0dmNp7rlzUIddWqBMsM/V8zcv1s0E3OL+hNc3egevGgb9IJEf0RE+efDkgX/EQJH5sXn9xZE8dyJTvgNp07rwgn/Btmt14fllVHUrwJF8DNtDduXiH3CsL72D7W4GYKs7CDpCT6WS/+qOvaaNFuxNH1cGKcKDNRZT9RBZZ/VnGZ58S+kB0uIXpfeH6XRi8jYdupSZRYHr75vc+NCGBPA1pis61fOBn8lSFZoYX5J7t8ZDYaWREAxy/GazP6sQIu43JI7KBUBQWp5PU3kNitPviTWiC4KCcsgFaAf6ifnunFB9HozHAm/4sN djcp@djcp-t5610|
)

rsync_upload_dir = "#{export_root}/rsync_uploads"

directory rsync_upload_dir do
  action :create
  owner 'root'
  group 'root'
  mode '777'
end

group 'file_uploader' do
  append true
end

user 'file_uploader' do
  supports manage_home: true
  comment 'rsync file upload user'
  gid 'file_uploader'
  shell '/bin/bash'
  home '/home/file_uploader'
  ignore_failure true
end

directory "/home/file_uploader/.ssh" do
  action :create
  owner 'file_uploader'
  group 'file_uploader'
  mode '700'
end

file "/home/file_uploader/.ssh/authorized_keys" do
  content %Q|command="/usr/bin/rsync --server -vvulogDtprze.iLsfx . #{rsync_upload_dir}",no-pty,no-agent-forwarding,no-port-forwarding,no-X11-forwarding #{public_ssh_key}|
  owner 'file_uploader'
  group 'file_uploader'
  mode '600'
end

cron_d "move_rsync_uploads_into_place" do
  user "root"
  minute "*"
  command %Q(cd #{rsync_upload_dir} && /usr/bin/run-one find ./ -type f ! -name '.*' -print0 | xargs -0 -I {} sh -c 'chown opencast.opencast "{}"; mv "{}" #{shared_storage_root}/inbox/;')
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d "remove_stale_rsync_uploads" do
  user "root"
  minute "30"
  command %Q(cd #{rsync_upload_dir} && /usr/bin/run-one find ./ -type f -name '.*' -mtime 1 -delete)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end
