#!/bin/bash

# AlrelShop API Panel - Status Check Script
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Panel directory
API_DIR="/etc/API-Panel"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  AlrelShop API Panel Status  ${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if API Panel is installed
if [ ! -d "$API_DIR" ]; then
    echo -e "${RED}❌ API Panel tidak ditemukan di $API_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API Panel ditemukan di $API_DIR${NC}"
echo

# Check Python virtual environment
if [ -d "$API_DIR/venv" ]; then
    echo -e "${GREEN}✅ Python virtual environment tersedia${NC}"
else
    echo -e "${RED}❌ Python virtual environment tidak ditemukan${NC}"
fi

# Check main API file
if [ -f "$API_DIR/api/main_api.py" ]; then
    echo -e "${GREEN}✅ Main API file tersedia${NC}"
else
    echo -e "${RED}❌ Main API file tidak ditemukan${NC}"
fi

# Check service modules
echo
echo -e "${BLUE}Service Modules:${NC}"
services=("ssh_service.py" "vmess_service.py" "vless_service.py" "shadowsocks_service.py" "trojan_service.py" "trial_service.py")
for service in "${services[@]}"; do
    if [ -f "$API_DIR/api/services/$service" ]; then
        echo -e "  ${GREEN}✅ $service${NC}"
    else
        echo -e "  ${RED}❌ $service${NC}"
    fi
done

# Check configuration files
echo
echo -e "${BLUE}Configuration Files:${NC}"
if [ -f "$API_DIR/config/api_config.json" ]; then
    echo -e "  ${GREEN}✅ api_config.json${NC}"
else
    echo -e "  ${RED}❌ api_config.json${NC}"
fi

# Check systemd service
echo
echo -e "${BLUE}Systemd Service:${NC}"
if systemctl is-active --quiet api-panel; then
    echo -e "  ${GREEN}✅ api-panel service aktif${NC}"
    echo -e "  Status: $(systemctl is-active api-panel)"
else
    echo -e "  ${RED}❌ api-panel service tidak aktif${NC}"
fi

if systemctl is-enabled --quiet api-panel; then
    echo -e "  ${GREEN}✅ api-panel service enabled${NC}"
else
    echo -e "  ${RED}❌ api-panel service tidak enabled${NC}"
fi

# Check Nginx configuration
echo
echo -e "${BLUE}Nginx Configuration:${NC}"
if [ -f "/etc/nginx/sites-available/api-panel" ]; then
    echo -e "  ${GREEN}✅ Nginx config tersedia${NC}"
    if nginx -t >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Nginx config valid${NC}"
    else
        echo -e "  ${RED}❌ Nginx config tidak valid${NC}"
    fi
else
    echo -e "  ${RED}❌ Nginx config tidak ditemukan${NC}"
fi

# Check if Nginx is running
if systemctl is-active --quiet nginx; then
    echo -e "  ${GREEN}✅ Nginx service aktif${NC}"
else
    echo -e "  ${RED}❌ Nginx service tidak aktif${NC}"
fi

# Check API endpoints
echo
echo -e "${BLUE}API Endpoints Test:${NC}"
if command -v curl >/dev/null 2>&1; then
    # Test health endpoint
    if curl -s -f "http://localhost:5000/health" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ API health endpoint (port 5000)${NC}"
    else
        echo -e "  ${RED}❌ API health endpoint (port 5000)${NC}"
    fi
    
    # Test through Nginx
    if curl -s -f "https://localhost/health" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Nginx health endpoint (HTTPS)${NC}"
    else
        echo -e "  ${RED}❌ Nginx health endpoint (HTTPS)${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  curl tidak tersedia untuk testing${NC}"
fi

# Check required system services
echo
echo -e "${BLUE}Required System Services:${NC}"
required_services=("xray" "ssh")
for service in "${required_services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "  ${GREEN}✅ $service service aktif${NC}"
    else
        echo -e "  ${RED}❌ $service service tidak aktif${NC}"
    fi
done

# Check log files
echo
echo -e "${BLUE}Log Files:${NC}"
log_dir="/var/log/api-panel"
if [ -d "$log_dir" ]; then
    echo -e "  ${GREEN}✅ Log directory tersedia: $log_dir${NC}"
    if [ -f "$log_dir/api-panel.log" ]; then
        echo -e "  ${GREEN}✅ API Panel log file tersedia${NC}"
        echo -e "  Size: $(du -h "$log_dir/api-panel.log" | cut -f1)"
    else
        echo -e "  ${YELLOW}⚠️  API Panel log file belum ada${NC}"
    fi
else
    echo -e "  ${RED}❌ Log directory tidak ditemukan${NC}"
fi

# Check database files
echo
echo -e "${BLUE}Database Files:${NC}"
db_files=(
    "/etc/ssh/.ssh.db"
    "/etc/vmess/.vmess.db"
    "/etc/vless/.vless.db"
    "/etc/shadowsocks/.shadowsocks.db"
    "/etc/trojan/.trojan.db"
    "/etc/trial/.trial.db"
)

for db_file in "${db_files[@]}"; do
    if [ -f "$db_file" ]; then
        echo -e "  ${GREEN}✅ $(basename "$db_file")${NC}"
    else
        echo -e "  ${YELLOW}⚠️  $(basename "$db_file") tidak ada${NC}"
    fi
done

# Check Xray configuration
echo
echo -e "${BLUE}Xray Configuration:${NC}"
xray_config="/etc/xray/config.json"
if [ -f "$xray_config" ]; then
    echo -e "  ${GREEN}✅ Xray config tersedia${NC}"
    if jq . "$xray_config" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Xray config valid JSON${NC}"
    else
        echo -e "  ${RED}❌ Xray config bukan valid JSON${NC}"
    fi
else
    echo -e "  ${RED}❌ Xray config tidak ditemukan${NC}"
fi

# Check domain configuration
echo
echo -e "${BLUE}Domain Configuration:${NC}"
domain_file="/etc/xray/domain"
if [ -f "$domain_file" ]; then
    domain=$(cat "$domain_file")
    echo -e "  ${GREEN}✅ Domain: $domain${NC}"
else
    echo -e "  ${RED}❌ Domain file tidak ditemukan${NC}"
fi

# Check SSL certificates
echo
echo -e "${BLUE}SSL Certificates:${NC}"
ssl_cert="/etc/xray/xray.crt"
ssl_key="/etc/xray/xray.key"
if [ -f "$ssl_cert" ] && [ -f "$ssl_key" ]; then
    echo -e "  ${GREEN}✅ SSL certificates tersedia${NC}"
    cert_expiry=$(openssl x509 -enddate -noout -in "$ssl_cert" 2>/dev/null | cut -d= -f2)
    if [ -n "$cert_expiry" ]; then
        echo -e "  Expires: $cert_expiry"
    fi
else
    echo -e "  ${RED}❌ SSL certificates tidak ditemukan${NC}"
fi

# Check firewall status
echo
echo -e "${BLUE}Firewall Status:${NC}"
if command -v ufw >/dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        echo -e "  ${GREEN}✅ UFW firewall aktif${NC}"
    else
        echo -e "  ${YELLOW}⚠️  UFW firewall tidak aktif${NC}"
    fi
elif command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state | grep -q "running"; then
        echo -e "  ${GREEN}✅ Firewalld aktif${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Firewalld tidak aktif${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  Firewall tidak terdeteksi${NC}"
fi

# Check disk space
echo
echo -e "${BLUE}Disk Space:${NC}"
df -h / | awk 'NR==2 {print "  Root: " $3 " / " $2 " (" $5 " used)"}'
df -h /etc | awk 'NR==2 {print "  /etc: " $3 " / " $2 " (" $5 " used)"}'

# Check memory usage
echo
echo -e "${BLUE}Memory Usage:${NC}"
free -h | awk 'NR==2 {print "  RAM: " $3 " / " $2 " (" $3/$2*100 "%)"}'

# Summary
echo
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}           SUMMARY              ${NC}"
echo -e "${BLUE}================================${NC}"

# Count issues
issues=0
if ! systemctl is-active --quiet api-panel; then
    ((issues++))
fi
if ! systemctl is-active --quiet nginx; then
    ((issues++))
fi
if ! systemctl is-active --quiet xray; then
    ((issues++))
fi

if [ $issues -eq 0 ]; then
    echo -e "${GREEN}✅ Semua service berjalan dengan baik!${NC}"
    echo -e "${GREEN}   API Panel siap digunakan${NC}"
else
    echo -e "${YELLOW}⚠️  Ditemukan $issues issue(s) yang perlu diperbaiki${NC}"
    echo -e "${YELLOW}   Jalankan: systemctl status api-panel${NC}"
fi

echo
echo -e "${BLUE}Untuk informasi lebih detail:${NC}"
echo -e "  - Log API: journalctl -u api-panel -f"
echo -e "  - Log Nginx: tail -f /var/log/nginx/api-panel-error.log"
echo -e "  - Status service: systemctl status api-panel"
echo -e "  - Test API: curl http://localhost:5000/health"
