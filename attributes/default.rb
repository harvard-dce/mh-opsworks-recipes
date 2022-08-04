
# Maven
default['maven']['version'] = '3.8.6'
default['maven']['setup_bin'] = true
default['maven']['mavenrc']['opts'] = '-Dmaven.repo.local=/root/.m2/repository -Xms1024m -Xmx1024m'
default['maven']['url'] = 'https://dlcdn.apache.org/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz'

# ActiveMQ
default['activemq']['install_java'] = false
default['activemq']['version'] = '5.15.4'
default['activemq']['transport_protocols'] = 'TLSv1.1,TLSv1.2'
default['activemq']['home'] = '/opt/opencast/activemq'
# this is only to tell the 3rd-party activemq recipe not to issue its own
# service restart; we do that ourselves in the configure-activemq recipe
default['activemq']['enabled'] = false

# Overrides for nfs
# the nfs cookbook gets these service names wrong for amazon linux 2018.03
# so here we override the nfs cookbook attributes
default['nfs']['service']['lock'] = 'nfslock'
default['nfs']['service']['idmap'] = 'rpcidmapd'
default['nfs']['service']['server'] = 'nfs'
