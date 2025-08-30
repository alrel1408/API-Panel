#!/bin/bash

# AlrelShop API Panel - Quick Fix Script
# Author: AlrelShop Auto Script
# Version: 1.0.0

echo -e "\033[0;34m================================\033[0m"
echo -e "\033[0;34m  AlrelShop API Panel Quick Fix \033[0m"
echo -e "\033[0;34m================================\033[0m"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m❌ Script ini harus dijalankan sebagai root\033[0m"
   echo -e "\033[1;33mJalankan: sudo su -\033[0m"
   exit 1
fi

echo -e "\033[1;33m🚀 Running quick fix...\033[0m"

# Kill stuck processes
echo -e "\033[0;34m🔄 Killing stuck processes...\033[0m"
pkill -f apt
pkill -f dpkg
pkill -f yum
pkill -f dnf
sleep 2

# Fix package manager locks
echo -e "\033[0;34m🔧 Fixing package manager...\033[0m"
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*
rm -f /var/lib/dpkg/lock-frontend

# Fix broken packages
echo -e "\033[0;34m🔧 Fixing broken packages...\033[0m"
dpkg --configure -a 2>/dev/null
apt-get install -f -y 2>/dev/null

# Clean up
echo -e "\033[0;34m🧹 Cleaning up...\033[0m"
apt-get clean 2>/dev/null
apt-get autoremove -y 2>/dev/null

# Check if port 5000 is in use
echo -e "\033[0;34m🔌 Checking ports...\033[0m"
if netstat -tlnp | grep :5000; then
    echo -e "\033[1;33m⚠️  Port 5000 is in use, killing process...\033[0m"
    fuser -k 5000/tcp 2>/dev/null
fi

echo -e "\033[0;32m✅ Quick fix completed!\033[0m"
echo -e "\033[0;34m🔄 Now try running the installer again:\033[0m"
echo -e "\033[0;34m   ./install/robust-install.sh\033[0m"
echo
echo -e "\033[0;32m🎉 Good luck!\033[0m"
