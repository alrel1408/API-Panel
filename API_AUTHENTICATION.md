# API Authentication Guide

## Overview
API Panel menggunakan API key authentication untuk mengamankan semua endpoint. Setiap request ke endpoint yang memerlukan autentikasi harus menyertakan API key yang valid.

## API Key
API key default: `alrelshop-secret-api-key-2024`

**⚠️ PENTING:** Ganti API key default ini sebelum deploy ke production!

## Cara Menggunakan Authentication

### 1. Menggunakan X-API-Key Header
```bash
curl -H "X-API-Key: alrelshop-secret-api-key-2024" \
     -X GET http://localhost:5000/api/ssh/list
```

### 2. Menggunakan Authorization Bearer Header
```bash
curl -H "Authorization: Bearer alrelshop-secret-api-key-2024" \
     -X GET http://localhost:5000/api/ssh/list
```

### 3. Menggunakan URL Parameter (tidak direkomendasikan untuk production)
```bash
curl -X GET "http://localhost:5000/api/ssh/list?api_key=alrelshop-secret-api-key-2024"
```

## Endpoints yang Tidak Memerlukan Authentication

- `GET /` - Homepage API
- `GET /api/status` - Status API (tanpa detail sensitif)
- `GET /api/system/status` - Status sistem dasar

## Endpoints yang Memerlukan Authentication

Semua endpoint berikut memerlukan API key yang valid:

### SSH Endpoints
- `POST /api/ssh/create`
- `POST /api/ssh/trial` 
- `GET /api/ssh/list`
- `POST /api/ssh/delete`
- `POST /api/ssh/renew`

### VMess Endpoints
- `POST /api/vmess/create`
- `POST /api/vmess/trial`
- `GET /api/vmess/list`
- `POST /api/vmess/delete`
- `POST /api/vmess/renew`

### VLess Endpoints
- `POST /api/vless/create`
- `POST /api/vless/trial`
- `GET /api/vless/list`
- `POST /api/vless/delete`
- `POST /api/vless/renew`

### Shadowsocks Endpoints
- `POST /api/shadowsocks/create`
- `POST /api/shadowsocks/trial`
- `GET /api/shadowsocks/list`
- `POST /api/shadowsocks/delete`
- `POST /api/shadowsocks/renew`

### Trojan Endpoints
- `POST /api/trojan/create`
- `POST /api/trojan/trial`
- `GET /api/trojan/list`
- `POST /api/trojan/delete`
- `POST /api/trojan/renew`

### Trial Management Endpoints
- `POST /api/trial/create`
- `GET /api/trial/list`
- `POST /api/trial/delete`

## Response untuk Authentication Error

### Missing API Key (401)
```json
{
  "success": false,
  "message": "Missing API key. Provide in X-API-Key header, Authorization: Bearer <token>, or api_key parameter",
  "error": "MISSING_API_KEY"
}
```

### Invalid API Key (401)
```json
{
  "success": false,
  "message": "Invalid API key",
  "error": "INVALID_API_KEY"
}
```

## Mengubah API Key

1. Edit file konfigurasi:
```bash
sudo nano /etc/API-Panel/config/api_config.json
```

2. Ubah nilai `api_key`:
```json
{
  "security": {
    "authentication": {
      "enabled": true,
      "type": "bearer",
      "api_key": "your-new-secret-api-key-here"
    }
  }
}
```

3. Restart service:
```bash
sudo systemctl restart api-panel
```

## Menonaktifkan Authentication (tidak direkomendasikan)

Untuk development saja, bisa disable authentication:

```json
{
  "security": {
    "authentication": {
      "enabled": false,
      "type": "bearer",
      "api_key": "your-api-key"
    }
  }
}
```

**⚠️ WARNING:** Jangan disable authentication di production!

## Testing Authentication

Gunakan script test untuk memverifikasi authentication:

```bash
python3 scripts/test_api.py
```

Script ini akan menguji:
- Request tanpa API key (harus ditolak)
- Request dengan API key invalid (harus ditolak)
- Request dengan API key valid menggunakan X-API-Key header
- Request dengan API key valid menggunakan Bearer token

## Contoh Penggunaan dengan Python

```python
import requests

# Configuration
BASE_URL = "http://localhost:5000"
API_KEY = "alrelshop-secret-api-key-2024"

# Menggunakan X-API-Key header
headers = {"X-API-Key": API_KEY}
response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers)

# Menggunakan Authorization Bearer
headers = {"Authorization": f"Bearer {API_KEY}"}
response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers)

# Create SSH account
data = {
    "username": "testuser",
    "password": "testpass123",
    "days": 30,
    "ip_limit": 2,
    "quota_gb": 10
}
response = requests.post(f"{BASE_URL}/api/ssh/create", json=data, headers=headers)
```

## Security Best Practices

1. **Gunakan HTTPS** di production
2. **Ganti API key default** sebelum deploy
3. **Gunakan API key yang kuat** (minimal 32 karakter, random)
4. **Jangan expose API key** di logs atau repository
5. **Rotasi API key** secara berkala
6. **Monitor API usage** untuk mendeteksi abuse
7. **Gunakan rate limiting** untuk mencegah brute force

## Troubleshooting

### API Key Tidak Diterima
1. Pastikan format header benar
2. Cek API key di config file
3. Restart service setelah mengubah config
4. Cek logs: `journalctl -u api-panel -f`

### Service Tidak Start
1. Cek syntax JSON di config file
2. Cek permission file config
3. Cek logs untuk error message

### Test Authentication
```bash
# Test tanpa API key (harus 401)
curl -X GET http://localhost:5000/api/ssh/list

# Test dengan API key (harus 200)
curl -H "X-API-Key: alrelshop-secret-api-key-2024" \
     -X GET http://localhost:5000/api/ssh/list
```
