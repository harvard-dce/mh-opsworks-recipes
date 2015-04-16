# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-alarms

ruby_block 'remove alarms for instance' do
  block do
    require 'json'

    opsworks_instance_id = node[:opsworks][:instance][:id]
    region = node[:opsworks][:instance][:region]

    all_alarms = ::JSON.parse(
      %x(aws cloudwatch describe-alarms --region "#{region}" --output json)
    )

    alarms_for_instance = all_alarms['MetricAlarms'].find_all do |alarm|
      alarm['Dimensions'].find do |dimension|
        dimension['Name'] == 'InstanceId' && dimension['Value'] == opsworks_instance_id
      end
    end

    alarm_name_list = alarms_for_instance.map { |alarm| alarm['AlarmName'] }.join(' ')
    Chef::Log.info alarms_for_instance

    command = %Q(aws cloudwatch delete-alarms --region "#{region}" --alarm-names #{alarm_name_list})

    Chef::Log.info command
    %x(#{command})
  end
end

