#!/bin/bash
set -e

# === 1. Update system ===
sudo apt update -y && sudo apt upgrade -y

# === 2. Install dependencies ===
sudo apt install -y curl git rsync debian-keyring debian-archive-keyring apt-transport-https gnupg

# === 3. Install Caddy (fixed for Ubuntu 24.04) ===
# Remove any old key
sudo rm -f /usr/share/keyrings/caddy-stable.gpg

# Import the correct key
curl -fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
  sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

# Add Caddy repo with correct signed-by
echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] \
https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | \
  sudo tee /etc/apt/sources.list.d/caddy-stable.list

# Install Caddy
sudo apt update -y
sudo apt install -y caddy

# === 4. Setup web root ===
WEB_DIR=/var/www/html
sudo mkdir -p $WEB_DIR
sudo chown -R $USER:$USER $WEB_DIR

# === 5. Clone or update repo ===
if [ -d "$WEB_DIR/.git" ]; then
    echo "🔄 Updating existing repo..."
    cd $WEB_DIR
    git pull origin main || git pull origin master
else
    echo "⬇️ Cloning repo fresh..."
    git clone https://github.com/ekow1/Group_one.git $WEB_DIR
fi

# === 6. Configure Caddy with domain & HTTPS ===
sudo tee /etc/caddy/Caddyfile <<EOF
ui.ekowlabs.space {
    root * $WEB_DIR
    file_server
}
EOF

# === 7. Restart Caddy ===
sudo systemctl reload caddy || sudo systemctl start caddy
sudo systemctl enable caddy

echo "✅ Deployment complete!"
echo "🌍 Visit: https://ui.ekowlabs.space"
