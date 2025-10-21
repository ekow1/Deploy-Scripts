#!/bin/bash
# Automated MySQL setup on Ubuntu EC2 (public access, non-root user only)

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

echo "🔐 Securing MySQL root user (local only)..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';
FLUSH PRIVILEGES;
EOF

echo "🌐 Configuring MySQL for public access..."
# Update bind-address to allow all network connections
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

echo "👤 Creating database and non-root user..."
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "🚫 Disabling remote root access..."
sudo mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "DELETE FROM mysql.user WHERE User='root' AND Host='%'; FLUSH PRIVILEGES;"

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
echo "   Root login is local-only. Use '${MYSQL_USER}' for remote connections."
