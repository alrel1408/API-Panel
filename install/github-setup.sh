#!/bin/bash

# AlrelShop API Panel - GitHub Setup Script
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="your-username/alrelshop-api-panel"  # Ganti dengan repo GitHub Anda
GITHUB_BRANCH="main"
echo -e "${YELLOW}⚠️  IMPORTANT: Edit file ini dan ganti GITHUB_REPO dengan repository Anda!${NC}"
echo
INSTALL_DIR="/etc/API-Panel"
BACKUP_DIR="/root/backup-api-panel"

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

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}📦 Installing git...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y git
    elif command -v yum &> /dev/null; then
        yum install -y git
    elif command -v dnf &> /dev/null; then
        dnf install -y git
    else
        echo -e "${RED}❌ Package manager tidak dikenali${NC}"
        exit 1
    fi
fi

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Python3...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y python3 python3-pip python3-venv
    elif command -v yum &> /dev/null; then
        yum install -y python3 python3-pip
    elif command -v dnf &> /dev/null; then
        dnf install -y python3 python3-pip
    else
        echo -e "${RED}❌ Package manager tidak dikenali${NC}"
        exit 1
    fi
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Nginx...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y nginx
    elif command -v yum &> /dev/null; then
        yum install -y nginx
    elif command -v dnf &> /dev/null; then
        dnf install -y nginx
    else
        echo -e "${RED}❌ Package manager tidak dikenali${NC}"
        exit 1
    fi
fi

# Create backup if API Panel already exists
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  API Panel sudah ada di $INSTALL_DIR${NC}"
    echo -e "${YELLOW}📦 Membuat backup...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="api-panel-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C /etc API-Panel; then
        echo -e "${GREEN}✅ Backup berhasil dibuat: $BACKUP_NAME${NC}"
    else
        echo -e "${RED}❌ Gagal membuat backup${NC}"
        exit 1
    fi
    
    # Remove existing installation
    echo -e "${YELLOW}🗑️  Menghapus instalasi lama...${NC}"
    rm -rf "$INSTALL_DIR"
fi

# Clone repository
echo -e "${YELLOW}📥 Cloning repository dari GitHub...${NC}"
echo -e "${BLUE}Repository: https://github.com/$GITHUB_REPO${NC}"
echo -e "${BLUE}Branch: $GITHUB_BRANCH${NC}"
echo

# Prompt for GitHub credentials if needed
read -p "Apakah repository private? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️  Repository private terdeteksi${NC}"
    echo -e "${BLUE}Anda mungkin perlu memasukkan username dan token GitHub${NC}"
    echo -e "${BLUE}Atau setup SSH key untuk akses tanpa password${NC}"
    echo
fi

# Clone the repository
if git clone -b "$GITHUB_BRANCH" "https://github.com/$GITHUB_REPO.git" "$INSTALL_DIR"; then
    echo -e "${GREEN}✅ Repository berhasil di-clone${NC}"
else
    echo -e "${RED}❌ Gagal clone repository${NC}"
    echo -e "${YELLOW}Pastikan:${NC}"
    echo -e "  - Repository URL benar"
    echo -e "  - Repository dapat diakses"
    echo -e "  - Branch $GITHUB_BRANCH ada"
    echo -e "  - Git credentials sudah disetup"
    exit 1
fi

# Navigate to installation directory
cd "$INSTALL_DIR"

# Check if required files exist
echo -e "${YELLOW}🔍 Memverifikasi file yang diperlukan...${NC}"
required_files=(
    "api/main_api.py"
    "requirements.txt"
    "install/install.sh"
    "config/api_config.json"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo -e "${RED}❌ File berikut tidak ditemukan:${NC}"
    for file in "${missing_files[@]}"; do
        echo -e "  - $file"
    done
    echo -e "${YELLOW}Pastikan repository berisi semua file yang diperlukan${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Semua file yang diperlukan tersedia${NC}"

# Make install script executable
chmod +x install/install.sh

# Run the installer
echo -e "${YELLOW}🚀 Menjalankan installer...${NC}"
if ./install/install.sh; then
    echo -e "${GREEN}✅ Instalasi berhasil!${NC}"
else
    echo -e "${RED}❌ Instalasi gagal${NC}"
    echo -e "${YELLOW}Check log untuk detail error${NC}"
    exit 1
fi

# Show installation summary
echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}      INSTALASI SELESAI!        ${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo -e "${GREEN}✅ API Panel berhasil diinstall dari GitHub${NC}"
echo -e "${BLUE}📍 Lokasi: $INSTALL_DIR${NC}"
echo -e "${BLUE}🌐 URL: http://$(hostname -I | awk '{print $1}'):5000${NC}"
echo -e "${BLUE}🔑 API Key: $(grep -o '"api_key": "[^"]*"' config/api_config.json | cut -d'"' -f4)${NC}"
echo

# Show next steps
echo -e "${BLUE}📋 Langkah selanjutnya:${NC}"
echo -e "  1. Test API: python3 scripts/test_api.py"
echo -e "  2. Check status: scripts/status.sh"
echo -e "  3. Setup monitoring dan backup"
echo -e "  4. Konfigurasi domain dan SSL"
echo

# Show useful commands
echo -e "${BLUE}🛠️  Command yang berguna:${NC}"
echo -e "  - Start service: systemctl start api-panel"
echo -e "  - Stop service: systemctl stop api-panel"
echo -e "  - Check status: systemctl status api-panel"
echo -e "  - View logs: journalctl -u api-panel -f"
echo -e "  - Backup: scripts/backup.sh"
echo

# Show security note
echo -e "${YELLOW}🔐 Catatan Keamanan:${NC}"
echo -e "  - API Key sudah diaktifkan secara default"
echo -e "  - Semua endpoint memerlukan API Key"
echo -e "  - Gunakan header: X-API-Key: YOUR_API_KEY"
echo -e "  - Atau parameter: ?api_key=YOUR_API_KEY"
echo

echo -e "${GREEN}🎉 Selamat! API Panel Anda siap digunakan!${NC}"
