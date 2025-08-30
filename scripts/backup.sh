#!/bin/bash

# AlrelShop API Panel - Backup Script
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_DIR="/etc/API-Panel"
BACKUP_DIR="/root/backup-api-panel"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="api-panel-backup-$DATE.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  AlrelShop API Panel Backup   ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if API Panel is installed
if [ ! -d "$API_DIR" ]; then
    echo -e "${RED}❌ API Panel tidak ditemukan di $API_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Memulai backup API Panel...${NC}"
echo

# Stop API Panel service before backup
echo -e "${YELLOW}⏸️  Menghentikan API Panel service...${NC}"
if systemctl is-active --quiet api-panel; then
    systemctl stop api-panel
    echo -e "${GREEN}✅ API Panel service dihentikan${NC}"
else
    echo -e "${YELLOW}⚠️  API Panel service sudah tidak aktif${NC}"
fi

# Wait a moment for services to stop
sleep 2

# Create backup
echo -e "${YELLOW}📦 Membuat backup...${NC}"

# Files and directories to backup
BACKUP_ITEMS=(
    "$API_DIR/api"
    "$API_DIR/config"
    "$API_DIR/scripts"
    "$API_DIR/requirements.txt"
    "$API_DIR/README.md"
    "/etc/systemd/system/api-panel.service"
    "/etc/nginx/sites-available/api-panel"
    "/etc/nginx/sites-enabled/api-panel"
    "/var/log/api-panel"
)

# Check which items exist and add them to backup
EXISTING_ITEMS=()
for item in "${BACKUP_ITEMS[@]}"; do
    if [ -e "$item" ]; then
        EXISTING_ITEMS+=("$item")
        echo -e "  ${GREEN}✅ $item${NC}"
    else
        echo -e "  ${YELLOW}⚠️  $item tidak ditemukan${NC}"
    fi
done

# Create backup archive
if [ ${#EXISTING_ITEMS[@]} -gt 0 ]; then
    echo
    echo -e "${YELLOW}📁 Membuat archive backup...${NC}"
    
    cd /
    if tar -czf "$BACKUP_DIR/$BACKUP_NAME" "${EXISTING_ITEMS[@]}" 2>/dev/null; then
        echo -e "${GREEN}✅ Backup berhasil dibuat: $BACKUP_NAME${NC}"
        
        # Get backup size
        BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
        echo -e "  Size: $BACKUP_SIZE"
        
        # Create backup info file
        INFO_FILE="$BACKUP_DIR/backup-info-$DATE.txt"
        cat > "$INFO_FILE" << EOF
AlrelShop API Panel Backup Info
================================
Backup Date: $(date)
Backup File: $BACKUP_NAME
Backup Size: $BACKUP_SIZE
Items Backed Up:
$(printf '%s\n' "${EXISTING_ITEMS[@]}")
System Info:
- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- Kernel: $(uname -r)
- Architecture: $(uname -m)
- API Panel Version: $(grep -o 'Version: [0-9.]*' "$API_DIR/README.md" | head -1)
EOF
        
        echo -e "${GREEN}✅ Backup info disimpan: backup-info-$DATE.txt${NC}"
        
    else
        echo -e "${RED}❌ Gagal membuat backup${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Tidak ada item yang dapat di-backup${NC}"
    exit 1
fi

# Start API Panel service after backup
echo
echo -e "${YELLOW}▶️  Memulai kembali API Panel service...${NC}"
if systemctl start api-panel; then
    echo -e "${GREEN}✅ API Panel service dimulai kembali${NC}"
else
    echo -e "${RED}❌ Gagal memulai API Panel service${NC}"
    echo -e "${YELLOW}⚠️  Jalankan manual: systemctl start api-panel${NC}"
fi

# Check service status
sleep 3
if systemctl is-active --quiet api-panel; then
    echo -e "${GREEN}✅ API Panel service berjalan dengan baik${NC}"
else
    echo -e "${RED}❌ API Panel service tidak berjalan${NC}"
fi

# Cleanup old backups (keep last 5)
echo
echo -e "${YELLOW}🧹 Membersihkan backup lama...${NC}"
cd "$BACKUP_DIR"
BACKUP_COUNT=$(ls -1 api-panel-backup-*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    OLD_BACKUPS=$(ls -1t api-panel-backup-*.tar.gz | tail -n +6)
    for old_backup in $OLD_BACKUPS; do
        rm -f "$old_backup"
        echo -e "  ${YELLOW}🗑️  Dihapus: $old_backup${NC}"
    done
    echo -e "${GREEN}✅ Backup lama dibersihkan${NC}"
else
    echo -e "${GREEN}✅ Tidak ada backup lama yang perlu dibersihkan${NC}"
fi

# List all backups
echo
echo -e "${BLUE}📋 Daftar backup yang tersedia:${NC}"
if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    cd "$BACKUP_DIR"
    ls -lh api-panel-backup-*.tar.gz 2>/dev/null | while read -r line; do
        echo -e "  $line"
    done
else
    echo -e "  ${YELLOW}⚠️  Tidak ada backup yang tersedia${NC}"
fi

# Show backup location
echo
echo -e "${BLUE}📍 Lokasi backup:${NC}"
echo -e "  Directory: $BACKUP_DIR"
echo -e "  Total size: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo 'N/A')"

# Show restore instructions
echo
echo -e "${BLUE}🔄 Cara restore backup:${NC}"
echo -e "  1. Stop API Panel: systemctl stop api-panel"
echo -e "  2. Extract backup: tar -xzf $BACKUP_NAME -C /"
echo -e "  3. Restart service: systemctl daemon-reload && systemctl start api-panel"
echo -e "  4. Check status: systemctl status api-panel"

echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ Backup selesai!${NC}"
echo -e "${BLUE}================================${NC}"
