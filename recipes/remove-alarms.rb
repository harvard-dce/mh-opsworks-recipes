# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-alarms

::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block 'remove alarms for instance' do
  block do
    require 'json'

    aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
    region = 'us-east-1'

    all_alarms = ::JSON.parse(
      execute_command(%Q(aws cloudwatch describe-alarms --alarm-name-prefix="#{alarm_name_prefix}" --region "#{region}" --output json))
    )

    # Probably not necessary, but this ensures we don't remove alarms accidentally.
    alarms_for_instance = all_alarms['MetricAlarms'].find_all do |alarm|
      alarm['Dimensions'].find do |dimension|
        dimension['Name'] == 'InstanceId' && dimension['Value'] == aws_instance_id
      end
    end

    alarm_name_list = alarms_for_instance.map { |alarm| alarm['AlarmName'] }.join(' ')

    command = %Q(aws cloudwatch delete-alarms --region "#{region}" --alarm-names #{alarm_name_list})
    Chef::Log.info command
    execute_command(command)
  end
end
