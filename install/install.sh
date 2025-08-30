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

# Copy files from current directory
echo -e "${YELLOW}📋 Copying API Panel files...${NC}"
cp -r api/ /etc/API-Panel/
cp -r config/ /etc/API-Panel/
cp -r docs/ /etc/API-Panel/
cp -r scripts/ /etc/API-Panel/
cp requirements.txt /etc/API-Panel/

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
chmod +x /etc/API-Panel/scripts/*.sh

# Create config file
echo -e "${YELLOW}⚙️ Creating configuration file...${NC}"
cat > /etc/API-Panel/config/api_config.json << EOF
{
    "api": {
        "host": "0.0.0.0",
        "port": 5000,
        "debug": false
    },
    "services": {
        "ssh": {
            "enabled": true,
            "default_days": 30,
            "default_ip_limit": 1,
            "default_quota_gb": 0
        },
        "vmess": {
            "enabled": true,
            "default_days": 30,
            "default_ip_limit": 1,
            "default_quota_gb": 0
        },
        "vless": {
            "enabled": true,
            "default_days": 30,
            "default_ip_limit": 1,
            "default_quota_gb": 0
        },
        "shadowsocks": {
            "enabled": true,
            "default_days": 30,
            "default_quota_gb": 0
        },
        "trojan": {
            "enabled": true,
            "default_days": 30,
            "default_ip_limit": 1,
            "default_quota_gb": 0
        },
        "trial": {
            "enabled": true,
            "default_minutes": 60
        }
    },
    "telegram": {
        "enabled": false,
        "bot_token": "",
        "chat_id": ""
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
echo -e "   • Check Status: ${GREEN}/etc/API-Panel/scripts/check_status.sh${NC}"
echo -e "   • Backup: ${GREEN}/etc/API-Panel/scripts/backup.sh${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "   • API Docs: ${GREEN}/etc/API-Panel/docs/${NC}"
echo -e "   • Config: ${GREEN}/etc/API-Panel/config/api_config.json${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo -e "   • Pastikan domain sudah dikonfigurasi dengan benar"
echo -e "   • Update konfigurasi Telegram bot jika diperlukan"
echo -e "   • Monitor logs di /var/log/api-panel/"
echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo -e "   1. Test API endpoints"
echo -e "   2. Configure domain dan SSL"
echo -e "   3. Setup monitoring dan backup"
echo -e "   4. Test semua service (SSH, VMess, VLess, dll)"
echo ""

# Test API endpoint
echo -e "${YELLOW}🧪 Testing API endpoint...${NC}"
sleep 2
if curl -s http://localhost:5000/ > /dev/null; then
    echo -e "${GREEN}✅ API endpoint is accessible${NC}"
else
    echo -e "${RED}❌ API endpoint is not accessible${NC}"
fi

echo ""
echo -e "${GREEN}✨ Installation completed successfully!${NC}"
echo -e "${BLUE}Visit http://YOUR_IP to access the API Panel${NC}"
