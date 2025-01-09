#!/bin/bash

set -e

echo "Install Transform dependencies"
sudo dnf -y update &&
sudo dnf install -y ImageMagick &&
sudo dnf install -y libreoffice &&
sudo dnf install -y exiftool

curl -L -o /tmp/alfresco-pdf-renderer-1.2-linux.tgz https://nexus.alfresco.com/nexus/repository/releases/org/alfresco/alfresco-pdf-renderer/1.2/alfresco-pdf-renderer-1.2-linux.tgz &&
sudo tar xf /tmp/alfresco-pdf-renderer-1.2-linux.tgz -C /usr/bin

echo "Configure Transform server"
mkdir /home/alfresco/transform
cp downloads/alfresco-transform-core-aio-5.1.0.jar /home/alfresco/transform

# Variables
TRANSFORM_USER=alfresco
TRANSFORM_GROUP=alfresco
TRANSFORM_HOME=/home/alfresco/transform

echo "Creating Transform systemd service file..."
cat <<EOL | sudo tee /etc/systemd/system/transform.service
[Unit]
Description=Transform Application Container
After=network.target activemq.service
Requires=activemq.service

[Service]
Type=simple

User=$TRANSFORM_USER
Group=$TRANSFORM_GROUP

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="LIBREOFFICE_HOME=/usr/lib/libreoffice"

ExecStart=java -jar /home/alfresco/transform/alfresco-transform-core-aio-5.1.0.jar
ExecStop=/bin/kill -15 $MAINPID

[Install]
WantedBy=multi-user.target
EOL

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Starting Transform service..."
sudo systemctl start transform

echo "Stopping Transform service..."
sudo systemctl stop transform

echo "Enabling Transform service to start on boot..."
sudo systemctl enable transform

echo "Transform has been configured"
