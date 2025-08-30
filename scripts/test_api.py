#!/usr/bin/env python3
"""
AlrelShop API Panel - Test Script
Author: AlrelShop Auto Script
Version: 1.0.0

Script untuk testing semua endpoint API Panel
"""

import requests
import json
import time
import sys
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:5000"
API_KEY = "alrelshop-secret-api-key-2024"  # API key yang valid sesuai config

# Test data
TEST_ACCOUNTS = {
    "ssh": {
        "username": "testuser",
        "password": "testpass123",
        "days": 7,
        "ip_limit": 2,
        "quota_gb": 10
    },
    "vmess": {
        "username": "testvmess",
        "days": 7,
        "ip_limit": 2,
        "quota_gb": 5,
        "bug": "bug.com"
    },
    "vless": {
        "username": "testvless",
        "days": 7,
        "ip_limit": 2,
        "quota_gb": 5
    },
    "shadowsocks": {
        "username": "testss",
        "days": 7,
        "quota_gb": 5
    },
    "trojan": {
        "username": "testtrojan",
        "days": 7,
        "ip_limit": 2,
        "quota_gb": 5
    }
}

# Colors for output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_header(title):
    """Print formatted header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{title:^60}{Colors.END}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'='*60}{Colors.END}")

def print_success(message):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {message}{Colors.END}")

def print_error(message):
    """Print error message"""
    print(f"{Colors.RED}❌ {message}{Colors.END}")

def print_warning(message):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")

def print_info(message):
    """Print info message"""
    print(f"{Colors.CYAN}ℹ️  {message}{Colors.END}")

def test_health_endpoint():
    """Test health endpoint"""
    print_header("Testing Health Endpoint")
    
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print_success(f"Health endpoint: {data.get('message', 'API Panel')}")
            print_info(f"Version: {data.get('version', 'N/A')}")
            print_info(f"Status: {data.get('status', 'N/A')}")
            return True
        else:
            print_error(f"Health endpoint failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print_error(f"Health endpoint error: {e}")
        return False

def test_api_status():
    """Test API status endpoint"""
    print_header("Testing API Status")
    
    try:
        response = requests.get(f"{BASE_URL}/api/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print_success("API status endpoint working")
            print_info(f"Status: {data.get('status', 'N/A')}")
            print_info(f"Timestamp: {data.get('timestamp', 'N/A')}")
            return True
        else:
            print_error(f"API status failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print_error(f"API status error: {e}")
        return False

def test_authentication():
    """Test API authentication"""
    print_header("Testing API Authentication")
    
    # Test without API key
    try:
        response = requests.get(f"{BASE_URL}/api/ssh/list", timeout=10)
        if response.status_code == 401:
            print_success("Authentication properly blocks unauthorized requests")
        else:
            print_error(f"Authentication bypass detected! Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Authentication test error: {e}")
    
    # Test with invalid API key
    try:
        headers = {"X-API-Key": "invalid-key"}
        response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers, timeout=10)
        if response.status_code == 401:
            print_success("Authentication properly rejects invalid API key")
        else:
            print_error(f"Invalid API key accepted! Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Invalid API key test error: {e}")
    
    # Test with valid API key using X-API-Key header
    try:
        headers = {"X-API-Key": API_KEY}
        response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("X-API-Key header authentication working")
        else:
            print_error(f"Valid X-API-Key rejected! Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"X-API-Key test error: {e}")
    
    # Test with valid API key using Authorization Bearer header
    try:
        headers = {"Authorization": f"Bearer {API_KEY}"}
        response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Authorization Bearer authentication working")
        else:
            print_error(f"Valid Bearer token rejected! Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Bearer token test error: {e}")
    
    return True

def test_system_status():
    """Test system status endpoint"""
    print_header("Testing System Status")
    
    try:
        response = requests.get(f"{BASE_URL}/api/system/status", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print_success("System status endpoint working")
            print_info(f"Xray: {data.get('xray', 'N/A')}")
            print_info(f"Nginx: {data.get('nginx', 'N/A')}")
            print_info(f"SSH: {data.get('ssh', 'N/A')}")
            return True
        else:
            print_error(f"System status failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print_error(f"System status error: {e}")
        return False

def test_ssh_endpoints():
    """Test SSH service endpoints"""
    print_header("Testing SSH Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test SSH list
    try:
        response = requests.get(f"{BASE_URL}/api/ssh/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("SSH list endpoint working")
        else:
            print_error(f"SSH list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"SSH list error: {e}")
    
    # Test SSH create
    try:
        data = TEST_ACCOUNTS["ssh"]
        response = requests.post(f"{BASE_URL}/api/ssh/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("SSH create endpoint working")
            result = response.json()
            print_info(f"Created user: {result.get('username', 'N/A')}")
        else:
            print_error(f"SSH create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"SSH create error: {e}")

def test_vmess_endpoints():
    """Test VMess service endpoints"""
    print_header("Testing VMess Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test VMess list
    try:
        response = requests.get(f"{BASE_URL}/api/vmess/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("VMess list endpoint working")
        else:
            print_error(f"VMess list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"VMess list error: {e}")
    
    # Test VMess create
    try:
        data = TEST_ACCOUNTS["vmess"]
        response = requests.post(f"{BASE_URL}/api/vmess/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("VMess create endpoint working")
            result = response.json()
            print_info(f"Created user: {result.get('username', 'N/A')}")
        else:
            print_error(f"VMess create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"VMess create error: {e}")

def test_vless_endpoints():
    """Test VLess service endpoints"""
    print_header("Testing VLess Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test VLess list
    try:
        response = requests.get(f"{BASE_URL}/api/vless/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("VLess list endpoint working")
        else:
            print_error(f"VLess list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"VLess list error: {e}")
    
    # Test VLess create
    try:
        data = TEST_ACCOUNTS["vless"]
        response = requests.post(f"{BASE_URL}/api/vless/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("VLess create endpoint working")
            result = response.json()
            print_info(f"Created user: {result.get('username', 'N/A')}")
        else:
            print_error(f"VLess create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"VLess create error: {e}")

def test_shadowsocks_endpoints():
    """Test Shadowsocks service endpoints"""
    print_header("Testing Shadowsocks Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test Shadowsocks list
    try:
        response = requests.get(f"{BASE_URL}/api/shadowsocks/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Shadowsocks list endpoint working")
        else:
            print_error(f"Shadowsocks list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Shadowsocks list error: {e}")
    
    # Test Shadowsocks create
    try:
        data = TEST_ACCOUNTS["shadowsocks"]
        response = requests.post(f"{BASE_URL}/api/shadowsocks/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Shadowsocks create endpoint working")
            result = response.json()
            print_info(f"Created user: {result.get('username', 'N/A')}")
        else:
            print_error(f"Shadowsocks create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"Shadowsocks create error: {e}")

def test_trojan_endpoints():
    """Test Trojan service endpoints"""
    print_header("Testing Trojan Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test Trojan list
    try:
        response = requests.get(f"{BASE_URL}/api/trojan/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Trojan list endpoint working")
        else:
            print_error(f"Trojan list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Trojan list error: {e}")
    
    # Test Trojan create
    try:
        data = TEST_ACCOUNTS["trojan"]
        response = requests.post(f"{BASE_URL}/api/trojan/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Trojan create endpoint working")
            result = response.json()
            print_info(f"Created user: {result.get('username', 'N/A')}")
        else:
            print_error(f"Trojan create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"Trojan create error: {e}")

def test_trial_endpoints():
    """Test Trial service endpoints"""
    print_header("Testing Trial Service Endpoints")
    
    headers = {"X-API-Key": API_KEY}
    
    # Test Trial list
    try:
        response = requests.get(f"{BASE_URL}/api/trial/list", headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Trial list endpoint working")
        else:
            print_error(f"Trial list failed: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print_error(f"Trial list error: {e}")
    
    # Test Trial create
    try:
        data = {
            "service": "ssh",
            "minutes": 60,
            "ip_limit": 4,
            "quota_gb": 5
        }
        response = requests.post(f"{BASE_URL}/api/trial/create", json=data, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success("Trial create endpoint working")
            result = response.json()
            print_info(f"Created trial: {result.get('username', 'N/A')}")
        else:
            print_error(f"Trial create failed: {response.status_code}")
            if response.text:
                print_error(f"Error: {response.text}")
    except requests.exceptions.RequestException as e:
        print_error(f"Trial create error: {e}")

def cleanup_test_accounts():
    """Clean up test accounts"""
    print_header("Cleaning Up Test Accounts")
    
    services = ["ssh", "vmess", "vless", "shadowsocks", "trojan"]
    
    for service in services:
        try:
            username = TEST_ACCOUNTS[service]["username"]
            headers = {"X-API-Key": API_KEY}
            response = requests.delete(f"{BASE_URL}/api/{service}/delete", 
                                    json={"username": username}, headers=headers, timeout=10)
            if response.status_code == 200:
                print_success(f"Cleaned up {service} test account: {username}")
            else:
                print_warning(f"Could not clean up {service} test account: {username}")
        except requests.exceptions.RequestException as e:
            print_warning(f"Error cleaning up {service} test account: {e}")

def main():
    """Main test function"""
    print_header("AlrelShop API Panel - API Testing")
    print_info(f"Testing API at: {BASE_URL}")
    print_info(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test basic endpoints
    health_ok = test_health_endpoint()
    if not health_ok:
        print_error("API Panel tidak dapat diakses. Pastikan service berjalan.")
        print_info("Jalankan: systemctl status api-panel")
        return
    
    # Test all endpoints
    test_api_status()
    test_authentication()
    test_system_status()
    test_ssh_endpoints()
    test_vmess_endpoints()
    test_vless_endpoints()
    test_shadowsocks_endpoints()
    test_trojan_endpoints()
    test_trial_endpoints()
    
    # Clean up test accounts
    cleanup_test_accounts()
    
    print_header("Testing Complete")
    print_success("Semua endpoint telah di-test!")
    print_info(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    print_info("\nUntuk testing lebih lanjut, gunakan Postman collection:")
    print_info("File: postman_collection.json")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTesting dihentikan oleh user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        sys.exit(1)
