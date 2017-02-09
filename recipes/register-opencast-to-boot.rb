# Cookbook Name:: oc-opsworks-recipes
# Recipe:: register-opencast-to-boot

cron_d 'start_opencast_at_boot' do
  # This is necessary (rather than the more idiomatic chef "service { action :enable }"
  # because the default opencast init causes other init scripts to fail to run during
  # a boot under the upstart sysvinit compatibility layer. Completely mysterious and
  # frustrating.
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games'
  predefined_value '@reboot'
  command '/etc/init.d/opencast start 2>&1 | /usr/bin/logger -t opencast'
end
