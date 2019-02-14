# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-opencast-job-metrics

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

install_package('python3-pip python3-requests python3-six')

rest_auth_info = get_rest_auth_info
aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first
stack_name = stack_shortname

ojm_dir = "/usr/local/opencast_job_metrics"
ojm_revision = node.fetch(:opencast_job_metrics_revision, 'master')
ojm_recreate_venv = node.fetch(:opencast_job_metrics_recreate_venv, false)

bash 'install some system deps' do
  code '/usr/bin/pip3 install pyhorn virtualenv'
  user 'root'
end

["queued_job_count.py",
 "queued_job_count_metric.sh"
].each do |filename|
  cookbook_file filename do
    path "/usr/local/bin/#{filename}"
    owner "root"
    group "root"
    mode "755"
  end
end

git "get the opencast-job-metrics script" do
  repository "https://github.com/harvard-dce/opencast-job-metrics.git"
  revision ojm_revision
  destination ojm_dir
end

bash 'create virtualenv' do
  code %Q|
cd #{ojm_dir} &&
rm -rf venv &&
/usr/bin/python3 -m virtualenv --clear venv
  |
  only_if { !::Dir.exists?("#{}ojm_dir}/venv") || ojm_recreate_venv }
end

bash 'upgrade the venvs pip and install dependencies' do
  code %Q|
cd #{ojm_dir} &&
venv/bin/pip install -U pip &&
venv/bin/pip install -r requirements.txt
  |
end

cron_d 'opencast_jobs_queued' do
  user 'custom_metrics'
  minute '*'
  command %Q(/usr/local/bin/queued_job_count_metric.sh "#{aws_instance_id}" "http://#{private_admin_hostname}/" "#{rest_auth_info[:user]}" "#{rest_auth_info[:pass]}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end


