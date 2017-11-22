# Cookbook Name:: oc-opsworks-recipes
# Recipe:: moscaler-resume

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

moscaler_attributes = get_moscaler_info

moscaler_type = moscaler_attributes['moscaler_type']
debug_flag = moscaler_attributes['moscaler_debug'] ? '-d' : ''
cron_interval = moscaler_attributes['cron_interval']

if moscaler_type == 'time'
  
  offpeak_instances = moscaler_attributes['offpeak_instances']
  peak_instances = moscaler_attributes['peak_instances']
  weekend_instances = moscaler_attributes['weekend_instances']

  # weekdays, offpeak, every five minutes from midnight - 7am + 11pm - midnight
  cron_d 'moscaler_offpeak' do
    user 'moscaler'
    hour '0-7,23'
    minute cron_interval
    weekday '1-5'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{offpeak_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  # weekdays, normal production window, every five minutes from 8am - 11pm
  cron_d 'moscaler_normal' do
    user 'moscaler'
    hour '8-22'
    minute cron_interval
    weekday '1-5'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{peak_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  # weekends, every five minutes
  cron_d 'moscaler_weekend' do
    user 'moscaler'
    minute cron_interval
    weekday '6,7'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{weekend_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

elsif moscaler_type == 'auto'

  cron_d 'moscaler_auto' do
    user 'moscaler'
    minute cron_interval
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale auto 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

end



