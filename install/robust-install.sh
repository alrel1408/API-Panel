#!/bin/bash

# AlrelShop API Panel - Robust Installer
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/api-panel-install.log"

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif command_exists lsb_release; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=SuSE
    elif [ -f /etc/redhat-release ]; then
        OS=RedHat
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo "$OS"
}

# Function to install packages based on OS
install_packages() {
    local os=$(detect_os)
    log_message "${YELLOW}📦 Installing packages for $os...${NC}"
    
    case $os in
        *Ubuntu*|*Debian*)
            log_message "${BLUE}Updating package lists...${NC}"
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y >> "$LOG_FILE" 2>&1
            
            log_message "${BLUE}Installing required packages...${NC}"
            apt-get install -y --no-install-recommends \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                git \
                curl \
                wget \
                nginx \
                ufw \
                >> "$LOG_FILE" 2>&1
            ;;
        *CentOS*|*RedHat*|*Rocky*|*Alma*)
            log_message "${BLUE}Installing EPEL repository...${NC}"
            yum install -y epel-release >> "$LOG_FILE" 2>&1
            
            log_message "${BLUE}Installing required packages...${NC}"
            yum install -y \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                git \
                curl \
                wget \
                nginx \
                >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_message "${RED}❌ Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ Packages installed successfully${NC}"
    else
        log_message "${RED}❌ Failed to install packages${NC}"
        log_message "${YELLOW}Check log file: $LOG_FILE${NC}"
        exit 1
    fi
}

# Function to setup Python environment
setup_python() {
    log_message "${YELLOW}🐍 Setting up Python environment...${NC}"
    
    # Check Python version
    if ! command_exists python3; then
        log_message "${RED}❌ Python3 not found${NC}"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1)
    log_message "${BLUE}Python version: $PYTHON_VERSION${NC}"
    
    # Create virtual environment
    log_message "${BLUE}Creating virtual environment...${NC}"
    python3 -m venv /etc/API-Panel/venv >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ Virtual environment created${NC}"
    else
        log_message "${RED}❌ Failed to create virtual environment${NC}"
        exit 1
    fi
    
    # Activate virtual environment and install dependencies
    log_message "${BLUE}Installing Python dependencies...${NC}"
    source /etc/API-Panel/venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    
    # Install requirements
    if [ -f /etc/API-Panel/requirements.txt ]; then
        pip install -r /etc/API-Panel/requirements.txt >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ Python dependencies installed${NC}"
        else
            log_message "${RED}❌ Failed to install Python dependencies${NC}"
            exit 1
        fi
    else
        log_message "${YELLOW}⚠️  requirements.txt not found, installing basic packages${NC}"
        pip install flask flask-cors >> "$LOG_FILE" 2>&1
    fi
}

# Function to create systemd service
create_systemd_service() {
    log_message "${YELLOW}⚙️  Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/api-panel.service << 'EOF'
[Unit]
Description=AlrelShop API Panel
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/etc/API-Panel
Environment=PATH=/etc/API-Panel/venv/bin
Environment=PYTHONPATH=/etc/API-Panel
ExecStart=/etc/API-Panel/venv/bin/python api/main_api.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=api-panel

[Install]
WantedBy=multi-user.target
EOF

    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ Systemd service created${NC}"
    else
        log_message "${RED}❌ Failed to create systemd service${NC}"
        exit 1
    fi
}

# Function to setup Nginx
setup_nginx() {
    log_message "${YELLOW}🌐 Setting up Nginx...${NC}"
    
    # Create Nginx config
    cat > /etc/nginx/sites-available/api-panel << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/api-panel /etc/nginx/sites-enabled/
    
    # Remove default site if exists
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi
    
    # Test Nginx config
    nginx -t >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ Nginx configuration valid${NC}"
    else
        log_message "${RED}❌ Nginx configuration invalid${NC}"
        exit 1
    fi
}

# Function to setup firewall
setup_firewall() {
    log_message "${YELLOW}🔥 Setting up firewall...${NC}"
    
    if command_exists ufw; then
        ufw allow 22/tcp >> "$LOG_FILE" 2>&1
        ufw allow 80/tcp >> "$LOG_FILE" 2>&1
        ufw allow 443/tcp >> "$LOG_FILE" 2>&1
        ufw --force enable >> "$LOG_FILE" 2>&1
        log_message "${GREEN}✅ UFW firewall configured${NC}"
    elif command_exists firewall-cmd; then
        firewall-cmd --permanent --add-service=ssh >> "$LOG_FILE" 2>&1
        firewall-cmd --permanent --add-service=http >> "$LOG_FILE" 2>&1
        firewall-cmd --permanent --add-service=https >> "$LOG_FILE" 2>&1
        firewall-cmd --reload >> "$LOG_FILE" 2>&1
        log_message "${GREEN}✅ Firewalld configured${NC}"
    else
        log_message "${YELLOW}⚠️  No firewall manager found${NC}"
    fi
}

# Function to start services
start_services() {
    log_message "${YELLOW}🚀 Starting services...${NC}"
    
    # Reload systemd
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    
    # Enable and start API Panel
    systemctl enable api-panel >> "$LOG_FILE" 2>&1
    systemctl start api-panel >> "$LOG_FILE" 2>&1
    
    # Wait a moment for service to start
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet api-panel; then
        log_message "${GREEN}✅ API Panel service started${NC}"
    else
        log_message "${RED}❌ API Panel service failed to start${NC}"
        log_message "${YELLOW}Check logs: journalctl -u api-panel -f${NC}"
        exit 1
    fi
    
    # Start Nginx
    systemctl enable nginx >> "$LOG_FILE" 2>&1
    systemctl start nginx >> "$LOG_FILE" 2>&1
    
    if systemctl is-active --quiet nginx; then
        log_message "${GREEN}✅ Nginx service started${NC}"
    else
        log_message "${RED}❌ Nginx service failed to start${NC}"
    fi
}

# Function to create directories
create_directories() {
    log_message "${YELLOW}📁 Creating directories...${NC}"
    
    mkdir -p /var/log/api-panel
    mkdir -p /etc/API-Panel/logs
    mkdir -p /etc/API-Panel/backups
    
    # Set permissions
    chown -R root:root /etc/API-Panel
    chmod -R 755 /etc/API-Panel
    
    log_message "${GREEN}✅ Directories created${NC}"
}

# Function to test API
test_api() {
    log_message "${YELLOW}🧪 Testing API...${NC}"
    
    # Wait for service to be ready
    sleep 5
    
    # Test health endpoint
    if command_exists curl; then
        response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null)
        if [ "$response" = "200" ]; then
            log_message "${GREEN}✅ API is responding (HTTP $response)${NC}"
        else
            log_message "${YELLOW}⚠️  API response: HTTP $response${NC}"
        fi
    else
        log_message "${YELLOW}⚠️  curl not available, skipping API test${NC}"
    fi
}

# Main installation function
main() {
    log_message "${BLUE}================================${NC}"
    log_message "${BLUE}  AlrelShop API Panel Installer  ${NC}"
    log_message "${BLUE}      Robust Installation        ${NC}"
    log_message "${BLUE}================================${NC}"
    log_message ""
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_message "${RED}❌ Script ini harus dijalankan sebagai root${NC}"
        log_message "${YELLOW}Jalankan: sudo su -${NC}"
        exit 1
    fi
    
    # Check if API Panel directory exists
    if [ ! -d "/etc/API-Panel" ]; then
        log_message "${RED}❌ API Panel directory tidak ditemukan${NC}"
        log_message "${YELLOW}Pastikan script dijalankan dari direktori yang benar${NC}"
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE"
    log_message "${BLUE}📝 Log file: $LOG_FILE${NC}"
    
    # Detect OS
    OS=$(detect_os)
    log_message "${GREEN}✅ OS terdeteksi: $OS${NC}"
    
    # Install packages
    install_packages
    
    # Create directories
    create_directories
    
    # Setup Python environment
    setup_python
    
    # Create systemd service
    create_systemd_service
    
    # Setup Nginx
    setup_nginx
    
    # Setup firewall
    setup_firewall
    
    # Start services
    start_services
    
    # Test API
    test_api
    
    # Show final information
    log_message ""
    log_message "${BLUE}================================${NC}"
    log_message "${BLUE}      INSTALASI SELESAI!        ${NC}"
    log_message "${BLUE}================================${NC}"
    log_message ""
    log_message "${GREEN}✅ API Panel berhasil diinstall!${NC}"
    log_message "${BLUE}📍 Lokasi: /etc/API-Panel${NC}"
    log_message "${BLUE}🌐 URL: http://$(hostname -I | awk '{print $1}'):5000${NC}"
    log_message "${BLUE}🔑 API Key: alrelshop-secret-api-key-2024${NC}"
    log_message ""
    
    # Show useful commands
    log_message "${BLUE}🛠️  Command yang berguna:${NC}"
    log_message "  - Check status: systemctl status api-panel"
    log_message "  - View logs: journalctl -u api-panel -f"
    log_message "  - Restart: systemctl restart api-panel"
    log_message "  - Test API: curl http://localhost:5000/"
    log_message ""
    
    log_message "${GREEN}🎉 Selamat! API Panel Anda siap digunakan!${NC}"
    log_message "${BLUE}📝 Check log file untuk detail: $LOG_FILE${NC}"
}

# Run main function
main "$@"
