# 🚀 AlrelShop API Panel - GitHub Setup Guide

## 📋 Overview

Guide ini menjelaskan cara setup AlrelShop API Panel langsung dari GitHub repository. API Panel ini sudah dilengkapi dengan **API Key Authentication** untuk keamanan.

## 🔐 Security Features

### ✅ **API Key Authentication**
- **Default API Key**: `alrelshop-secret-api-key-2024`
- **Header**: `X-API-Key: YOUR_API_KEY`
- **Parameter**: `?api_key=YOUR_API_KEY`
- **Semua endpoint sensitif memerlukan API Key**

### 🛡️ **Protected Endpoints**
- ✅ SSH Management (create, trial, list, delete, renew)
- ✅ VMess Management (create, trial, list, delete, renew)
- ✅ VLess Management (create, trial, list, delete, renew)
- ✅ Shadowsocks Management (create, trial, list, delete, renew)
- ✅ Trojan Management (create, trial, list, delete, renew)
- ✅ Trial Management (create, list, delete)
- ❌ System Restart (disabled for security)

### 🔓 **Public Endpoints**
- ✅ Health Check (`/health`)
- ✅ System Status (`/api/system/status`)
- ✅ Homepage (`/`)

## 🚀 Quick Setup

### **Method 1: Simple Setup (Recommended)**

```bash
# 1. SSH ke VPS
ssh root@your-vps-ip

# 2. Download dan jalankan setup script
curl -sSL https://raw.githubusercontent.com/your-username/alrelshop-api-panel/main/install/simple-github-setup.sh | bash

# 3. Masukkan URL GitHub repository ketika diminta
# Contoh: https://github.com/your-username/alrelshop-api-panel
```

### **Method 2: Manual Setup**

```bash
# 1. SSH ke VPS
ssh root@your-vps-ip

# 2. Install dependencies
apt-get update && apt-get install -y git python3 python3-pip python3-venv nginx curl wget

# 3. Clone repository
cd /etc
git clone https://github.com/your-username/alrelshop-api-panel.git API-Panel

# 4. Setup Python environment
cd API-Panel
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Create systemd service
cat > /etc/systemd/system/api-panel.service << 'EOF'
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

# 6. Start service
systemctl daemon-reload
systemctl enable api-panel
systemctl start api-panel
```

## 🔑 API Key Configuration

### **Default Configuration**
```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "type": "bearer",
      "api_key": "alrelshop-secret-api-key-2024"
    }
  }
}
```

### **Customize API Key**
```bash
# Edit config file
nano /etc/API-Panel/config/api_config.json

# Restart service setelah perubahan
systemctl restart api-panel
```

### **Disable Authentication (Not Recommended)**
```json
{
  "security": {
    "authentication": {
      "enabled": false
    }
  }
}
```

## 🌐 Testing API

### **1. Health Check (No Auth Required)**
```bash
curl http://localhost:5000/health
# Expected: "OK"
```

### **2. Test Protected Endpoint (With API Key)**
```bash
# Method 1: Header
curl -H "X-API-Key: alrelshop-secret-api-key-2024" \
     http://localhost:5000/api/ssh/list

# Method 2: Parameter
curl "http://localhost:5000/api/ssh/list?api_key=alrelshop-secret-api-key-2024"
```

### **3. Test Without API Key (Should Fail)**
```bash
curl http://localhost:5000/api/ssh/list
# Expected: 401 Unauthorized
```

## 📱 Postman Collection

### **Import Collection**
1. Download `postman_collection.json`
2. Import ke Postman
3. Set variables:
   - `base_url`: `http://your-vps-ip:5000`
   - `api_key`: `alrelshop-secret-api-key-2024`

### **Test All Endpoints**
- ✅ **SSH Management** - Create, trial, list, delete, renew
- ✅ **VMess Management** - Create, trial, list, delete, renew
- ✅ **VLess Management** - Create, trial, list, delete, renew
- ✅ **Shadowsocks Management** - Create, trial, list, delete, renew
- ✅ **Trojan Management** - Create, trial, list, delete, renew
- ✅ **Trial Management** - Create, list, delete

## 🛠️ Management Commands

### **Service Control**
```bash
# Start service
systemctl start api-panel

# Stop service
systemctl stop api-panel

# Restart service
systemctl restart api-panel

# Check status
systemctl status api-panel

# View logs
journalctl -u api-panel -f
```

### **Utility Scripts**
```bash
# Check status
/etc/API-Panel/scripts/status.sh

# Create backup
/etc/API-Panel/scripts/backup.sh

# Test API
python3 /etc/API-Panel/scripts/test_api.py
```

## 🔧 Troubleshooting

### **Common Issues**

#### 1. **Service Won't Start**
```bash
# Check logs
journalctl -u api-panel -f

# Check Python environment
/etc/API-Panel/venv/bin/python --version

# Check dependencies
/etc/API-Panel/venv/bin/pip list
```

#### 2. **API Key Not Working**
```bash
# Verify config
cat /etc/API-Panel/config/api_config.json | grep api_key

# Check service is running
systemctl status api-panel

# Test with curl
curl -H "X-API-Key: alrelshop-secret-api-key-2024" \
     http://localhost:5000/api/status
```

#### 3. **Port Already in Use**
```bash
# Check what's using port 5000
netstat -tlnp | grep :5000

# Kill process if needed
kill -9 <PID>

# Restart service
systemctl restart api-panel
```

### **Debug Commands**
```bash
# Check API Panel directory
ls -la /etc/API-Panel/

# Check Python files
ls -la /etc/API-Panel/api/

# Check config
cat /etc/API-Panel/config/api_config.json

# Check logs
tail -f /var/log/api-panel.log
```

## 📚 Documentation

### **Available Files**
- **README.md** - Complete documentation
- **GITHUB_SETUP.md** - This file
- **INSTALLATION_SUMMARY.md** - Installation overview
- **postman_collection.json** - API testing collection

### **Directory Structure**
```
/etc/API-Panel/
├── api/                    # Main API application
├── config/                 # Configuration files
├── install/                # Installation scripts
├── scripts/                # Utility scripts
├── docs/                   # Documentation
├── requirements.txt        # Python dependencies
└── postman_collection.json # Postman collection
```

## 🔄 Updates

### **Update from GitHub**
```bash
cd /etc/API-Panel

# Backup current version
scripts/backup.sh

# Pull latest changes
git pull origin main

# Restart service
systemctl restart api-panel

# Test API
python3 scripts/test_api.py
```

### **Rollback if Issues**
```bash
# Stop service
systemctl stop api-panel

# Restore from backup
tar -xzf /root/backup-api-panel/api-panel-backup-*.tar.gz -C /

# Restart service
systemctl daemon-reload
systemctl start api-panel
```

## 🆘 Support

### **Getting Help**
- Check logs: `journalctl -u api-panel -f`
- Check status: `scripts/status.sh`
- Test endpoints: `scripts/test_api.py`
- Review documentation: `docs/README.md`

### **Bug Reports**
- Include error logs
- Describe steps to reproduce
- Provide system information
- Include configuration details

---

## 🎉 Congratulations!

Your AlrelShop API Panel has been successfully set up from GitHub with enhanced security features!

**Key Benefits:**
- ✅ **Secure by Default** - API Key authentication enabled
- ✅ **Easy Setup** - Simple GitHub clone and install
- ✅ **Production Ready** - Professional quality code
- ✅ **Complete VPN Management** - All services in one API
- ✅ **Comprehensive Testing** - Postman collection included

**Ready to use?** Test your API endpoints and start managing VPN services! 🚀
