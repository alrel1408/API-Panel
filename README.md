# AlrelShop Auto Script - API Panel

API Panel lengkap untuk mengelola semua service VPN berdasarkan script AlrelShop Auto Script.

## 🚀 Fitur Utama

### ✅ **SSH/OVPN Management**
- Create, Delete, Renew, List SSH accounts
- Trial SSH accounts dengan auto-expiry
- IP limit dan quota management
- OVPN config generation

### ✅ **VMess Management**
- Create, Delete, Renew, List VMess accounts
- Trial VMess accounts
- WS/TLS, WS/Non-TLS, gRPC support
- Quota dan IP limit management

### ✅ **VLess Management**
- Create, Delete, Renew, List VLess accounts
- Trial VLess accounts
- WS/TLS dan gRPC support
- Quota dan IP limit management

### ✅ **Shadowsocks Management**
- Create, Delete, Renew, List Shadowsocks accounts
- Trial Shadowsocks accounts
- WS/TLS, WS/Non-TLS, gRPC support
- OpenClash config generation

### ✅ **Trojan Management**
- Create, Delete, Renew, List Trojan accounts
- Trial Trojan accounts
- WS/TLS dan gRPC support
- Quota dan IP limit management

### ✅ **Trial Management**
- Create trial accounts untuk semua service
- Auto-expiry management
- Bulk trial creation

## 📁 Struktur Direktori

```
/etc/API-Panel/
├── api/                          # Main API server
│   ├── main_api.py              # Main Flask application
│   └── services/                # Service modules
│       ├── ssh_service.py       # SSH management
│       ├── vmess_service.py     # VMess management
│       ├── vless_service.py     # VLess management
│       ├── shadowsocks_service.py # Shadowsocks management
│       ├── trojan_service.py    # Trojan management
│       └── trial_service.py     # Trial management
├── config/                       # Configuration files
│   └── api_config.json          # API configuration
├── docs/                         # Documentation
├── scripts/                      # Utility scripts
│   ├── check_status.sh          # Status checker
│   └── backup.sh                # Backup script
├── requirements.txt              # Python dependencies
├── start_api.sh                 # Startup script
└── install/                      # Installation files
    └── install.sh               # Auto-installer
```

## 🛠️ Installation

### 1. **Auto Install (Recommended)**
```bash
# Clone repository
git clone https://github.com/alrel1408/API-Panel.git
cd API-Panel

# Run installer
chmod +x install/install.sh
./install/install.sh
```

### 2. **Manual Install**
```bash
# Create directory
mkdir -p /etc/API-Panel
cd /etc/API-Panel

# Copy files
cp -r api/ config/ docs/ scripts/ ./
cp requirements.txt ./

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create systemd service
# (See install.sh for details)

# Start service
systemctl start api-panel
systemctl enable api-panel
```

## 📡 API Endpoints

### **Base URL**: `http://YOUR_IP:5000/api`

### **SSH Management**
```
POST   /ssh/create      - Create SSH account
POST   /ssh/trial       - Create trial SSH
GET    /ssh/list        - List SSH accounts
POST   /ssh/delete      - Delete SSH account
POST   /ssh/renew       - Renew SSH account
```

### **VMess Management**
```
POST   /vmess/create    - Create VMess account
POST   /vmess/trial     - Create trial VMess
GET    /vmess/list      - List VMess accounts
POST   /vmess/delete    - Delete VMess account
POST   /vmess/renew     - Renew VMess account
```

### **VLess Management**
```
POST   /vless/create    - Create VLess account
POST   /vless/trial     - Create trial VLess
GET    /vless/list      - List VLess accounts
POST   /vless/delete    - Delete VLess account
POST   /vless/renew     - Renew VLess account
```

### **Shadowsocks Management**
```
POST   /shadowsocks/create    - Create Shadowsocks account
POST   /shadowsocks/trial     - Create trial Shadowsocks
GET    /shadowsocks/list      - List Shadowsocks accounts
POST   /shadowsocks/delete    - Delete Shadowsocks account
POST   /shadowsocks/renew     - Renew Shadowsocks account
```

### **Trojan Management**
```
POST   /trojan/create   - Create Trojan account
POST   /trojan/trial    - Create trial Trojan
GET    /trojan/list     - List Trojan accounts
POST   /trojan/delete   - Delete Trojan account
POST   /trojan/renew    - Renew Trojan account
```

### **Trial Management**
```
POST   /trial/create    - Create trial accounts
POST   /trial/delete    - Delete trial account
GET    /trial/list      - List trial accounts
```

### **System Management**
```
GET    /status          - API status
GET    /system/status   - System services status
POST   /system/restart  - Restart system services
```

## 📝 Usage Examples

### **Create SSH Account**
```bash
curl -X POST http://YOUR_IP:5000/api/ssh/create \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user123",
    "password": "password123",
    "days": 30,
    "ip_limit": 2,
    "quota_gb": 10
  }'
```

### **Create Trial VMess**
```bash
curl -X POST http://YOUR_IP:5000/api/vmess/trial \
  -H "Content-Type: application/json" \
  -d '{
    "minutes": 60
  }'
```

### **List All Accounts**
```bash
# List SSH accounts
curl http://YOUR_IP:5000/api/ssh/list

# List VMess accounts
curl http://YOUR_IP:5000/api/vmess/list

# List all trial accounts
curl http://YOUR_IP:5000/api/trial/list
```

## ⚙️ Configuration

### **API Configuration** (`/etc/API-Panel/config/api_config.json`)
```json
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
    }
  },
  "telegram": {
    "enabled": false,
    "bot_token": "",
    "chat_id": ""
  }
}
```

## 🔧 Management Commands

### **Service Management**
```bash
# Start API Panel
systemctl start api-panel

# Stop API Panel
systemctl stop api-panel

# Restart API Panel
systemctl restart api-panel

# Check status
systemctl status api-panel

# View logs
journalctl -u api-panel -f
```

### **Utility Scripts**
```bash
# Check API Panel status
/etc/API-Panel/scripts/check_status.sh

# Backup configuration
/etc/API-Panel/scripts/backup.sh

# Manual start
/etc/API-Panel/start_api.sh
```

## 📊 Monitoring & Logs

### **Log Files**
- **API Logs**: `/var/log/api-panel/api-panel.log`
- **System Logs**: `journalctl -u api-panel`
- **Nginx Logs**: `/var/log/nginx/`

### **Status Monitoring**
```bash
# Check API status
curl http://YOUR_IP:5000/api/status

# Check system services
curl http://YOUR_IP:5000/api/system/status

# Check specific service
curl http://YOUR_IP:5000/api/ssh/list
```

## 🔒 Security Features

### **Built-in Security**
- Input validation dan sanitization
- Error handling yang aman
- Logging untuk audit trail
- Rate limiting (configurable)

### **Network Security**
- Nginx reverse proxy
- Firewall configuration
- Port management
- SSL/TLS support (manual setup)

## 🚨 Troubleshooting

### **Common Issues**

#### **1. API Service Not Starting**
```bash
# Check service status
systemctl status api-panel

# Check logs
journalctl -u api-panel -n 50

# Check Python dependencies
cd /etc/API-Panel
source venv/bin/activate
pip list
```

#### **2. Port Already in Use**
```bash
# Check port usage
netstat -tlnp | grep :5000

# Kill process if needed
sudo fuser -k 5000/tcp

# Restart service
systemctl restart api-panel
```

#### **3. Permission Issues**
```bash
# Fix permissions
chmod +x /etc/API-Panel/api/main_api.py
chmod +x /etc/API-Panel/scripts/*.sh

# Check file ownership
ls -la /etc/API-Panel/
```

### **Debug Mode**
```bash
# Enable debug mode
sed -i 's/"debug": false/"debug": true/' /etc/API-Panel/config/api_config.json

# Restart service
systemctl restart api-panel

# Check detailed logs
tail -f /var/log/api-panel/api-panel.log
```

## 🔄 Updates & Maintenance

### **Backup Configuration**
```bash
# Manual backup
/etc/API-Panel/scripts/backup.sh

# Backup specific files
cp -r /etc/API-Panel/config /root/backup/
cp -r /etc/API-Panel/api /root/backup/
```

### **Update API Panel**
```bash
# Stop service
systemctl stop api-panel

# Backup current version
/etc/API-Panel/scripts/backup.sh

# Update files
# (Copy new files to /etc/API-Panel/)

# Restart service
systemctl start api-panel
```

## 📚 API Documentation

### **Postman Collection**
Import file `postman_collection.json` ke Postman untuk testing lengkap.

### **Swagger/OpenAPI**
API documentation tersedia di `/docs` setelah setup selesai.

## 🤝 Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### **Documentation**
- **API Docs**: `/etc/API-Panel/docs/`
- **Config Examples**: `/etc/API-Panel/config/`
- **Scripts**: `/etc/API-Panel/scripts/`

### **Contact**
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Wiki**: Project Wiki

## 🎯 Roadmap

### **v1.1.0**
- [ ] Web-based admin panel
- [ ] User authentication & authorization
- [ ] Advanced monitoring dashboard
- [ ] Automated backup system

### **v1.2.0**
- [ ] Multi-server support
- [ ] Load balancing
- [ ] High availability setup
- [ ] Advanced analytics

### **v1.3.0**
- [ ] Mobile app support
- [ ] Real-time notifications
- [ ] Advanced reporting
- [ ] Integration APIs

---

**Made with ❤️ by AlrelShop Auto Script Team**
