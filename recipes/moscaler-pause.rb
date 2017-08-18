# Cookbook Name:: mh-opsworks-recipes
# Recipe:: moscaler-pause

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

[
    'moscaler_offpeak',
    'moscaler_normal',
    'moscaler_weekend',
    'moscaler_auto'
].each do |cron_entry|
  cron_d cron_entry do
    action :delete
  end
end



