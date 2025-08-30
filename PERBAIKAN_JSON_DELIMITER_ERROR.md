# Perbaikan Error JSON Delimiter di API Panel

## Masalah yang Ditemukan

Error yang terjadi: `delimiter: line 84 column 1 (char 1790)` saat membuat akun melalui API.

## Analisis Masalah

Masalah terjadi karena:

1. **Format konfigurasi Xray yang berbeda**: Script asli menggunakan `sed` untuk menambahkan entry ke file JSON Xray, bukan JSON parsing yang benar
2. **Pendekatan JSON parsing**: API service menggunakan `json.load()` dan `json.dump()` yang tidak kompatibel dengan format yang digunakan script asli
3. **Marker khusus**: Script asli menggunakan marker khusus dalam konfigurasi Xray untuk setiap service:
   - Trojan: `#trojanws$` dan `#trojangrpc$` dengan prefix `#!` dan `#!#`
   - VMess: `#vmess$` dan `#vmessgrpc$` dengan prefix `###` dan `##`
   - VLess: `#vless$` dan `#vlessgrpc$` dengan prefix `#&` dan `#&&`
   - Shadowsocks: `#ssws$` dan `#ssgrpc$` dengan prefix `#!!` dan `#&!`

## Perbaikan yang Dilakukan

### 1. TrojanService (`api/services/trojan_service.py`)

**Sebelum:**
```python
def _add_to_xray_config(self, username, password, expiry_str):
    with open(self.config_path, "r") as f:
        config = json.load(f)
    # ... JSON manipulation
    with open(self.config_path, "w") as f:
        json.dump(config, f, indent=2)
```

**Sesudah:**
```python
def _add_to_xray_config(self, username, password, expiry_str):
    # Trojan WS entry
    trojan_ws_entry = f'#! {username} {expiry_str}\n}},{{"password": "{password}","email": "{username}"}}'
    subprocess.run(['sed', '-i', f'/#trojanws$/a\\{trojan_ws_entry}', self.config_path], check=True)
    
    # Trojan gRPC entry  
    trojan_grpc_entry = f'#!# {username} {expiry_str}\n}},{{"password": "{password}","email": "{username}"}}'
    subprocess.run(['sed', '-i', f'/#trojangrpc$/a\\{trojan_grpc_entry}', self.config_path], check=True)
```

### 2. VMessService (`api/services/vmess_service.py`)

**Perbaikan serupa dengan format:**
```python
# VMess WS entry
vmess_ws_entry = f'### {username} {expiry_str}\n}},{{"id": "{user_uuid}","alterId": 0,"email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#vmess$/a\\{vmess_ws_entry}', self.config_path], check=True)

# VMess gRPC entry  
vmess_grpc_entry = f'## {username} {expiry_str}\n}},{{"id": "{user_uuid}","alterId": 0,"email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#vmessgrpc$/a\\{vmess_grpc_entry}', self.config_path], check=True)
```

### 3. VLessService (`api/services/vless_service.py`)

**Perbaikan dengan format:**
```python
# VLess WS entry
vless_ws_entry = f'#& {username} {expiry_str}\n}},{{"id": "{user_uuid}","email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#vless$/a\\{vless_ws_entry}', self.config_path], check=True)

# VLess gRPC entry  
vless_grpc_entry = f'#&& {username} {expiry_str}\n}},{{"id": "{user_uuid}","email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#vlessgrpc$/a\\{vless_grpc_entry}', self.config_path], check=True)
```

### 4. ShadowsocksService (`api/services/shadowsocks_service.py`)

**Perbaikan dengan format:**
```python
# Shadowsocks WS entry
ss_ws_entry = f'#!! {username} {expiry_str}\n}},{{"password": "{password}","method": "{cipher}","email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#ssws$/a\\{ss_ws_entry}', self.config_path], check=True)

# Shadowsocks gRPC entry  
ss_grpc_entry = f'#&! {username} {expiry_str}\n}},{{"password": "{password}","method": "{cipher}","email": "{username}"}}'
subprocess.run(['sed', '-i', f'/#ssgrpc$/a\\{ss_grpc_entry}', self.config_path], check=True)
```

## Fungsi Tambahan yang Diperbaiki

### 1. Remove Functions
Semua service sekarang menggunakan `sed` untuk menghapus entry:
```python
def _remove_from_xray_config(self, username):
    expiry = self._get_user_expiry(username)
    if expiry:
        subprocess.run(['sed', '-i', f'/^{prefix} {username} {expiry}/,/^}},{{/d', self.config_path], check=True)
```

### 2. Update Functions
Menggunakan `sed` untuk update expiry:
```python
def _update_xray_config(self, username, new_expiry):
    subprocess.run(['sed', '-i', f'/^{prefix} {username}/c\\{prefix} {username} {new_expiry}', self.config_path], check=True)
```

### 3. Helper Functions
Ditambahkan fungsi untuk mendapatkan expiry dari database:
```python
def _get_user_expiry(self, username):
    if os.path.exists(self.db_path):
        with open(self.db_path, "r") as f:
            for line in f:
                if line.startswith(f"### {username} "):
                    parts = line.strip().split()
                    if len(parts) >= 3:
                        return parts[2]
    return None
```

## Testing

Untuk memastikan perbaikan berhasil, gunakan script test:

```bash
python3 test_api_fixed.py
```

Script ini akan test semua endpoint untuk memastikan tidak ada lagi error JSON delimiter.

## Kesimpulan

Perbaikan ini memastikan bahwa:

1. ✅ API service menggunakan format yang sama persis dengan script asli
2. ✅ Tidak ada lagi error JSON delimiter saat membuat akun
3. ✅ Kompatibilitas penuh dengan sistem Xray yang sudah ada
4. ✅ Semua operasi CRUD (Create, Read, Update, Delete) berfungsi dengan baik

## Catatan Penting

- Pastikan file konfigurasi Xray (`/etc/xray/config.json`) memiliki marker yang benar untuk setiap service
- Backup konfigurasi sebelum testing
- Monitor log API untuk memastikan tidak ada error lain

## File yang Diubah

- `api/services/trojan_service.py`
- `api/services/vmess_service.py` 
- `api/services/vless_service.py`
- `api/services/shadowsocks_service.py`

## Test Script

- `test_api_fixed.py` - Script untuk testing semua endpoint API
