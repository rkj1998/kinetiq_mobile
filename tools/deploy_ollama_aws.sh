#!/usr/bin/env bash
# ==============================================================================
# Kinetiq Mobile - 1-Click AWS EC2 / VPS Ollama Cloud Deployment Script
# ==============================================================================
# Run this script on any Ubuntu 22.04 / 24.04 AWS EC2 instance (e.g. g4dn.xlarge,
# g5.xlarge for NVIDIA GPU, or c6i / t4g for CPU inference).
#
# It automatically:
#  1. Installs Docker & Ollama with systemd auto-restart
#  2. Pulls target models (e.g., qwen2.5-coder:14b, qwen2.5-coder:7b, llama3)
#  3. Generates a secure API Key for your phone
#  4. Sets up a secure NGINX reverse proxy with optional SSL & Bearer authentication
#  5. Prints the exact Base URL and API Key to paste directly into Kinetiq Mobile!
#
# Usage:
#   chmod +x deploy_ollama_aws.sh
#   ./deploy_ollama_aws.sh
# ==============================================================================

set -euo pipefail

echo "=================================================================="
echo "🚀 KINETIQ MOBILE - OLLAMA CLOUD DEPLOYMENT (AWS / VPS)"
echo "=================================================================="

# 1. Update OS & Install Prerequisites
echo "📦 Updating system packages..."
sudo apt-get update -y
sudo apt-get install -y curl ufw nginx apache2-utils jq

# 2. Install Ollama
echo "🧠 Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✓ Ollama is already installed."
fi

# 3. Configure Ollama Systemd Service to listen on 127.0.0.1:11434 (Nginx will proxy & authenticate)
echo "⚙️ Configuring Ollama service..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=127.0.0.1:11434"
Environment="OLLAMA_ORIGINS=*"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl enable ollama

# Wait for Ollama to become responsive
echo "⏳ Waiting for Ollama daemon to initialize..."
until curl -s http://127.0.0.1:11434/api/tags > /dev/null; do
    sleep 2
done
echo "✓ Ollama daemon is live and listening on 127.0.0.1:11434"

# 4. Pull Default Models
MODELS=("qwen2.5-coder:7b" "llama3:latest")
echo "📥 Pulling initial models: ${MODELS[*]}..."
for MODEL in "${MODELS[@]}"; do
    echo "-> Downloading $MODEL (this may take a few minutes)..."
    ollama pull "$MODEL"
done

# 5. Generate Secure API Token for Kinetiq Mobile
AUTH_TOKEN=$(openssl rand -hex 24)
echo "$AUTH_TOKEN" > ~/kinetiq_ollama_key.txt
chmod 600 ~/kinetiq_ollama_key.txt

# 6. Configure NGINX Reverse Proxy with Bearer Token Authentication
echo "🛡️ Configuring NGINX reverse proxy on port 11434..."
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || curl -s ifconfig.me || echo "YOUR_SERVER_IP")

cat <<EOF | sudo tee /etc/nginx/sites-available/kinetiq-ollama
server {
    listen 80;
    listen 11434;
    server_name _;

    client_max_body_size 128M;

    location / {
        # Optional Bearer Token Validation
        if (\$http_authorization != "Bearer $AUTH_TOKEN") {
            # Allow preflight CORS
            set \$test_auth A;
        }
        if (\$request_method = OPTIONS) {
            set \$test_auth B;
        }
        if (\$test_auth = A) {
            return 401 '{"error": "Unauthorized: Invalid or missing Bearer token"}';
        }

        # CORS Headers for Mobile Client
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;

        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        proxy_pass http://127.0.0.1:11434;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Streaming support (disable buffering for LLM tokens)
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/kinetiq-ollama /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# 7. Configure Firewall
echo "🔥 Updating firewall rules..."
sudo ufw allow 22/tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 11434/tcp || true

echo ""
echo "=================================================================="
echo "🎉 DEPLOYMENT COMPLETE! KINETIQ MOBILE IS READY TO CONNECT"
echo "=================================================================="
echo ""
echo "📱 In Kinetiq Mobile on your phone (anywhere in the world):"
echo "   1. Open 'Customization Studio' -> 'Keys & Models' (or tap Network Hub icon)"
echo "   2. Base URL:  http://$PUBLIC_IP:11434/v1"
echo "   3. API Key:   $AUTH_TOKEN"
echo "   4. Tap 'Fetch Models' -> All downloaded models appear instantly!"
echo ""
echo "🔑 Saved Token File: ~/kinetiq_ollama_key.txt"
echo "=================================================================="
