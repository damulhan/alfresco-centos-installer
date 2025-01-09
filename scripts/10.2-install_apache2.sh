#!/bin/bash

# Exit script on any error
set -e

# Update and upgrade the system
echo "Updating system..."
sudo dnf update -y

# Install Apache
echo "Installing Apache..."
sudo dnf install -y httpd

# Create directory for the Alfresco Content App
echo "Creating directory for Alfresco Content App..."
sudo mkdir -p /var/www/alfresco-content-app
sudo cp -r /home/alfresco/alfresco-content-app/dist/content-ce/* /var/www/alfresco-content-app

echo "Creating Apache systemd service file..."
cat <<EOL | sudo tee /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target solr.service
Requires=solr.service

[Service]
Type=forking
PIDFile=/run/httpd.pid
ExecStartPre=/usr/sbin/httpd -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/httpd -DFOREGROUND
ExecReload=/usr/sbin/httpd -k graceful
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling Apache service to start on boot..."
sudo systemctl enable httpd

# Configure Apache to serve the Alfresco Content App
echo "Configuring Apache..."
cat <<EOL | sudo tee /etc/httpd/conf.d/alfresco-content-app.conf
<VirtualHost *:80>
    DocumentRoot /var/www/alfresco-content-app

    <Directory /var/www/alfresco-content-app>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    RewriteEngine On
    RewriteCond %{REQUEST_URI} !-f
    RewriteCond %{REQUEST_URI} !-d
    RewriteRule ^ /index.html [L]
</VirtualHost>
EOL

# Enable the new Apache configuration
echo "Enabling Apache configuration..."
sudo systemctl restart httpd

# Stop Apache after configuration check
sudo systemctl stop httpd

# Instructions to transfer the built files
echo "Apache setup complete."
