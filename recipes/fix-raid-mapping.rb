# Cookbook Name:: mh-opsworks-recipes
# Recipe:: fix-raid-mapping

# Fix RAID array boot-time mapping bug: http://ubuntuforums.org/showthread.php?t=1764861&page=2
execute 'fix RAID array boot-time mapping bug' do
  command "update-initramfs -u"
  retries 5
  retry_delay 5
end
