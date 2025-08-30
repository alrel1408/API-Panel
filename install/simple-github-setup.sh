#!/bin/bash

# AlrelShop API Panel - Simple GitHub Setup
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  AlrelShop API Panel Setup     ${NC}"
echo -e "${BLUE}      From GitHub Repository     ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root${NC}"
   echo -e "${YELLOW}Jalankan: sudo su -${NC}"
   exit 1
fi

# Get GitHub repository URL
echo -e "${YELLOW}📥 Masukkan URL GitHub repository:${NC}"
echo -e "${BLUE}Contoh: https://github.com/username/alrelshop-api-panel${NC}"
read -p "GitHub URL: " GITHUB_URL

if [ -z "$GITHUB_URL" ]; then
    echo -e "${RED}❌ URL tidak boleh kosong${NC}"
    exit 1
fi

# Extract repository name
REPO_NAME=$(basename "$GITHUB_URL" .git)
echo -e "${GREEN}✅ Repository: $REPO_NAME${NC}"

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y git python3 python3-pip python3-venv nginx curl wget
elif command -v yum &> /dev/null; then
    yum install -y git python3 python3-pip nginx curl wget
elif command -v dnf &> /dev/null; then
    dnf install -y git python3 python3-pip nginx curl wget
else
    echo -e "${RED}❌ Package manager tidak dikenali${NC}"
    exit 1
fi

# Clone repository
echo -e "${YELLOW}📥 Cloning repository...${NC}"
cd /etc
if git clone "$GITHUB_URL" API-Panel; then
    echo -e "${GREEN}✅ Repository berhasil di-clone${NC}"
else
    echo -e "${RED}❌ Gagal clone repository${NC}"
    exit 1
fi

# Navigate to API Panel directory
cd API-Panel

# Check if required files exist
echo -e "${YELLOW}🔍 Verifying files...${NC}"
if [ ! -f "api/main_api.py" ] || [ ! -f "requirements.txt" ]; then
    echo -e "${RED}❌ File yang diperlukan tidak ditemukan${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Semua file tersedia${NC}"

# Make install script executable and run it
if [ -f "install/install.sh" ]; then
    echo -e "${YELLOW}🚀 Running installer...${NC}"
    chmod +x install/install.sh
    if ./install/install.sh; then
        echo -e "${GREEN}✅ Instalasi berhasil!${NC}"
    else
        echo -e "${RED}❌ Instalasi gagal${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Install script tidak ditemukan, setup manual...${NC}"
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install dependencies
    pip install -r requirements.txt
    
    # Create systemd service
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

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start service
    systemctl daemon-reload
    systemctl enable api-panel
    systemctl start api-panel
    
    echo -e "${GREEN}✅ Setup manual selesai${NC}"
fi

# Show final information
echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}      INSTALASI SELESAI!        ${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo -e "${GREEN}✅ API Panel berhasil diinstall dari GitHub${NC}"
echo -e "${BLUE}📍 Lokasi: /etc/API-Panel${NC}"
echo -e "${BLUE}🌐 URL: http://$(hostname -I | awk '{print $1}'):5000${NC}"
echo -e "${BLUE}🔑 API Key: alrelshop-secret-api-key-2024${NC}"
echo

# Show next steps
echo -e "${BLUE}📋 Langkah selanjutnya:${NC}"
echo -e "  1. Test API: python3 scripts/test_api.py"
echo -e "  2. Check status: scripts/status.sh"
echo -e "  3. Import Postman collection: postman_collection.json"
echo

echo -e "${GREEN}🎉 Selamat! API Panel Anda siap digunakan!${NC}"
