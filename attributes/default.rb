
# Java
default['java']['install_flavor'] = 'openjdk'
default['java']['jdk_version'] = '8'

# Maven
default['maven']['version'] = '3.3.9'
default['maven']['setup_bin'] = true
default['maven']['mavenrc']['opts'] = '-Dmaven.repo.local=/root/.m2/repository -Xms1024m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=256m'

# ActiveMQ
default['activemq']['install_java'] = false
default['activemq']['version'] = '5.15.4'
# this is only to tell the 3rd-party activemq recipe not to issue its own
# service restart; we do that ourselves in the configure-activemq recipe
default['activemq']['enabled'] = false
# OPC-141 update wrapper.conf (https://opencast.jira.com/browse/MH-12620)
default['activemq']['wrapper']['max_memory'] = '2048'

