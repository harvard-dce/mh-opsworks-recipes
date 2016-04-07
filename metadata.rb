name             'mh-opsworks-recipes'
maintainer       'Dan Collis-Puro'
maintainer_email 'dan@collispuro.net'
license          'All rights reserved'
description      'Installs/Configures mh-opsworks-recipes'
long_description 'Installs/Configures mh-opsworks-recipes'
version          '0.1.0'
issues_url       'http://github.com/harvard-dce/mh-opsworks-recipes/issues' if respond_to?(:issues_url)
source_url       'http://github.com/harvard-dce/mh-opsworks-recipes/'if respond_to?(:source_url)

depends 'nfs', '~> 2.1.0'
depends 'apt', '~> 2.9.2'
depends 'cron', '~> 1.6.1'
depends 'nodejs', '~> 2.4.4'
