#!/bin/bash

# AlrelShop API Panel - Troubleshooting Script
# Author: AlrelShop Auto Script
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  AlrelShop API Panel Troubleshoot${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root${NC}"
   echo -e "${YELLOW}Jalankan: sudo su -${NC}"
   exit 1
fi

# Function to check system status
check_system() {
    echo -e "${YELLOW}🔍 Checking system status...${NC}"
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${BLUE}OS: $NAME $VERSION_ID${NC}"
    fi
    
    # Check memory
    MEMORY=$(free -h | grep Mem | awk '{print $2}')
    echo -e "${BLUE}Memory: $MEMORY${NC}"
    
    # Check disk space
    DISK=$(df -h / | tail -1 | awk '{print $4}')
    echo -e "${BLUE}Disk space: $DISK${NC}"
    
    # Check running processes
    echo -e "${BLUE}Running processes: $(ps aux | wc -l)${NC}"
}

# Function to kill stuck processes
kill_stuck_processes() {
    echo -e "${YELLOW}🔄 Killing stuck processes...${NC}"
    
    # Kill apt processes if stuck
    pkill -f apt
    pkill -f dpkg
    
    # Kill any hanging package managers
    pkill -f yum
    pkill -f dnf
    
    # Wait a moment
    sleep 2
    
    echo -e "${GREEN}✅ Stuck processes killed${NC}"
}

# Function to fix package manager
fix_package_manager() {
    echo -e "${YELLOW}🔧 Fixing package manager...${NC}"
    
    if command -v apt-get &> /dev/null; then
        echo -e "${BLUE}Fixing apt...${NC}"
        
        # Remove lock files
        rm -f /var/lib/apt/lists/lock
        rm -f /var/cache/apt/archives/lock
        rm -f /var/lib/dpkg/lock*
        
        # Reconfigure packages
        dpkg --configure -a
        
        # Fix broken packages
        apt-get install -f -y
        
        echo -e "${GREEN}✅ Apt fixed${NC}"
    elif command -v yum &> /dev/null; then
        echo -e "${BLUE}Fixing yum...${NC}"
        yum clean all
        echo -e "${GREEN}✅ Yum fixed${NC}"
    fi
}

# Function to check network
check_network() {
    echo -e "${YELLOW}🌐 Checking network...${NC}"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✅ Internet connection OK${NC}"
    else
        echo -e "${RED}❌ No internet connection${NC}"
        return 1
    fi
    
    # Check DNS
    if nslookup google.com &> /dev/null; then
        echo -e "${GREEN}✅ DNS working${NC}"
    else
        echo -e "${RED}❌ DNS issues${NC}"
        return 1
    fi
}

# Function to check ports
check_ports() {
    echo -e "${YELLOW}🔌 Checking ports...${NC}"
    
    # Check if port 5000 is in use
    if netstat -tlnp | grep :5000; then
        echo -e "${YELLOW}⚠️  Port 5000 is in use${NC}"
        echo -e "${BLUE}Killing process on port 5000...${NC}"
        fuser -k 5000/tcp
    else
        echo -e "${GREEN}✅ Port 5000 is free${NC}"
    fi
    
    # Check if port 80 is in use
    if netstat -tlnp | grep :80; then
        echo -e "${YELLOW}⚠️  Port 80 is in use${NC}"
    else
        echo -e "${GREEN}✅ Port 80 is free${NC}"
    fi
}

# Function to clean up
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    
    # Clean package cache
    if command -v apt-get &> /dev/null; then
        apt-get clean
        apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        yum clean all
    fi
    
    # Clear temporary files
    rm -rf /tmp/*
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to manual install
manual_install() {
    echo -e "${YELLOW}🛠️  Starting manual installation...${NC}"
    
    # Install basic packages one by one
    if command -v apt-get &> /dev/null; then
        echo -e "${BLUE}Installing Python3...${NC}"
        apt-get install -y python3
        
        echo -e "${BLUE}Installing pip...${NC}"
        apt-get install -y python3-pip
        
        echo -e "${BLUE}Installing venv...${NC}"
        apt-get install -y python3-venv
        
        echo -e "${BLUE}Installing nginx...${NC}"
        apt-get install -y nginx
        
        echo -e "${BLUE}Installing git...${NC}"
        apt-get install -y git
    fi
    
    echo -e "${GREEN}✅ Manual installation completed${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${YELLOW}📋 Recent system logs...${NC}"
    
    # Show recent system logs
    echo -e "${BLUE}--- Recent system logs ---${NC}"
    journalctl -n 20 --no-pager
    
    # Show package manager logs
    if [ -f /var/log/apt/history.log ]; then
        echo -e "${BLUE}--- Recent apt logs ---${NC}"
        tail -20 /var/log/apt/history.log
    fi
}

# Function to reset everything
reset_all() {
    echo -e "${RED}⚠️  WARNING: This will reset everything!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔄 Resetting everything...${NC}"
        
        # Stop services
        systemctl stop api-panel 2>/dev/null
        systemctl stop nginx 2>/dev/null
        
        # Remove API Panel
        rm -rf /etc/API-Panel
        
        # Remove systemd service
        rm -f /etc/systemd/system/api-panel.service
        
        # Remove nginx config
        rm -f /etc/nginx/sites-enabled/api-panel
        rm -f /etc/nginx/sites-available/api-panel
        
        # Reload systemd
        systemctl daemon-reload
        
        echo -e "${GREEN}✅ Reset completed${NC}"
    else
        echo -e "${BLUE}Reset cancelled${NC}"
    fi
}

# Main menu
main_menu() {
    while true; do
        echo
        echo -e "${BLUE}================================${NC}"
        echo -e "${BLUE}        TROUBLESHOOT MENU        ${NC}"
        echo -e "${BLUE}================================${NC}"
        echo -e "1. Check system status"
        echo -e "2. Kill stuck processes"
        echo -e "3. Fix package manager"
        echo -e "4. Check network"
        echo -e "5. Check ports"
        echo -e "6. Clean up system"
        echo -e "7. Manual install packages"
        echo -e "8. Show recent logs"
        echo -e "9. Reset everything"
        echo -e "0. Exit"
        echo
        read -p "Choose option (0-9): " choice
        
        case $choice in
            1) check_system ;;
            2) kill_stuck_processes ;;
            3) fix_package_manager ;;
            4) check_network ;;
            5) check_ports ;;
            6) cleanup ;;
            7) manual_install ;;
            8) show_logs ;;
            9) reset_all ;;
            0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Auto-fix function
auto_fix() {
    echo -e "${YELLOW}🚀 Running auto-fix...${NC}"
    
    check_system
    kill_stuck_processes
    fix_package_manager
    check_network
    check_ports
    cleanup
    
    echo -e "${GREEN}✅ Auto-fix completed${NC}"
    echo -e "${BLUE}Try running the installer again${NC}"
}

# Check if auto-fix argument provided
if [ "$1" = "auto" ]; then
    auto_fix
else
    main_menu
fi
