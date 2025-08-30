#!/usr/bin/env python3
"""
Test Script untuk API Panel setelah perbaikan error delimiter JSON
"""

import requests
import json
import sys

def test_api_endpoint(url, headers, data=None, method='GET'):
    """Test API endpoint dan return response"""
    try:
        if method == 'POST':
            response = requests.post(url, headers=headers, json=data, timeout=10)
        else:
            response = requests.get(url, headers=headers, timeout=10)
        
        print(f"Status Code: {response.status_code}")
        
        try:
            json_response = response.json()
            print(f"Response: {json.dumps(json_response, indent=2)}")
            return json_response
        except json.JSONDecodeError as e:
            print(f"JSON Decode Error: {e}")
            print(f"Raw Response: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"Request Error: {e}")
        return None

def main():
    # Configuration
    base_url = "http://localhost:5000"
    api_key = "your-secret-api-key-here"  # Ganti dengan API key yang benar
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": api_key
    }
    
    print("=== Testing API Panel setelah perbaikan ===\n")
    
    # Test 1: API Status
    print("1. Testing API Status...")
    test_api_endpoint(f"{base_url}/api/status", headers)
    print("\n" + "="*50 + "\n")
    
    # Test 2: Create Trojan Account
    print("2. Testing Create Trojan Account...")
    trojan_data = {
        "username": "test-trojan-user",
        "days": 30,
        "quota_gb": 10,
        "ip_limit": 2
    }
    test_api_endpoint(f"{base_url}/api/trojan/create", headers, trojan_data, 'POST')
    print("\n" + "="*50 + "\n")
    
    # Test 3: Create VMess Account
    print("3. Testing Create VMess Account...")
    vmess_data = {
        "username": "test-vmess-user",
        "days": 30,
        "quota_gb": 10,
        "ip_limit": 2,
        "bug": "bug.com"
    }
    test_api_endpoint(f"{base_url}/api/vmess/create", headers, vmess_data, 'POST')
    print("\n" + "="*50 + "\n")
    
    # Test 4: Create VLess Account
    print("4. Testing Create VLess Account...")
    vless_data = {
        "username": "test-vless-user",
        "days": 30,
        "quota_gb": 10,
        "ip_limit": 2
    }
    test_api_endpoint(f"{base_url}/api/vless/create", headers, vless_data, 'POST')
    print("\n" + "="*50 + "\n")
    
    # Test 5: Create Shadowsocks Account
    print("5. Testing Create Shadowsocks Account...")
    ss_data = {
        "username": "test-ss-user",
        "days": 30,
        "quota_gb": 10,
        "cipher": "aes-128-gcm"
    }
    test_api_endpoint(f"{base_url}/api/shadowsocks/create", headers, ss_data, 'POST')
    print("\n" + "="*50 + "\n")
    
    # Test 6: List Accounts
    print("6. Testing List Trojan Accounts...")
    test_api_endpoint(f"{base_url}/api/trojan/list", headers)
    print("\n" + "="*50 + "\n")
    
    print("7. Testing List VMess Accounts...")
    test_api_endpoint(f"{base_url}/api/vmess/list", headers)
    print("\n" + "="*50 + "\n")
    
    print("8. Testing List VLess Accounts...")
    test_api_endpoint(f"{base_url}/api/vless/list", headers)
    print("\n" + "="*50 + "\n")
    
    print("9. Testing List Shadowsocks Accounts...")
    test_api_endpoint(f"{base_url}/api/shadowsocks/list", headers)
    print("\n" + "="*50 + "\n")
    
    # Test 7: System Status
    print("10. Testing System Status...")
    test_api_endpoint(f"{base_url}/api/system/status", headers)
    print("\n" + "="*50 + "\n")
    
    print("=== Test selesai ===")

if __name__ == "__main__":
    main()

