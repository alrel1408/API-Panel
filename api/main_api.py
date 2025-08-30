#!/usr/bin/env python3
"""
AlrelShop Auto Script - API Panel
API Server untuk mengelola semua service:
- SSH/OVPN
- VMess
- VLess  
- Shadowsocks
- Trojan
- Trial Management

Author: AlrelShop Auto Script
Version: 1.0.0
"""

from flask import Flask, request, jsonify, g
from flask_cors import CORS
import subprocess
import json
import os
import re
import uuid
from datetime import datetime, timedelta
import logging
import threading
import time
from functools import wraps

# Import semua service modules
from services.ssh_service import SSHService
from services.vmess_service import VMessService
from services.vless_service import VLessService
from services.shadowsocks_service import ShadowsocksService
from services.trojan_service import TrojanService
from services.trial_service import TrialService

app = Flask(__name__)
CORS(app)

# Load configuration
def load_config():
    try:
        with open('/etc/API-Panel/config/api_config.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        # Default config if file not found
        return {
            "security": {
                "authentication": {
                    "enabled": True,
                    "type": "bearer",
                    "api_key": "your-secret-api-key-here"
                }
            }
        }

config = load_config()

# API Key Authentication Decorator
def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not config.get("security", {}).get("authentication", {}).get("enabled", False):
            return f(*args, **kwargs)
        
        api_key = request.headers.get('X-API-Key') or request.args.get('api_key')
        expected_key = config.get("security", {}).get("authentication", {}).get("api_key", "")
        
        if not api_key or api_key != expected_key:
            return jsonify({
                "success": False,
                "message": "Invalid or missing API key",
                "error": "UNAUTHORIZED"
            }), 401
        
        return f(*args, **kwargs)
    return decorated_function

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/api-panel.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize services
ssh_service = SSHService()
vmess_service = VMessService()
vless_service = VLessService()
shadowsocks_service = ShadowsocksService()
trojan_service = TrojanService()
trial_service = TrialService()

class APIPanel:
    def __init__(self):
        self.services = {
            'ssh': ssh_service,
            'vmess': vmess_service,
            'vless': vless_service,
            'shadowsocks': shadowsocks_service,
            'trojan': trojan_service,
            'trial': trial_service
        }
        
    def get_service_info(self):
        """Get info semua service yang tersedia"""
        info = {}
        for service_name, service in self.services.items():
            try:
                info[service_name] = service.get_info()
            except Exception as e:
                logger.error(f"Error getting info for {service_name}: {e}")
                info[service_name] = {"status": "error", "message": str(e)}
        return info

# Initialize API Panel
api_panel = APIPanel()

@app.route('/')
def index():
    """API Panel Homepage"""
    return jsonify({
        "message": "AlrelShop Auto Script - API Panel",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "services": list(api_panel.services.keys())
    })

@app.route('/api/status')
def api_status():
    """Check API status dan semua service"""
    try:
        return jsonify({
            "status": "success",
            "api_status": "running",
            "timestamp": datetime.now().isoformat(),
            "services": api_panel.get_service_info()
        })
    except Exception as e:
        logger.error(f"Error checking API status: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# SSH Endpoints
@app.route('/api/ssh/create', methods=['POST'])
@require_api_key
def create_ssh():
    """Create SSH account"""
    try:
        data = request.get_json()
        result = ssh_service.create_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating SSH account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/ssh/trial', methods=['POST'])
@require_api_key
def trial_ssh():
    """Create trial SSH account"""
    try:
        data = request.get_json()
        result = ssh_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial SSH: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/ssh/list', methods=['GET'])
@require_api_key
def list_ssh():
    """List semua SSH accounts"""
    try:
        result = ssh_service.list_accounts()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing SSH accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/ssh/delete', methods=['POST'])
@require_api_key
def delete_ssh():
    """Delete SSH account"""
    try:
        data = request.get_json()
        result = ssh_service.delete_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting SSH account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/ssh/renew', methods=['POST'])
@require_api_key
def renew_ssh():
    """Renew SSH account"""
    try:
        data = request.get_json()
        result = ssh_service.renew_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error renewing SSH account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# VMess Endpoints
@app.route('/api/vmess/create', methods=['POST'])
@require_api_key
def create_vmess():
    """Create VMess account"""
    try:
        data = request.get_json()
        result = vmess_service.create_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating VMess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vmess/trial', methods=['POST'])
@require_api_key
def trial_vmess():
    """Create trial VMess account"""
    try:
        data = request.get_json()
        result = vmess_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial VMess: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vmess/list', methods=['GET'])
@require_api_key
def list_vmess():
    """List semua VMess accounts"""
    try:
        result = vmess_service.list_accounts()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing VMess accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vmess/delete', methods=['POST'])
@require_api_key
def delete_vmess():
    """Delete VMess account"""
    try:
        data = request.get_json()
        result = vmess_service.delete_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting VMess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vmess/renew', methods=['POST'])
@require_api_key
def renew_vmess():
    """Renew VMess account"""
    try:
        data = request.get_json()
        result = vmess_service.renew_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error renewing VMess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# VLess Endpoints
@app.route('/api/vless/create', methods=['POST'])
@require_api_key
def create_vless():
    """Create VLess account"""
    try:
        data = request.get_json()
        result = vless_service.create_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating VLess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vless/trial', methods=['POST'])
@require_api_key
def trial_vless():
    """Create trial VLess account"""
    try:
        data = request.get_json()
        result = vless_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial VLess: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vless/list', methods=['GET'])
@require_api_key
def list_vless():
    """List semua VLess accounts"""
    try:
        result = vless_service.list_accounts()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing VLess accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vless/delete', methods=['POST'])
@require_api_key
def delete_vless():
    """Delete VLess account"""
    try:
        data = request.get_json()
        result = vless_service.delete_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting VLess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/vless/renew', methods=['POST'])
@require_api_key
def renew_vless():
    """Renew VLess account"""
    try:
        data = request.get_json()
        result = vless_service.renew_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error renewing VLess account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# Shadowsocks Endpoints
@app.route('/api/shadowsocks/create', methods=['POST'])
@require_api_key
def create_shadowsocks():
    """Create Shadowsocks account"""
    try:
        data = request.get_json()
        result = shadowsocks_service.create_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating Shadowsocks account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/shadowsocks/trial', methods=['POST'])
@require_api_key
def trial_shadowsocks():
    """Create trial Shadowsocks account"""
    try:
        data = request.get_json()
        result = shadowsocks_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial Shadowsocks: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/shadowsocks/list', methods=['GET'])
@require_api_key
def list_shadowsocks():
    """List semua Shadowsocks accounts"""
    try:
        result = shadowsocks_service.list_accounts()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing Shadowsocks accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/shadowsocks/delete', methods=['POST'])
@require_api_key
def delete_shadowsocks():
    """Delete Shadowsocks account"""
    try:
        data = request.get_json()
        result = shadowsocks_service.delete_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting Shadowsocks account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/shadowsocks/renew', methods=['POST'])
@require_api_key
def renew_shadowsocks():
    """Renew Shadowsocks account"""
    try:
        data = request.get_json()
        result = shadowsocks_service.renew_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error renewing Shadowsocks account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# Trojan Endpoints
@app.route('/api/trojan/create', methods=['POST'])
@require_api_key
def create_trojan():
    """Create Trojan account"""
    try:
        data = request.get_json()
        result = trojan_service.create_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating Trojan account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trojan/trial', methods=['POST'])
@require_api_key
def trial_trojan():
    """Create trial Trojan account"""
    try:
        data = request.get_json()
        result = trojan_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial Trojan: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trojan/list', methods=['GET'])
@require_api_key
def list_trojan():
    """List semua Trojan accounts"""
    try:
        result = trojan_service.list_accounts()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing Trojan accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trojan/delete', methods=['POST'])
@require_api_key
def delete_trojan():
    """Delete Trojan account"""
    try:
        data = request.get_json()
        result = trojan_service.delete_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting Trojan account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trojan/renew', methods=['POST'])
@require_api_key
def renew_trojan():
    """Renew Trojan account"""
    try:
        data = request.get_json()
        result = trojan_service.renew_account(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error renewing Trojan account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# Trial Management Endpoints
@app.route('/api/trial/create', methods=['POST'])
@require_api_key
def create_trial():
    """Create trial account untuk semua service"""
    try:
        data = request.get_json()
        result = trial_service.create_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error creating trial account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trial/delete', methods=['POST'])
@require_api_key
def delete_trial():
    """Delete trial account"""
    try:
        data = request.get_json()
        result = trial_service.delete_trial(data)
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error deleting trial account: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/trial/list', methods=['GET'])
@require_api_key
def list_trials():
    """List semua trial accounts"""
    try:
        result = trial_service.list_trials()
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error listing trial accounts: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# System Management Endpoints
# @app.route('/api/system/restart', methods=['POST'])
# @require_api_key
# def restart_system():
#     """Restart system service"""
#     try:
#         data = request.get_json()
#         service = data.get('service', 'all')
#         result = {"status": "success", "message": f"Service {service} restarted"}
#         
#         if service == 'all':
#             subprocess.run(['systemctl', 'restart', 'xray'], check=True)
#             subprocess.run(['systemctl', 'restart', 'nginx'], check=True)
#             subprocess.run(['systemctl', 'restart', 'ssh'], check=True)
#         else:
#             subprocess.run(['systemctl', 'restart', service], check=True)
#             
#         return jsonify(result)
#     except Exception as e:
#         logger.error(f"Error restarting system: {e}")
#         return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/system/status', methods=['GET'])
def system_status():
    """Get system status"""
    try:
        services = ['xray', 'nginx', 'ssh']
        status = {}
        
        for service in services:
            try:
                result = subprocess.run(['systemctl', 'is-active', service], 
                                     capture_output=True, text=True, check=True)
                status[service] = result.stdout.strip()
            except:
                status[service] = "inactive"
                
        return jsonify({
            "status": "success",
            "services": status,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Error getting system status: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting AlrelShop API Panel Server...")
    app.run(host='0.0.0.0', port=5000, debug=False)
