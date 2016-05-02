# Cookbook Name:: mh-opsworks-recipes
# Recipe:: update-package-repo

execute 'fix any half-configured packages' do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command 'dpkg --configure -a'
  timeout 30
  retries 5
  retry_delay 15
end

execute 'update package repository' do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command 'apt-get update'
  timeout 180
  retries 5
  retry_delay 15
  ignore_failure true
  only_if do
    # /var/lib/apt/periodic/update-success-stamp is automatically touch'ed when
    # an "apt-get update" runs successfully. Take this into account.
    if ! File.exists?('/var/lib/apt/periodic/update-success-stamp')
      # It doesn't exist, update the repo
      true
    else
      # It does exist, update if it's older than 30 minutes
      File.mtime('/var/lib/apt/periodic/update-success-stamp') < Time.now - 1800
    end
  end
end
