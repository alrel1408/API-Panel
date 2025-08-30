#!/bin/bash

# AlrelShop Auto Script - API Panel Installer
# Script untuk menginstall API Panel di VPS
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║              AlrelShop Auto Script - API Panel              ║
    ║                                                              ║
    ║                    VPN Management API                        ║
    ║                                                              ║
    ║              SSH • VMess • VLess • Shadowsocks              ║
    ║                    • Trojan • Trial                         ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root${NC}"
   exit 1
fi

# Check OS
if [[ -e /etc/debian_version ]]; then
    OS="debian"
    PKG_MANAGER="apt"
elif [[ -e /etc/redhat-release ]]; then
    OS="redhat"
    PKG_MANAGER="yum"
else
    echo -e "${RED}❌ OS tidak didukung${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OS terdeteksi: $OS${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
$PKG_MANAGER update -y

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
if [[ $OS == "debian" ]]; then
    $PKG_MANAGER install -y python3 python3-pip python3-venv curl wget git nginx
else
    $PKG_MANAGER install -y python3 python3-pip curl wget git nginx
fi

# Create API Panel directory
echo -e "${YELLOW}📁 Creating API Panel directory...${NC}"
mkdir -p /etc/API-Panel
cd /etc/API-Panel

# Copy files from current directory or clone from GitHub
echo -e "${YELLOW}📋 Setting up API Panel files...${NC}"

if [ -d "api" ] && [ -f "requirements.txt" ]; then
    # Files exist locally, copy them
    echo -e "${GREEN}✅ Using local files${NC}"
    cp -r api/ /etc/API-Panel/
    cp -r config/ /etc/API-Panel/
    cp -r docs/ /etc/API-Panel/
    cp -r scripts/ /etc/API-Panel/
    cp requirements.txt /etc/API-Panel/
    cp README.md /etc/API-Panel/ 2>/dev/null || true
    cp API_AUTHENTICATION.md /etc/API-Panel/ 2>/dev/null || true
    cp postman_collection.json /etc/API-Panel/ 2>/dev/null || true
else
    # Clone from GitHub
    echo -e "${YELLOW}📦 Cloning from GitHub repository...${NC}"
    cd /tmp
    git clone https://github.com/alrel1408/API-Panel.git
    cd API-Panel
    cp -r api/ /etc/API-Panel/
    cp -r config/ /etc/API-Panel/
    cp -r docs/ /etc/API-Panel/
    cp -r scripts/ /etc/API-Panel/
    cp requirements.txt /etc/API-Panel/
    cp README.md /etc/API-Panel/
    cp API_AUTHENTICATION.md /etc/API-Panel/
    cp postman_collection.json /etc/API-Panel/
    cd /etc/API-Panel
    rm -rf /tmp/API-Panel
fi

# Create virtual environment
echo -e "${YELLOW}🐍 Creating Python virtual environment...${NC}"
cd /etc/API-Panel
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo -e "${YELLOW}📦 Installing Python dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service
echo -e "${YELLOW}🔧 Creating systemd service...${NC}"
cat > /etc/systemd/system/api-panel.service << EOF
[Unit]
Description=AlrelShop API Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/API-Panel
Environment=PATH=/etc/API-Panel/venv/bin
ExecStart=/etc/API-Panel/venv/bin/python api/main_api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create nginx config
echo -e "${YELLOW}🌐 Creating nginx configuration...${NC}"
cat > /etc/nginx/sites-available/api-panel << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/api-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Create log directory
mkdir -p /var/log/api-panel

# Set permissions
chmod +x /etc/API-Panel/api/main_api.py
chmod +x /etc/API-Panel/api/api_key_manager.py 2>/dev/null || true
chmod +x /etc/API-Panel/scripts/*.sh
chown -R root:root /etc/API-Panel
chmod 755 /etc/API-Panel
chmod -R 644 /etc/API-Panel/config/
chmod 600 /etc/API-Panel/config/api_config.json

# Generate secure API key
echo -e "${YELLOW}🔑 Generating secure API key...${NC}"
API_KEY="alrelshop-$(openssl rand -hex 16)-$(date +%Y%m%d)"
echo -e "${GREEN}✅ Generated API Key: ${API_KEY}${NC}"

# Create config file with security settings
echo -e "${YELLOW}⚙️ Creating configuration file...${NC}"
cat > /etc/API-Panel/config/api_config.json << EOF
{
  "api": {
    "host": "0.0.0.0",
    "port": 5000,
    "debug": false,
    "log_level": "INFO",
    "log_file": "/var/log/api-panel/api-panel.log"
  },
  "services": {
    "ssh": {
      "enabled": true,
      "default_days": 30,
      "default_ip_limit": 1,
      "default_quota_gb": 0,
      "trial_minutes": 60,
      "trial_ip_limit": 4,
      "trial_quota_gb": 5
    },
    "vmess": {
      "enabled": true,
      "default_days": 30,
      "default_ip_limit": 1,
      "default_quota_gb": 0,
      "trial_minutes": 60,
      "trial_ip_limit": 3,
      "trial_quota_gb": 1,
      "default_bug": "bug.com"
    },
    "vless": {
      "enabled": true,
      "default_days": 30,
      "default_ip_limit": 1,
      "default_quota_gb": 0,
      "trial_minutes": 60,
      "trial_ip_limit": 2,
      "trial_quota_gb": 1
    },
    "shadowsocks": {
      "enabled": true,
      "default_days": 30,
      "default_quota_gb": 0,
      "trial_minutes": 60,
      "trial_quota_gb": 5,
      "default_cipher": "aes-128-gcm"
    },
    "trojan": {
      "enabled": true,
      "default_days": 30,
      "default_ip_limit": 1,
      "default_quota_gb": 0,
      "trial_minutes": 60,
      "trial_ip_limit": 3,
      "trial_quota_gb": 1
    },
    "trial": {
      "enabled": true,
      "default_minutes": 60,
      "auto_cleanup": true,
      "cleanup_interval": 3600
    }
  },
  "telegram": {
    "enabled": false,
    "bot_token": "",
    "chat_id": "",
    "notifications": {
      "account_created": true,
      "account_deleted": true,
      "account_renewed": true,
      "trial_created": true,
      "system_alerts": true
    }
  },
  "security": {
    "rate_limit": {
      "enabled": true,
      "requests_per_minute": 100,
      "burst_size": 20
    },
    "cors": {
      "enabled": true,
      "allowed_origins": ["*"],
      "allowed_methods": ["GET", "POST", "PUT", "DELETE"],
      "allowed_headers": ["Content-Type", "Authorization", "X-API-Key"]
    },
    "authentication": {
      "enabled": true,
      "type": "bearer",
      "api_key": "$API_KEY",
      "require_header": true
    }
  },
  "logging": {
    "level": "INFO",
    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    "handlers": {
      "file": {
        "enabled": true,
        "path": "/var/log/api-panel/api-panel.log",
        "max_size": "10MB",
        "backup_count": 5
      },
      "console": {
        "enabled": true
      }
    }
  }
}
EOF

# Create startup script
echo -e "${YELLOW}🚀 Creating startup script...${NC}"
cat > /etc/API-Panel/start_api.sh << 'EOF'
#!/bin/bash

# AlrelShop API Panel Startup Script
cd /etc/API-Panel
source venv/bin/activate
python api/main_api.py
EOF

chmod +x /etc/API-Panel/start_api.sh

# Create status check script
echo -e "${YELLOW}🔍 Creating status check script...${NC}"
cat > /etc/API-Panel/scripts/check_status.sh << 'EOF'
#!/bin/bash

# Check API Panel status
echo "=== AlrelShop API Panel Status ==="
echo "Service Status:"
systemctl status api-panel --no-pager -l

echo -e "\nPort Status:"
netstat -tlnp | grep :5000

echo -e "\nLogs (last 20 lines):"
tail -n 20 /var/log/api-panel/api-panel.log
EOF

chmod +x /etc/API-Panel/scripts/check_status.sh

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"
cat > /etc/API-Panel/scripts/backup.sh << 'EOF'
#!/bin/bash

# Backup API Panel configuration
BACKUP_DIR="/root/api-panel-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup configs
cp -r /etc/API-Panel/config $BACKUP_DIR/
cp -r /etc/API-Panel/api $BACKUP_DIR/

# Backup service files
cp /etc/systemd/system/api-panel.service $BACKUP_DIR/
cp /etc/nginx/sites-available/api-panel $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /etc/API-Panel/scripts/backup.sh

# Reload systemd and start services
echo -e "${YELLOW}🔄 Reloading systemd and starting services...${NC}"
systemctl daemon-reload
systemctl enable api-panel
systemctl start api-panel

# Test nginx config and restart
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    echo -e "${GREEN}✅ Nginx configuration is valid and restarted${NC}"
else
    echo -e "${RED}❌ Nginx configuration has errors${NC}"
fi

# Create firewall rules
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 5000/tcp
    echo -e "${GREEN}✅ UFW firewall rules added${NC}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --permanent --add-port=5000/tcp
    firewall-cmd --reload
    echo -e "${GREEN}✅ Firewalld rules added${NC}"
fi

# Final status check
echo -e "${YELLOW}🔍 Checking final status...${NC}"
sleep 5

if systemctl is-active --quiet api-panel; then
    echo -e "${GREEN}✅ API Panel service is running${NC}"
else
    echo -e "${RED}❌ API Panel service failed to start${NC}"
    systemctl status api-panel --no-pager -l
fi

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx service is running${NC}"
else
    echo -e "${RED}❌ Nginx service failed to start${NC}"
    systemctl status nginx --no-pager -l
fi

# Display installation summary
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    INSTALLATION COMPLETE                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${GREEN}🎉 AlrelShop API Panel berhasil diinstall!${NC}"
echo ""
echo -e "${BLUE}📋 Installation Summary:${NC}"
echo -e "   • API Panel Directory: ${GREEN}/etc/API-Panel${NC}"
echo -e "   • API Service: ${GREEN}api-panel.service${NC}"
echo -e "   • API Port: ${GREEN}5000${NC}"
echo -e "   • Web Interface: ${GREEN}http://YOUR_IP${NC}"
echo -e "   • API Base URL: ${GREEN}http://YOUR_IP/api${NC}"
echo ""
echo -e "${BLUE}🚀 Available Commands:${NC}"
echo -e "   • Start API: ${GREEN}systemctl start api-panel${NC}"
echo -e "   • Stop API: ${GREEN}systemctl stop api-panel${NC}"
echo -e "   • Restart API: ${GREEN}systemctl restart api-panel${NC}"
echo -e "   • Check Status: ${GREEN}/etc/API-Panel/scripts/status.sh${NC}"
echo -e "   • Start Service: ${GREEN}/etc/API-Panel/scripts/start.sh${NC}"
echo -e "   • Stop Service: ${GREEN}/etc/API-Panel/scripts/stop.sh${NC}"
echo -e "   • Backup: ${GREEN}/etc/API-Panel/scripts/backup.sh${NC}"
echo -e "   • API Key Manager: ${GREEN}/etc/API-Panel/scripts/api-key-manager.sh${NC}"
echo -e "   • Test API: ${GREEN}python3 /etc/API-Panel/scripts/test_api.py${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "   • API Docs: ${GREEN}/etc/API-Panel/docs/${NC}"
echo -e "   • Config: ${GREEN}/etc/API-Panel/config/api_config.json${NC}"
echo ""
echo -e "${BLUE}🔐 Security Information:${NC}"
echo -e "   • API Key: ${GREEN}$API_KEY${NC}"
echo -e "   • Authentication: ${GREEN}Enabled${NC}"
echo -e "   • Rate Limiting: ${GREEN}Enabled${NC}"
echo -e "   • CORS Protection: ${GREEN}Enabled${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo -e "   • Save your API key securely!"
echo -e "   • Use X-API-Key header for authentication"
echo -e "   • Pastikan domain sudah dikonfigurasi dengan benar"
echo -e "   • Update konfigurasi Telegram bot jika diperlukan"
echo -e "   • Monitor logs di /var/log/api-panel/"
echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo -e "   1. Save your API key: ${GREEN}$API_KEY${NC}"
echo -e "   2. Test API endpoints with authentication"
echo -e "   3. Configure domain dan SSL"
echo -e "   4. Generate new API key if needed: ${GREEN}/etc/API-Panel/scripts/api-key-manager.sh${NC}"
echo -e "   5. Setup monitoring dan backup"
echo -e "   6. Test semua service (SSH, VMess, VLess, dll)"
echo ""

# Test API endpoint
echo -e "${YELLOW}🧪 Testing API endpoint...${NC}"
sleep 3

# Test basic endpoint (no auth required)
if curl -s http://localhost:5000/ > /dev/null; then
    echo -e "${GREEN}✅ API basic endpoint is accessible${NC}"
else
    echo -e "${RED}❌ API basic endpoint is not accessible${NC}"
fi

# Test authenticated endpoint
echo -e "${YELLOW}🔐 Testing API authentication...${NC}"
AUTH_TEST=$(curl -s -H "X-API-Key: $API_KEY" http://localhost:5000/api/status)
if echo "$AUTH_TEST" | grep -q "success"; then
    echo -e "${GREEN}✅ API authentication is working${NC}"
else
    echo -e "${RED}❌ API authentication failed${NC}"
fi

# Show example API usage
echo -e "${BLUE}💡 Example API Usage:${NC}"
echo -e "   ${YELLOW}# Test API status${NC}"
echo -e "   ${GREEN}curl -H \"X-API-Key: $API_KEY\" http://YOUR_IP:5000/api/status${NC}"
echo ""
echo -e "   ${YELLOW}# Create SSH account${NC}"
echo -e "   ${GREEN}curl -X POST http://YOUR_IP:5000/api/ssh/create \\${NC}"
echo -e "   ${GREEN}     -H \"Content-Type: application/json\" \\${NC}"
echo -e "   ${GREEN}     -H \"X-API-Key: $API_KEY\" \\${NC}"
echo -e "   ${GREEN}     -d '{\"username\":\"test\",\"password\":\"pass123\",\"days\":30}'${NC}"

echo ""
echo -e "${GREEN}✨ Installation completed successfully!${NC}"
echo -e "${BLUE}Visit http://YOUR_IP to access the API Panel${NC}"
