# overrides the builtin opsworks setup recipe that installs ntpd1
name              "opsworks_initial_setup"
description       "override/workaround"
license           "Apache 2.0"
version           "1.0.0"
maintainer       'Jay Luker'
maintainer_email 'jay_luker@harvard.edu'
issues_url       'http://github.com/harvard-dce/oc-opsworks-recipes/issues' if respond_to?(:issues_url)
source_url       'http://github.com/harvard-dce/oc-opsworks-recipes/' if respond_to?(:source_url)
