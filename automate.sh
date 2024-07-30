#!/bin/bash

# Variables
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
PROJECT_DIR="/var/www/projectlamp"
PROJECT_CONF="/etc/apache2/sites-available/projectlamp.conf"
PRIVATE_KEY="<private-key-name>.pem"

# Update and upgrade the system
sudo apt update -y
sudo apt upgrade -y

# Install Apache
sudo apt install apache2 -y

# Enable Apache to start on boot and start the service
sudo systemctl enable apache2
sudo systemctl start apache2

# Allow traffic on port 80
sudo ufw allow 'Apache Full'

# Install MySQL
sudo apt install mysql-server -y

# Secure MySQL installation
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'PassWord.1';"
sudo mysql_secure_installation <<EOF
n
1
y
y
y
y
EOF

# Install PHP
sudo apt install php libapache2-mod-php php-mysql -y

# Create project directory
sudo mkdir -p $PROJECT_DIR

# Set ownership of the project directory
sudo chown -R $USER:$USER $PROJECT_DIR

# Create Apache configuration for project
sudo bash -c "cat > $PROJECT_CONF <<EOF
<VirtualHost *:80>
    ServerName projectlamp
    ServerAlias www.projectlamp
    ServerAdmin webmaster@localhost
    DocumentRoot $PROJECT_DIR
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"

# Enable the new virtual host
sudo a2ensite projectlamp

# Disable the default virtual host
sudo a2dissite 000-default

# Test Apache configuration
sudo apache2ctl configtest

# Reload Apache to apply changes
sudo systemctl reload apache2

# Create a simple HTML file in the project directory
echo "Hello LAMP from hostname $HOSTNAME with public IP $PUBLIC_IP" | sudo tee $PROJECT_DIR/index.html

# Create a PHP info file to test PHP
sudo bash -c "cat > $PROJECT_DIR/index.php <<EOF
<?php
phpinfo();
EOF"

# Adjust DirectoryIndex to prioritize PHP files
sudo sed -i 's/index.html/index.php index.html/' /etc/apache2/mods-enabled/dir.conf

# Reload Apache to apply DirectoryIndex changes
sudo systemctl reload apache2

# Print out instructions to verify the installation
echo "LAMP stack installation is complete. You can verify it by visiting:"
echo "http://$PUBLIC_IP"
echo "http://$HOSTNAME"

