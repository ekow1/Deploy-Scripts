#!/bin/bash
# Automated MySQL setup on Ubuntu EC2 (public access)

# Exit on error
set -e

# ====== CONFIGURATION ======
MYSQL_ROOT_PASSWORD="MyStrongRootPass123!"
MYSQL_DB_NAME="myappdb"
MYSQL_USER="myappuser"
MYSQL_USER_PASSWORD="MyAppUserPass123!"
# ===========================

echo "🔄 Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

echo "🐬 Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo "🚀 Starting and enabling MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

echo "🔐 Configuring MySQL root user..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "🌐 Configuring MySQL for public access..."
# Update bind-address to allow all connections
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

echo "👤 Creating database and user..."
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME};"
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';"
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME}.* TO '${MYSQL_USER}'@'%';"
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

echo "🧱 Adjusting firewall (if using UFW)..."
sudo ufw allow 3306/tcp || true

echo "✅ MySQL setup complete!"
echo "-----------------------------------------"
echo " Database: ${MYSQL_DB_NAME}"
echo " User: ${MYSQL_USER}"
echo " Password: ${MYSQL_USER_PASSWORD}"
echo " Root Password: ${MYSQL_ROOT_PASSWORD}"
echo " Public access enabled on port 3306"
echo "-----------------------------------------"
echo "💡 Reminder: Open port 3306 in your EC2 security group."
