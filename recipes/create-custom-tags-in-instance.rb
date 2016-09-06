# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-custom-tags-in-instance

include_recipe "mh-opsworks-recipes::install-awscli"
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block "add tags" do
  block do
    require 'json'

    aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
    region = 'us-east-1'

    command = %Q(aws ec2 describe-instances --region "#{region}" --instance-ids '#{aws_instance_id}' | grep 'VolumeId' | awk -F'"' '{print $4;}')
    Chef::Log.info command
    volume_ids = execute_command(command).split(/\n+/)
    resource_ids = volume_ids.concat([aws_instance_id])

    custom_tags = node.fetch(:aws_custom_tags, [])
    if custom_tags.any?
      tag_input = {
        "DryRun" => false,
        "Resources" => resource_ids,
        "Tags" => custom_tags
      }
      tag_input_json = tag_input.to_json

      command = %Q(aws ec2 create-tags --region "#{region}" --cli-input-json '#{tag_input_json}')
      Chef::Log.info command
      execute_command(command)
    else
      Chef::Log.info "no custom tags found"
    end
  end
end
