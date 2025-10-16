#!/bin/bash
set -e

# === 1. Update system ===
sudo apt update -y && sudo apt upgrade -y

# === 2. Install dependencies ===
sudo apt install -y curl git build-essential

# === 3. Install Node.js & npm ===
NODE_VERSION=18
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
sudo apt install -y nodejs

# === 4. Install Caddy ===
sudo rm -f /usr/share/keyrings/caddy-stable.gpg
curl -fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
  sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] \
https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | \
  sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update -y
sudo apt install -y caddy

# === 5. Setup app directory ===
APP_DIR=/var/www/linux-mastery
DOMAIN=linux.ekowlabs.space

sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# === 6. Clone or update repo ===
if [ -d "$APP_DIR/.git" ]; then
    echo "🔄 Updating existing repo..."
    cd $APP_DIR
    git pull origin main || git pull origin master
else
    echo "⬇️ Cloning repo fresh..."
    git clone https://github.com/your-org/linux-mastery.git $APP_DIR
    cd $APP_DIR
fi

# === 7. Install dependencies ===
npm install

# === 8. Create systemd service for Node app ===
sudo tee /etc/systemd/system/linux-mastery.service <<EOF
[Unit]
Description=Linux Mastery Node.js App
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/server.js
Restart=always
User=$USER
Environment=PORT=3000 NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# === 9. Enable & start the Node.js app ===
sudo systemctl daemon-reexec
sudo systemctl enable linux-mastery
sudo systemctl restart linux-mastery

# === 10. Configure Caddy reverse proxy ===
sudo tee /etc/caddy/Caddyfile <<EOF
linux.ekowlabs.space {
    reverse_proxy 127.0.0.1:3000
}
EOF

# === 11. Restart Caddy ===
sudo systemctl reload caddy || sudo systemctl start caddy
sudo systemctl enable caddy

echo "✅ Linux Mastery deployed successfully!"
echo "🌍 Visit: https://$DOMAIN"
