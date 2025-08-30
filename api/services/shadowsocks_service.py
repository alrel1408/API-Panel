#!/usr/bin/env python3
"""
Shadowsocks Service Module untuk AlrelShop API Panel
Mengintegrasikan fungsi-fungsi dari script m-ssws
"""

import subprocess
import json
import os
import re
import uuid
import base64
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class ShadowsocksService:
    def __init__(self):
        self.domain = self._get_domain()
        self.config_path = "/etc/xray/config.json"
        self.ss_db_path = "/etc/shadowsocks/.shadowsocks.db"
        self.limit_ip_path = "/etc/kyt/limit/shadowsocks/ip"
        self.web_path = "/var/www/html"
        
    def _get_domain(self):
        """Get domain dari config"""
        try:
            with open("/etc/xray/domain", "r") as f:
                return f.read().strip()
        except:
            return "localhost"
    
    def _get_server_info(self):
        """Get server information"""
        try:
            with open("/etc/xray/isp", "r") as f:
                isp = f.read().strip()
        except:
            isp = "Unknown"
            
        try:
            with open("/etc/xray/city", "r") as f:
                city = f.read().strip()
        except:
            city = "Unknown"
            
        try:
            with open("/root/nsdomain", "r") as f:
                ns = f.read().strip()
        except:
            ns = "Unknown"
            
        try:
            with open("/etc/slowdns/server.pub", "r") as f:
                pub = f.read().strip()
        except:
            pub = "Unknown"
            
        return {
            "isp": isp,
            "city": city,
            "ns": ns,
            "pub": pub
        }
    
    def create_account(self, data):
        """Create Shadowsocks account baru"""
        try:
            username = data.get('username')
            days = data.get('days', 30)
            quota_gb = data.get('quota_gb', 0)
            cipher = data.get('cipher', 'aes-128-gcm')
            
            if not username:
                return {"status": "error", "message": "Username harus diisi"}
            
            # Check if user exists
            if self._user_exists(username):
                return {"status": "error", "message": "Username sudah ada"}
            
            # Generate password
            password = str(uuid.uuid4())
            
            # Calculate expiry
            expiry_date = datetime.now() + timedelta(days=days)
            expiry_str = expiry_date.strftime("%Y-%m-%d")
            
            # Add to Xray config
            self._add_to_xray_config(username, password, cipher, expiry_str)
            
            # Setup quota
            if quota_gb > 0:
                quota_bytes = quota_gb * 1024 * 1024 * 1024
                os.makedirs("/etc/shadowsocks", exist_ok=True)
                with open(f"/etc/shadowsocks/{username}", "w") as f:
                    f.write(str(quota_bytes))
            
            # Add to database
            self._add_to_db(username, expiry_str, password)
            
            # Create config file
            self._create_config_file(username, password, cipher, quota_gb, days)
            
            # Send to Telegram bot
            self._send_telegram_notification(username, password, cipher, quota_gb, days)
            
            # Restart Xray
            subprocess.run(['systemctl', 'restart', 'xray'], check=True)
            
            return {
                "status": "success",
                "message": "Shadowsocks account berhasil dibuat",
                "data": {
                    "username": username,
                    "password": password,
                    "cipher": cipher,
                    "expiry": expiry_str,
                    "quota_gb": quota_gb,
                    "config_url": f"https://{self.domain}:81/sodosokws-{username}.txt"
                }
            }
            
        except Exception as e:
            logger.error(f"Error creating Shadowsocks account: {e}")
            return {"status": "error", "message": str(e)}
    
    def create_trial(self, data):
        """Create trial Shadowsocks account"""
        try:
            minutes = data.get('minutes', 60)
            username = f"WV-{uuid.uuid4().hex[:3].upper()}"
            password = str(uuid.uuid4())
            cipher = "aes-128-gcm"
            quota_gb = 5
            
            # Calculate expiry
            expiry_date = datetime.now() + timedelta(minutes=minutes)
            expiry_str = expiry_date.strftime("%Y-%m-%d")
            
            # Add to Xray config
            self._add_to_xray_config(username, password, cipher, expiry_str)
            
            # Setup quota
            quota_bytes = quota_gb * 1024 * 1024 * 1024
            os.makedirs("/etc/shadowsocks", exist_ok=True)
            with open(f"/etc/shadowsocks/{username}", "w") as f:
                f.write(str(quota_bytes))
            
            # Add to database
            self._add_to_db(username, expiry_str, password)
            
            # Create config file
            self._create_config_file(username, password, cipher, quota_gb, minutes, is_trial=True)
            
            # Send to Telegram bot
            self._send_telegram_notification(username, password, cipher, quota_gb, minutes, is_trial=True)
            
            # Restart Xray
            subprocess.run(['systemctl', 'restart', 'xray'], check=True)
            
            return {
                "status": "success",
                "message": "Trial Shadowsocks account berhasil dibuat",
                "data": {
                    "username": username,
                    "password": password,
                    "cipher": cipher,
                    "expiry_minutes": minutes,
                    "quota_gb": quota_gb,
                    "config_url": f"https://{self.domain}:81/sodosokws-{username}.txt"
                }
            }
            
        except Exception as e:
            logger.error(f"Error creating trial Shadowsocks account: {e}")
            return {"status": "error", "message": str(e)}
    
    def list_accounts(self):
        """List semua Shadowsocks accounts"""
        try:
            accounts = []
            
            if os.path.exists(self.ss_db_path):
                with open(self.ss_db_path, "r") as f:
                    for line in f:
                        if line.startswith("### "):
                            parts = line.strip().split()
                            if len(parts) >= 3:
                                username = parts[1]
                                expiry = parts[2]
                                password = parts[3]
                                
                                accounts.append({
                                    "username": username,
                                    "expiry": expiry,
                                    "password": password,
                                    "status": self._get_account_status(username, expiry)
                                })
            
            return {
                "status": "success",
                "data": accounts,
                "total": len(accounts)
            }
            
        except Exception as e:
            logger.error(f"Error listing Shadowsocks accounts: {e}")
            return {"status": "error", "message": str(e)}
    
    def delete_account(self, data):
        """Delete Shadowsocks account"""
        try:
            username = data.get('username')
            
            if not username:
                return {"status": "error", "message": "Username harus diisi"}
            
            # Remove from Xray config
            self._remove_from_xray_config(username)
            
            # Remove from database
            self._remove_from_db(username)
            
            # Remove files
            for path in [f"/etc/shadowsocks/{username}", f"{self.web_path}/sodosokws-{username}.txt", f"{self.web_path}/oc-sodosokws-{username}.txt", f"{self.web_path}/sodosokgrpc-{username}.txt"]:
                if os.path.exists(path):
                    os.remove(path)
            
            # Restart Xray
            subprocess.run(['systemctl', 'restart', 'xray'], check=True)
            
            return {
                "status": "success",
                "message": f"Shadowsocks account {username} berhasil dihapus"
            }
            
        except Exception as e:
            logger.error(f"Error deleting Shadowsocks account: {e}")
            return {"status": "error", "message": str(e)}
    
    def renew_account(self, data):
        """Renew Shadowsocks account"""
        try:
            username = data.get('username')
            days = data.get('days', 30)
            
            if not username:
                return {"status": "error", "message": "Username harus diisi"}
            
            # Calculate new expiry
            expiry_date = datetime.now() + timedelta(days=days)
            expiry_str = expiry_date.strftime("%Y-%m-%d")
            
            # Update Xray config
            self._update_xray_config(username, expiry_str)
            
            # Update database
            self._update_db(username, expiry_str)
            
            # Restart Xray
            subprocess.run(['systemctl', 'restart', 'xray'], check=True)
            
            return {
                "status": "success",
                "message": f"Shadowsocks account {username} berhasil diperpanjang",
                "data": {
                    "username": username,
                    "expiry": expiry_str,
                    "days": days
                }
            }
            
        except Exception as e:
            logger.error(f"Error renewing Shadowsocks account: {e}")
            return {"status": "error", "message": str(e)}
    
    def get_info(self):
        """Get Shadowsocks service info"""
        try:
            total_accounts = len(self.list_accounts().get('data', []))
            active_accounts = len([acc for acc in self.list_accounts().get('data', []) if acc.get('status') == 'active'])
            
            return {
                "status": "running",
                "total_accounts": total_accounts,
                "active_accounts": active_accounts,
                "domain": self.domain
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
    
    def _user_exists(self, username):
        """Check if user exists in Xray config"""
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, "r") as f:
                    content = f.read()
                    return f'"email": "{username}"' in content
            return False
        except:
            return False
    
    def _add_to_xray_config(self, username, password, cipher, expiry_str):
        """Add user to Xray config using sed like original script"""
        try:
            # Use sed command like original script for shadowsocks WS
            ss_ws_entry = f'#!! {username} {expiry_str}\n}},{{"password": "{password}","method": "{cipher}","email": "{username}"}}'
            subprocess.run([
                'sed', '-i', f'/#ssws$/a\\{ss_ws_entry}',
                self.config_path
            ], check=True)
            
            # Use sed command like original script for shadowsocks gRPC  
            ss_grpc_entry = f'#&! {username} {expiry_str}\n}},{{"password": "{password}","method": "{cipher}","email": "{username}"}}'
            subprocess.run([
                'sed', '-i', f'/#ssgrpc$/a\\{ss_grpc_entry}',
                self.config_path
            ], check=True)
                
        except Exception as e:
            logger.error(f"Error adding to Xray config: {e}")
            raise
    
    def _remove_from_xray_config(self, username):
        """Remove user from Xray config using sed like original script"""
        try:
            # Get expiry for the user
            expiry = self._get_user_expiry(username)
            if expiry:
                # Remove shadowsocks WS entry
                subprocess.run([
                    'sed', '-i', f'/^#!! {username} {expiry}/,/^}},{{/d',
                    self.config_path
                ], check=True)
                
                # Remove shadowsocks gRPC entry
                subprocess.run([
                    'sed', '-i', f'/^#&! {username} {expiry}/,/^}},{{/d',
                    self.config_path
                ], check=True)
                
        except Exception as e:
            logger.error(f"Error removing from Xray config: {e}")
            raise
    
    def _update_xray_config(self, username, new_expiry):
        """Update user expiry in Xray config using sed like original script"""
        try:
            # Update shadowsocks WS entry
            subprocess.run([
                'sed', '-i', f'/^#!! {username}/c\\#!! {username} {new_expiry}',
                self.config_path
            ], check=True)
            
            # Update shadowsocks gRPC entry  
            subprocess.run([
                'sed', '-i', f'/^#&! {username}/c\\#&! {username} {new_expiry}',
                self.config_path
            ], check=True)
                
        except Exception as e:
            logger.error(f"Error updating Xray config: {e}")
            raise
    
    def _get_user_expiry(self, username):
        """Get user expiry from database"""
        try:
            if os.path.exists(self.ss_db_path):
                with open(self.ss_db_path, "r") as f:
                    for line in f:
                        if line.startswith(f"### {username} "):
                            parts = line.strip().split()
                            if len(parts) >= 3:
                                return parts[2]
            return None
        except:
            return None
    
    def _add_to_db(self, username, expiry, password):
        """Add user to database"""
        os.makedirs("/etc/shadowsocks", exist_ok=True)
        
        # Remove existing entry if any
        self._remove_from_db(username)
        
        # Add new entry
        with open(self.ss_db_path, "a") as f:
            f.write(f"### {username} {expiry} {password}\n")
    
    def _remove_from_db(self, username):
        """Remove user from database"""
        if os.path.exists(self.ss_db_path):
            lines = []
            with open(self.ss_db_path, "r") as f:
                for line in f:
                    if not line.startswith(f"### {username} "):
                        lines.append(line)
            
            with open(self.ss_db_path, "w") as f:
                f.writelines(lines)
    
    def _update_db(self, username, new_expiry):
        """Update user expiry in database"""
        if os.path.exists(self.ss_db_path):
            lines = []
            with open(self.ss_db_path, "r") as f:
                for line in f:
                    if line.startswith(f"### {username} "):
                        parts = line.strip().split()
                        if len(parts) >= 3:
                            parts[2] = new_expiry
                            lines.append(" ".join(parts) + "\n")
                    else:
                        lines.append(line)
            
            with open(self.ss_db_path, "w") as f:
                f.writelines(lines)
    
    def _get_account_status(self, username, expiry):
        """Get account status (active/expired)"""
        try:
            expiry_date = datetime.strptime(expiry, "%Y-%m-%d")
            if datetime.now() < expiry_date:
                return 'active'
            else:
                return 'expired'
        except:
            return 'unknown'
    
    def _create_config_file(self, username, password, cipher, quota_gb, duration, is_trial=False):
        """Create Shadowsocks config file"""
        server_info = self._get_server_info()
        
        # Generate Shadowsocks links
        ss_base64 = base64.b64encode(f"{cipher}:{password}".encode()).decode()
        
        ss_ws_tls = f"ss://{ss_base64}@{self.domain}:443?path=/ss-ws&security=tls&encryption=none&type=ws#{username}"
        ss_ws_nontls = f"ss://{ss_base64}@{self.domain}:80?path=/ss-ws&security=none&encryption=none&type=ws#{username}"
        ss_grpc = f"ss://{ss_base64}@{self.domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=ss-grpc&sni={self.domain}#{username}"
        
        duration_text = f"{duration} Menit" if is_trial else f"{duration} Hari"
        
        config_content = f"""◇━━━━━━━━━━━━━━━━━◇
Shadowsocks Account        
◇━━━━━━━━━━━━━━━━━◇
Remarks          : {username}
Domain           : {self.domain}
User Quota       : {quota_gb} GB
Port TLS         : 400-900
Password         : {password}
Cipers           : {cipher}
Network          : ws/grpc
Path             : /ss-ws
ServiceName      : ss-grpc
Location         : {server_info['city']}
◇━━━━━━━━━━━━━━━━━◇
Link WS TLS : 
{ss_ws_tls}
◇━━━━━━━━━━━━━━━━━◇
Link WS None TLS: 
{ss_ws_nontls}
◇━━━━━━━━━━━━━━━━━◇
Link GRPC: 
{ss_grpc}
◇━━━━━━━━━━━━━━━━━◇
Aktif Selama     : {duration_text}
Dibuat Pada      : {datetime.now().strftime('%d %b %Y')}
Berakhir Pada    : {expiry_date.strftime('%d %b %Y')}
◇━━━━━━━━━━━━━━━━━◇"""
        
        os.makedirs(self.web_path, exist_ok=True)
        with open(f"{self.web_path}/sodosokws-{username}.txt", "w") as f:
            f.write(config_content)
        
        # Create OpenClash config
        self._create_openclash_config(username, password, cipher)
        
        # Create gRPC config
        self._create_grpc_config(username, password, cipher)
    
    def _create_openclash_config(self, username, password, cipher):
        """Create OpenClash config file"""
        config = {
            "dns": {
                "servers": ["8.8.8.8", "8.8.4.4"]
            },
            "inbounds": [
                {
                    "port": 10808,
                    "protocol": "socks",
                    "settings": {
                        "auth": "noauth",
                        "udp": True,
                        "userLevel": 8
                    },
                    "sniffing": {
                        "destOverride": ["http", "tls"],
                        "enabled": True
                    },
                    "tag": "socks"
                },
                {
                    "port": 10809,
                    "protocol": "http",
                    "settings": {"userLevel": 8},
                    "tag": "http"
                }
            ],
            "log": {"loglevel": "none"},
            "outbounds": [
                {
                    "mux": {"enabled": True},
                    "protocol": "shadowsocks",
                    "settings": {
                        "servers": [{
                            "address": self.domain,
                            "level": 8,
                            "method": cipher,
                            "password": password,
                            "port": 443
                        }]
                    },
                    "streamSettings": {
                        "network": "ws",
                        "security": "tls",
                        "tlsSettings": {
                            "allowInsecure": True,
                            "serverName": "isi_bug_disini"
                        },
                        "wsSettings": {
                            "headers": {"Host": self.domain},
                            "path": "/ss-ws"
                        }
                    },
                    "tag": "proxy"
                },
                {"protocol": "freedom", "settings": {}, "tag": "direct"},
                {"protocol": "blackhole", "settings": {"response": {"type": "http"}}, "tag": "block"}
            ],
            "policy": {
                "levels": {
                    "8": {
                        "connIdle": 300,
                        "downlinkOnly": 1,
                        "handshake": 4,
                        "uplinkOnly": 1
                    }
                },
                "system": {
                    "statsOutboundUplink": True,
                    "statsOutboundDownlink": True
                }
            },
            "routing": {"domainStrategy": "Asls", "rules": []},
            "stats": {}
        }
        
        with open(f"{self.web_path}/oc-sodosokws-{username}.txt", "w") as f:
            json.dump(config, f, indent=2)
    
    def _create_grpc_config(self, username, password, cipher):
        """Create gRPC config file"""
        config = {
            "dns": {
                "servers": ["8.8.8.8", "8.8.4.4"]
            },
            "inbounds": [
                {
                    "port": 10808,
                    "protocol": "socks",
                    "settings": {
                        "auth": "noauth",
                        "udp": True,
                        "userLevel": 8
                    },
                    "sniffing": {
                        "destOverride": ["http", "tls"],
                        "enabled": True
                    },
                    "tag": "socks"
                },
                {
                    "port": 10809,
                    "protocol": "http",
                    "settings": {"userLevel": 8},
                    "tag": "http"
                }
            ],
            "log": {"loglevel": "none"},
            "outbounds": [
                {
                    "mux": {"enabled": True},
                    "protocol": "shadowsocks",
                    "settings": {
                        "servers": [{
                            "address": self.domain,
                            "level": 8,
                            "method": cipher,
                            "password": password,
                            "port": 443
                        }]
                    },
                    "streamSettings": {
                        "grpcSettings": {
                            "multiMode": True,
                            "serviceName": "ss-grpc"
                        },
                        "network": "grpc",
                        "security": "tls",
                        "tlsSettings": {
                            "allowInsecure": True,
                            "serverName": "isi_bug_disini"
                        }
                    },
                    "tag": "proxy"
                },
                {"protocol": "freedom", "settings": {}, "tag": "direct"},
                {"protocol": "blackhole", "settings": {"response": {"type": "http"}}, "tag": "block"}
            ],
            "policy": {
                "levels": {
                    "8": {
                        "connIdle": 300,
                        "downlinkOnly": 1,
                        "handshake": 4,
                        "uplinkOnly": 1
                    }
                },
                "system": {
                    "statsOutboundUplink": True,
                    "statsOutboundDownlink": True
                }
            },
            "routing": {"domainStrategy": "Asls", "rules": []},
            "stats": {}
        }
        
        with open(f"{self.web_path}/sodosokgrpc-{username}.txt", "w") as f:
            json.dump(config, f, indent=2)
    
    def _send_telegram_notification(self, username, password, cipher, quota_gb, duration, is_trial=False):
        """Send notification to Telegram bot"""
        try:
            # Get bot config
            bot_config = self._get_bot_config()
            if not bot_config:
                return
            
            server_info = self._get_server_info()
            duration_text = f"{duration} Menit" if is_trial else f"{duration} Hari"
            
            # Generate Shadowsocks links
            ss_base64 = base64.b64encode(f"{cipher}:{password}".encode()).decode()
            ss_ws_tls = f"ss://{ss_base64}@{self.domain}:443?path=/ss-ws&security=tls&encryption=none&type=ws#{username}"
            ss_ws_nontls = f"ss://{ss_base64}@{self.domain}:80?path=/ss-ws&security=none&encryption=none&type=ws#{username}"
            ss_grpc = f"ss://{ss_base64}@{self.domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=ss-grpc&sni={self.domain}#{username}"
            
            message = f"""<code>---------------------------------------------------</code>
<code>      XRAY/SHADOWSOCKS</code>
<code>---------------------------------------------------</code>
<code>Remarks : {username}
Domain : {self.domain}
Host XrayDNS: {server_info['ns']}
Pub Key: {server_info['pub']}
Limit Quota : {quota_gb} GB
Port TLS   : 400-900
Port NTLS : 80, 8080, 8081-9999
Password : {password}
Cipher : {cipher}
network : ws or grpc
Path : /ss-ws
Dynamic : https://bug.com/ss-ws
Name  : ss-grpc</code>
<code>---------------------------------------------------</code>
<code> SHADOWSOCKS WS TLS</code>
<code>---------------------------------------------------</code>
<code>{ss_ws_tls}</code>
<code>---------------------------------------------------</code>
<code>SHADOWSOCKS WS NO TLS</code>
<code>---------------------------------------------------</code>
<code>{ss_ws_nontls}</code>
<code>---------------------------------------------------</code>
<code> SHADOWSOCKS gRPC</code>
<code>---------------------------------------------------</code>
<code>{ss_grpc}</code>
<code>---------------------------------------------------</code>
Format Shadowsocks WS : https://{self.domain}:81/sodosokws-{username}.txt
<code>---------------------------------------------------</code>
Aktif Selama   : {duration_text}
<code>---------------------------------------------------</code>"""
            
            # Send to Telegram
            url = f"https://api.telegram.org/bot{bot_config['key']}/sendMessage"
            data = {
                'chat_id': bot_config['chat_id'],
                'text': message,
                'parse_mode': 'html',
                'disable_web_page_preview': True
            }
            
            subprocess.run(['curl', '-s', '--max-time', '10', '-d', json.dumps(data), url], check=True)
            
        except Exception as e:
            logger.error(f"Error sending Telegram notification: {e}")
    
    def _get_bot_config(self):
        """Get Telegram bot configuration"""
        try:
            if os.path.exists("/etc/bot/.bot.db"):
                with open("/etc/bot/.bot.db", "r") as f:
                    for line in f:
                        if line.startswith("#bot# "):
                            parts = line.strip().split()
                            if len(parts) >= 3:
                                return {
                                    'key': parts[1],
                                    'chat_id': parts[2]
                                }
            return None
        except:
            return None
