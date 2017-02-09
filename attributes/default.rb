
# Java
default['java']['install_flavor'] = 'openjdk'
default['java']['jdk_version'] = '8'

# Maven
default['maven']['version'] = '3.3.9'
default['maven']['setup_bin'] = true
default['maven']['mavenrc']['opts'] = '-Dmaven.repo.local=/root/.m2/repository -Xms1024m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=256m'

# ActiveMQ
default['activemq']['install_java'] = false
default['activemq']['version'] = '5.14.3'
