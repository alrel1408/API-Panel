#!/usr/bin/env python3
"""
AlrelShop Auto Script - API Key Manager
Sistem untuk generate dan manage API key secara otomatis
"""

import json
import secrets
import string
import os
import shutil
from datetime import datetime
import logging

class APIKeyManager:
    def __init__(self):
        self.config_path = '/etc/API-Panel/config/api_config.json'
        self.local_config_path = 'config/api_config.json'
        self.postman_path = '/etc/API-Panel/docs/postman_collection.json'
        self.local_postman_path = 'postman_collection.json'
        self.test_script_path = '/etc/API-Panel/scripts/test_api.py'
        self.local_test_script_path = 'scripts/test_api.py'
        self.readme_path = '/etc/API-Panel/README.md'
        self.local_readme_path = 'README.md'
        self.auth_doc_path = '/etc/API-Panel/API_AUTHENTICATION.md'
        self.local_auth_doc_path = 'API_AUTHENTICATION.md'
        
        self.logger = logging.getLogger(__name__)
    
    def generate_api_key(self, length=32):
        """Generate secure API key"""
        alphabet = string.ascii_letters + string.digits + '-_'
        api_key = ''.join(secrets.choice(alphabet) for _ in range(length))
        return f"alrelshop-{api_key}-{datetime.now().strftime('%Y%m%d')}"
    
    def get_current_api_key(self):
        """Get current API key from config"""
        try:
            config_file = self.config_path if os.path.exists(self.config_path) else self.local_config_path
            with open(config_file, 'r') as f:
                config = json.load(f)
                return config.get('security', {}).get('authentication', {}).get('api_key', '')
        except Exception as e:
            self.logger.error(f"Error reading config: {e}")
            return None
    
    def update_config_file(self, new_api_key):
        """Update API key in config file"""
        try:
            # Try production path first, then local
            config_file = self.config_path if os.path.exists(self.config_path) else self.local_config_path
            
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            # Update API key
            if 'security' not in config:
                config['security'] = {}
            if 'authentication' not in config['security']:
                config['security']['authentication'] = {}
            
            config['security']['authentication']['api_key'] = new_api_key
            config['security']['authentication']['enabled'] = True
            config['security']['authentication']['type'] = 'bearer'
            config['security']['authentication']['last_updated'] = datetime.now().isoformat()
            
            # Write back to file
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            # If production file exists, also update local for development
            if config_file == self.config_path and os.path.exists(self.local_config_path):
                with open(self.local_config_path, 'w') as f:
                    json.dump(config, f, indent=2)
            
            return True
        except Exception as e:
            self.logger.error(f"Error updating config: {e}")
            return False
    
    def update_postman_collection(self, new_api_key):
        """Update API key in Postman collection"""
        try:
            # Try production path first, then local
            postman_file = self.postman_path if os.path.exists(self.postman_path) else self.local_postman_path
            
            with open(postman_file, 'r') as f:
                collection = json.load(f)
            
            # Update variable
            for variable in collection.get('variable', []):
                if variable.get('key') == 'api_key':
                    variable['value'] = new_api_key
                    break
            else:
                # Add variable if not exists
                if 'variable' not in collection:
                    collection['variable'] = []
                collection['variable'].append({
                    "key": "api_key",
                    "value": new_api_key,
                    "type": "string"
                })
            
            # Write back to file
            with open(postman_file, 'w') as f:
                json.dump(collection, f, indent=2)
            
            # Also update local if production exists
            if postman_file == self.postman_path and os.path.exists(self.local_postman_path):
                with open(self.local_postman_path, 'w') as f:
                    json.dump(collection, f, indent=2)
            
            return True
        except Exception as e:
            self.logger.error(f"Error updating Postman collection: {e}")
            return False
    
    def update_test_script(self, new_api_key):
        """Update API key in test script"""
        try:
            # Try production path first, then local
            test_file = self.test_script_path if os.path.exists(self.test_script_path) else self.local_test_script_path
            
            with open(test_file, 'r') as f:
                content = f.read()
            
            # Replace API key
            import re
            pattern = r'API_KEY = "[^"]*"'
            replacement = f'API_KEY = "{new_api_key}"'
            content = re.sub(pattern, replacement, content)
            
            # Write back to file
            with open(test_file, 'w') as f:
                f.write(content)
            
            # Also update local if production exists
            if test_file == self.test_script_path and os.path.exists(self.local_test_script_path):
                with open(self.local_test_script_path, 'w') as f:
                    f.write(content)
            
            return True
        except Exception as e:
            self.logger.error(f"Error updating test script: {e}")
            return False
    
    def update_documentation(self, new_api_key):
        """Update API key in documentation files"""
        try:
            files_to_update = [
                (self.readme_path, self.local_readme_path),
                (self.auth_doc_path, self.local_auth_doc_path)
            ]
            
            for prod_file, local_file in files_to_update:
                # Choose file to update
                target_file = prod_file if os.path.exists(prod_file) else local_file
                
                if not os.path.exists(target_file):
                    continue
                
                with open(target_file, 'r') as f:
                    content = f.read()
                
                # Replace old API key with new one
                import re
                # Pattern untuk menangkap berbagai format API key di dokumentasi
                patterns = [
                    r'alrelshop-secret-api-key-\d{4}',
                    r'alrelshop-[a-zA-Z0-9_-]+-\d{8}',
                    r'"api_key": "[^"]*"',
                    r'X-API-Key: [^\s\n]*',
                    r'Bearer [^\s\n]*'
                ]
                
                for pattern in patterns:
                    if 'api_key' in pattern:
                        replacement = f'"api_key": "{new_api_key}"'
                    elif 'X-API-Key' in pattern:
                        replacement = f'X-API-Key: {new_api_key}'
                    elif 'Bearer' in pattern:
                        replacement = f'Bearer {new_api_key}'
                    else:
                        replacement = new_api_key
                    
                    content = re.sub(pattern, replacement, content)
                
                # Write back to file
                with open(target_file, 'w') as f:
                    f.write(content)
                
                # Also update local if production exists
                if target_file == prod_file and os.path.exists(local_file):
                    with open(local_file, 'w') as f:
                        f.write(content)
            
            return True
        except Exception as e:
            self.logger.error(f"Error updating documentation: {e}")
            return False
    
    def backup_current_config(self):
        """Backup current configuration"""
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_dir = f'/tmp/api-panel-backup-{timestamp}'
            os.makedirs(backup_dir, exist_ok=True)
            
            files_to_backup = [
                self.config_path,
                self.local_config_path,
                self.postman_path,
                self.local_postman_path
            ]
            
            for file_path in files_to_backup:
                if os.path.exists(file_path):
                    filename = os.path.basename(file_path)
                    shutil.copy2(file_path, os.path.join(backup_dir, filename))
            
            return backup_dir
        except Exception as e:
            self.logger.error(f"Error creating backup: {e}")
            return None
    
    def generate_and_sync_api_key(self):
        """Generate new API key and sync to all files"""
        try:
            # Backup current config
            backup_dir = self.backup_current_config()
            if backup_dir:
                print(f"✅ Backup created at: {backup_dir}")
            
            # Generate new API key
            new_api_key = self.generate_api_key()
            print(f"🔑 Generated new API key: {new_api_key}")
            
            # Get current API key for comparison
            old_api_key = self.get_current_api_key()
            
            # Update all files
            results = {}
            results['config'] = self.update_config_file(new_api_key)
            results['postman'] = self.update_postman_collection(new_api_key)
            results['test_script'] = self.update_test_script(new_api_key)
            results['documentation'] = self.update_documentation(new_api_key)
            
            # Report results
            success_count = sum(results.values())
            total_count = len(results)
            
            print(f"\n📊 Sync Results: {success_count}/{total_count} files updated")
            for file_type, success in results.items():
                status = "✅" if success else "❌"
                print(f"  {status} {file_type.title()}")
            
            if success_count == total_count:
                print(f"\n🎉 API key successfully generated and synced!")
                print(f"📝 Old API Key: {old_api_key}")
                print(f"🆕 New API Key: {new_api_key}")
                print(f"\n⚠️  Restart API service: sudo systemctl restart api-panel")
                return new_api_key
            else:
                print(f"\n⚠️  Some files failed to update. Check logs for details.")
                return None
            
        except Exception as e:
            self.logger.error(f"Error in generate_and_sync_api_key: {e}")
            print(f"❌ Error: {e}")
            return None
    
    def validate_api_key_sync(self):
        """Validate that all files have the same API key"""
        try:
            # Get API key from different sources
            config_key = self.get_current_api_key()
            
            # Check Postman collection
            postman_key = None
            try:
                postman_file = self.postman_path if os.path.exists(self.postman_path) else self.local_postman_path
                with open(postman_file, 'r') as f:
                    collection = json.load(f)
                for variable in collection.get('variable', []):
                    if variable.get('key') == 'api_key':
                        postman_key = variable.get('value')
                        break
            except:
                pass
            
            # Check test script
            test_key = None
            try:
                test_file = self.test_script_path if os.path.exists(self.test_script_path) else self.local_test_script_path
                with open(test_file, 'r') as f:
                    content = f.read()
                import re
                match = re.search(r'API_KEY = "([^"]*)"', content)
                if match:
                    test_key = match.group(1)
            except:
                pass
            
            # Compare keys
            keys = {
                'config': config_key,
                'postman': postman_key,
                'test_script': test_key
            }
            
            print("🔍 API Key Validation:")
            all_match = True
            reference_key = config_key
            
            for source, key in keys.items():
                if key == reference_key:
                    print(f"  ✅ {source.title()}: {key}")
                else:
                    print(f"  ❌ {source.title()}: {key} (MISMATCH)")
                    all_match = False
            
            if all_match:
                print(f"\n✅ All files are synchronized with API key: {reference_key}")
            else:
                print(f"\n⚠️  Files are NOT synchronized. Run sync command to fix.")
            
            return all_match
            
        except Exception as e:
            print(f"❌ Error validating API keys: {e}")
            return False

if __name__ == "__main__":
    import sys
    
    manager = APIKeyManager()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python3 api_key_manager.py generate    # Generate and sync new API key")
        print("  python3 api_key_manager.py validate    # Validate API key sync")
        print("  python3 api_key_manager.py current     # Show current API key")
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    if command == "generate":
        manager.generate_and_sync_api_key()
    elif command == "validate":
        manager.validate_api_key_sync()
    elif command == "current":
        current_key = manager.get_current_api_key()
        print(f"Current API Key: {current_key}")
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
