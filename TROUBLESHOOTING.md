# 🔧 AlrelShop API Panel - Troubleshooting Guide

## 🚨 **Common Installation Issues & Solutions**

### **1. Installation Stuck on Package Update**

**Problem**: Installer stuck pada proses `apt-get update` atau package installation

**Quick Fix**:
```bash
# Jalankan quick fix script
chmod +x install/quick-fix.sh
./install/quick-fix.sh

# Atau jalankan manual
pkill -f apt
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
dpkg --configure -a
apt-get install -f -y
```

**Full Fix**:
```bash
# Jalankan troubleshooting script
chmod +x install/troubleshoot.sh
./install/troubleshoot.sh

# Pilih option 2 (Kill stuck processes) dan 3 (Fix package manager)
```

### **2. Port Already in Use**

**Problem**: Error "Address already in use" atau port 5000/80 sudah digunakan

**Solution**:
```bash
# Check what's using the port
netstat -tlnp | grep :5000
netstat -tlnp | grep :80

# Kill the process
fuser -k 5000/tcp
fuser -k 80/tcp

# Or use the troubleshooting script
./install/troubleshoot.sh
# Pilih option 5 (Check ports)
```

### **3. Python Dependencies Installation Failed**

**Problem**: Error saat install Python packages atau virtual environment

**Solution**:
```bash
# Check Python version
python3 --version

# Install Python packages manually
apt-get install -y python3 python3-pip python3-venv python3-dev build-essential

# Create virtual environment manually
cd /etc/API-Panel
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask flask-cors
```

### **4. Service Won't Start**

**Problem**: API Panel service failed to start

**Solution**:
```bash
# Check service status
systemctl status api-panel

# Check logs
journalctl -u api-panel -f

# Check if Python file exists
ls -la /etc/API-Panel/api/main_api.py

# Check permissions
chmod +x /etc/API-Panel/api/main_api.py
chown -R root:root /etc/API-Panel
```

### **5. Nginx Configuration Error**

**Problem**: Nginx failed to start or configuration invalid

**Solution**:
```bash
# Test nginx config
nginx -t

# Check nginx status
systemctl status nginx

# Remove conflicting configs
rm -f /etc/nginx/sites-enabled/default

# Restart nginx
systemctl restart nginx
```

## 🛠️ **Available Troubleshooting Scripts**

### **1. Quick Fix Script** (`install/quick-fix.sh`)
**Purpose**: Fast fix for common issues
```bash
chmod +x install/quick-fix.sh
./install/quick-fix.sh
```

**What it does**:
- Kill stuck processes
- Fix package manager locks
- Clean up system
- Free up ports

### **2. Robust Installer** (`install/robust-install.sh`)
**Purpose**: More reliable installation with better error handling
```bash
chmod +x install/robust-install.sh
./install/robust-install.sh
```

**Features**:
- Better error handling
- Detailed logging
- Step-by-step installation
- Automatic cleanup

### **3. Troubleshooting Script** (`install/troubleshoot.sh`)
**Purpose**: Interactive troubleshooting with multiple options
```bash
chmod +x install/troubleshoot.sh
./install/troubleshoot.sh

# Or run auto-fix
./install/troubleshoot.sh auto
```

**Options**:
1. Check system status
2. Kill stuck processes
3. Fix package manager
4. Check network
5. Check ports
6. Clean up system
7. Manual install packages
8. Show recent logs
9. Reset everything

## 🔍 **Diagnostic Commands**

### **System Information**
```bash
# OS info
cat /etc/os-release
lsb_release -a

# System resources
free -h
df -h
top

# Network
ip addr show
ping 8.8.8.8
```

### **Service Status**
```bash
# Check all services
systemctl list-units --type=service --state=failed

# Check specific service
systemctl status api-panel
systemctl status nginx

# Check ports
netstat -tlnp
ss -tlnp
```

### **Log Files**
```bash
# System logs
journalctl -f
journalctl -u api-panel -f

# Package manager logs
tail -f /var/log/apt/history.log
tail -f /var/log/dpkg.log

# API Panel logs
tail -f /var/log/api-panel-install.log
```

## 🚀 **Step-by-Step Recovery**

### **Step 1: Stop Everything**
```bash
# Stop services
systemctl stop api-panel 2>/dev/null
systemctl stop nginx 2>/dev/null

# Kill processes
pkill -f python
pkill -f nginx
```

### **Step 2: Clean Up**
```bash
# Remove locks
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*

# Clean package cache
apt-get clean
apt-get autoremove -y
```

### **Step 3: Fix Packages**
```bash
# Fix broken packages
dpkg --configure -a
apt-get install -f -y

# Update system
apt-get update
```

### **Step 4: Reinstall**
```bash
# Use robust installer
./install/robust-install.sh
```

## 📋 **Prevention Tips**

### **Before Installation**
1. **Check system resources**: Ensure you have at least 1GB RAM and 10GB disk space
2. **Update system**: Run `apt-get update && apt-get upgrade -y` first
3. **Check network**: Ensure stable internet connection
4. **Close other services**: Stop unnecessary services that might use ports 80/5000

### **During Installation**
1. **Don't interrupt**: Let the installer complete
2. **Monitor logs**: Check `/var/log/api-panel-install.log`
3. **Check progress**: Watch for any error messages

### **After Installation**
1. **Test services**: Verify both API Panel and Nginx are running
2. **Check ports**: Ensure ports 80 and 5000 are accessible
3. **Test API**: Use `curl http://localhost:5000/` to test

## 🆘 **Getting Help**

### **If Nothing Works**
1. **Reset everything**:
   ```bash
   ./install/troubleshoot.sh
   # Choose option 9 (Reset everything)
   ```

2. **Start fresh**:
   ```bash
   rm -rf /etc/API-Panel
   git clone <your-repo> /etc/API-Panel
   cd /etc/API-Panel
   ./install/robust-install.sh
   ```

### **Collect Information for Support**
```bash
# System info
uname -a
cat /etc/os-release
free -h
df -h

# Service status
systemctl status api-panel
systemctl status nginx

# Recent logs
journalctl -u api-panel -n 50
tail -50 /var/log/api-panel-install.log

# Network info
ip addr show
netstat -tlnp
```

## 🎯 **Quick Solutions by Error Type**

| Error | Quick Solution |
|-------|----------------|
| `E: Could not get lock` | `./install/quick-fix.sh` |
| `Address already in use` | `fuser -k 5000/tcp` |
| `Service failed to start` | Check logs with `journalctl -u api-panel -f` |
| `Package not found` | `apt-get update && apt-get install -y <package>` |
| `Permission denied` | `chown -R root:root /etc/API-Panel` |
| `Python import error` | Recreate virtual environment |

---

## 🎉 **Success Indicators**

Your installation is successful when you see:
- ✅ `API Panel service started`
- ✅ `Nginx service started`
- ✅ `API is responding (HTTP 200)`
- ✅ `INSTALASI SELESAI!`

**Test your API**:
```bash
curl http://localhost:5000/
# Should return JSON response

curl -H "X-API-Key: alrelshop-secret-api-key-2024" http://localhost:5000/api/status
# Should return API status
```

**Good luck with your installation!** 🚀
