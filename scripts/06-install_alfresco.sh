#!/bin/bash

set -e

echo "Install unzip command"
sudo dnf -y install unzip

echo "Create support folders and configuration in Tomcat"
mkdir -p /home/alfresco/tomcat/shared/classes && mkdir -p /home/alfresco/tomcat/shared/lib
sed -i 's|^shared.loader=$|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' /home/alfresco/tomcat/conf/catalina.properties

echo "Unzip Alfresco ZIP Distribution File"
mkdir /tmp/alfresco
unzip downloads/alfresco-content-services-community-distribution-23.2.1.zip -d /tmp/alfresco

echo "Copy JDBC driver"
cp /tmp/alfresco/web-server/lib/postgresql-42.6.0.jar /home/alfresco/tomcat/shared/lib/

echo "Configure JAR Addons deployment"
mkdir -p /home/alfresco/modules/platform && mkdir -p /home/alfresco/modules/share && mkdir -p /home/alfresco/tomcat/conf/Catalina/localhost
cp /tmp/alfresco/web-server/conf/Catalina/localhost/* /home/alfresco/tomcat/conf/Catalina/localhost/

echo "Install Web Applications"
cp /tmp/alfresco/web-server/webapps/* /home/alfresco/tomcat/webapps/

echo "Apply configuration"
cp -r /tmp/alfresco/web-server/shared/classes/* /home/alfresco/tomcat/shared/classes/
mkdir /home/alfresco/keystore && cp -r /tmp/alfresco/keystore/* /home/alfresco/keystore/
mkdir /home/alfresco/alf_data
cat <<EOL | tee /home/alfresco/tomcat/shared/classes/alfresco-global.properties
#
# Custom content and index data location
#
dir.root=/home/alfresco/alf_data
dir.keystore=/home/alfresco/keystore/

#
# Database connection properties
#
db.username=alfresco
db.password=alfresco
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://localhost:5432/alfresco

#
# Solr Configuration
#
solr.secureComms=secret
solr.sharedSecret=secret
solr.host=localhost
solr.port=8983
index.subsystem.name=solr6

# 
# Transform Configuration
#
localTransform.core-aio.url=http://localhost:8090/

#
# Events Configuration
#
messaging.broker.url=failover:(nio://localhost:61616)?timeout=3000&jms.useCompression=true

#
# URL Generation Parameters
#-------------
alfresco.context=alfresco
alfresco.host=localhost
alfresco.port=8080
alfresco.protocol=http
share.context=share
share.host=localhost
share.port=8080
share.protocol=http
EOL

echo "Apply AMPs"
mkdir /home/alfresco/amps && cp -r /tmp/alfresco/amps/* /home/alfresco/amps/
mkdir /home/alfresco/bin && cp -r /tmp/alfresco/bin/* /home/alfresco/bin/
java -jar /home/alfresco/bin/alfresco-mmt.jar install /home/alfresco/amps /home/alfresco/tomcat/webapps/alfresco.war -directory
java -jar /home/alfresco/bin/alfresco-mmt.jar list /home/alfresco/tomcat/webapps/alfresco.war

echo "Modify alfresco and share logs directory"
mkdir /home/alfresco/tomcat/webapps/alfresco && unzip /home/alfresco/tomcat/webapps/alfresco.war -d /home/alfresco/tomcat/webapps/alfresco
mkdir /home/alfresco/tomcat/webapps/share && unzip /home/alfresco/tomcat/webapps/share.war -d /home/alfresco/tomcat/webapps/share
sed -i 's|^appender\.rolling\.fileName=alfresco\.log|appender.rolling.fileName=/home/alfresco/tomcat/logs/alfresco.log|' /home/alfresco/tomcat/webapps/alfresco/WEB-INF/classes/log4j2.properties
sed -i 's|^appender\.rolling\.fileName=share\.log|appender.rolling.fileName=/home/alfresco/tomcat/logs/share.log|' /home/alfresco/tomcat/webapps/share/WEB-INF/classes/log4j2.properties

echo "Alfresco has been configured"
