#!/bin/bash

# AlrelShop Auto Script - API Key Manager CLI
# Tool untuk manage API key secara otomatis

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
API_PANEL_DIR="/etc/API-Panel"
LOCAL_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
PYTHON_SCRIPT="$API_PANEL_DIR/api/api_key_manager.py"
LOCAL_PYTHON_SCRIPT="$LOCAL_DIR/api/api_key_manager.py"

echo -e "${BLUE}=== AlrelShop API Panel - API Key Manager ===${NC}"

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Warning: Running without root privileges${NC}"
        echo -e "${YELLOW}Some operations may require sudo access${NC}"
    fi
}

# Function to find Python script
find_python_script() {
    if [ -f "$PYTHON_SCRIPT" ]; then
        echo "$PYTHON_SCRIPT"
    elif [ -f "$LOCAL_PYTHON_SCRIPT" ]; then
        echo "$LOCAL_PYTHON_SCRIPT"
    else
        echo ""
    fi
}

# Function to generate new API key
generate_api_key() {
    echo -e "${CYAN}🔑 Generating new API key...${NC}"
    
    SCRIPT_PATH=$(find_python_script)
    if [ -z "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Error: api_key_manager.py not found${NC}"
        echo -e "${YELLOW}Expected locations:${NC}"
        echo -e "  - $PYTHON_SCRIPT"
        echo -e "  - $LOCAL_PYTHON_SCRIPT"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  This will generate a new API key and invalidate the current one!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Running API key generation...${NC}"
    cd "$(dirname "$SCRIPT_PATH")"
    python3 "$(basename "$SCRIPT_PATH")" generate
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✅ API key generation completed!${NC}"
        echo -e "${YELLOW}⚠️  Don't forget to restart the API service:${NC}"
        echo -e "${CYAN}    sudo systemctl restart api-panel${NC}"
        
        # Ask if user wants to restart service
        read -p "Restart API service now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restart_api_service
        fi
    else
        echo -e "\n${RED}❌ Failed to generate API key${NC}"
        return 1
    fi
}

# Function to validate API key sync
validate_api_key() {
    echo -e "${CYAN}🔍 Validating API key synchronization...${NC}"
    
    SCRIPT_PATH=$(find_python_script)
    if [ -z "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Error: api_key_manager.py not found${NC}"
        return 1
    fi
    
    cd "$(dirname "$SCRIPT_PATH")"
    python3 "$(basename "$SCRIPT_PATH")" validate
}

# Function to show current API key
show_current_api_key() {
    echo -e "${CYAN}🔑 Current API key:${NC}"
    
    SCRIPT_PATH=$(find_python_script)
    if [ -z "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Error: api_key_manager.py not found${NC}"
        return 1
    fi
    
    cd "$(dirname "$SCRIPT_PATH")"
    python3 "$(basename "$SCRIPT_PATH")" current
}

# Function to restart API service
restart_api_service() {
    echo -e "${YELLOW}🔄 Restarting API Panel service...${NC}"
    
    if systemctl is-active --quiet api-panel; then
        systemctl restart api-panel
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ API Panel service restarted successfully${NC}"
            sleep 2
            systemctl status api-panel --no-pager -l
        else
            echo -e "${RED}❌ Failed to restart API Panel service${NC}"
        fi
    else
        echo -e "${YELLOW}API Panel service is not running. Starting...${NC}"
        systemctl start api-panel
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ API Panel service started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start API Panel service${NC}"
        fi
    fi
}

# Function to test API with new key
test_api_with_new_key() {
    echo -e "${CYAN}🧪 Testing API with current key...${NC}"
    
    # Get current API key
    SCRIPT_PATH=$(find_python_script)
    if [ -z "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Error: api_key_manager.py not found${NC}"
        return 1
    fi
    
    cd "$(dirname "$SCRIPT_PATH")"
    CURRENT_KEY=$(python3 "$(basename "$SCRIPT_PATH")" current | grep "Current API Key:" | cut -d' ' -f4)
    
    if [ -z "$CURRENT_KEY" ]; then
        echo -e "${RED}❌ Could not retrieve current API key${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Testing with API key: $CURRENT_KEY${NC}"
    
    # Test API endpoint
    BASE_URL="http://localhost:5000"
    
    echo -e "${YELLOW}Testing API status endpoint...${NC}"
    RESPONSE=$(curl -s -w "%{http_code}" -H "X-API-Key: $CURRENT_KEY" "$BASE_URL/api/status")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✅ API test successful!${NC}"
        echo -e "${CYAN}Response: $BODY${NC}"
    else
        echo -e "${RED}❌ API test failed with HTTP code: $HTTP_CODE${NC}"
        echo -e "${YELLOW}Response: $BODY${NC}"
    fi
}

# Function to show API key info
show_api_key_info() {
    echo -e "${BLUE}📋 API Key Information${NC}"
    echo -e "${CYAN}===================${NC}"
    
    show_current_api_key
    echo ""
    validate_api_key
    echo ""
    
    # Show API Panel service status
    echo -e "${BLUE}🔧 Service Status:${NC}"
    if systemctl is-active --quiet api-panel; then
        echo -e "${GREEN}✅ API Panel service is running${NC}"
    else
        echo -e "${RED}❌ API Panel service is not running${NC}"
    fi
    
    # Show API endpoint
    echo -e "${BLUE}🌐 API Endpoint:${NC}"
    echo -e "${CYAN}http://localhost:5000${NC}"
}

# Function to generate via API endpoint
generate_via_api() {
    echo -e "${CYAN}🔗 Generating API key via API endpoint...${NC}"
    
    # Get current API key first
    SCRIPT_PATH=$(find_python_script)
    if [ -z "$SCRIPT_PATH" ]; then
        echo -e "${RED}❌ Error: api_key_manager.py not found${NC}"
        return 1
    fi
    
    cd "$(dirname "$SCRIPT_PATH")"
    CURRENT_KEY=$(python3 "$(basename "$SCRIPT_PATH")" current | grep "Current API Key:" | cut -d' ' -f4)
    
    if [ -z "$CURRENT_KEY" ]; then
        echo -e "${RED}❌ Could not retrieve current API key${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  This will generate a new API key via API endpoint!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 1
    fi
    
    # Call API endpoint
    BASE_URL="http://localhost:5000"
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $CURRENT_KEY" \
        -d '{"confirm": true}' \
        "$BASE_URL/api/admin/generate-api-key")
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ API call successful!${NC}"
        echo -e "${CYAN}Response: $RESPONSE${NC}"
        echo -e "\n${YELLOW}⚠️  Restart API service to use new key:${NC}"
        echo -e "${CYAN}    sudo systemctl restart api-panel${NC}"
    else
        echo -e "${RED}❌ API call failed${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "\n${PURPLE}🎛️  API Key Manager Menu${NC}"
    echo -e "${CYAN}========================${NC}"
    echo -e "1. ${GREEN}Generate new API key (CLI)${NC}"
    echo -e "2. ${GREEN}Generate new API key (API)${NC}"
    echo -e "3. ${BLUE}Show current API key${NC}"
    echo -e "4. ${BLUE}Validate API key sync${NC}"
    echo -e "5. ${BLUE}Show API key info${NC}"
    echo -e "6. ${YELLOW}Test API with current key${NC}"
    echo -e "7. ${YELLOW}Restart API service${NC}"
    echo -e "8. ${RED}Exit${NC}"
    echo ""
}

# Main execution
main() {
    check_root
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option (1-8): " choice
            echo ""
            
            case $choice in
                1)
                    generate_api_key
                    ;;
                2)
                    generate_via_api
                    ;;
                3)
                    show_current_api_key
                    ;;
                4)
                    validate_api_key
                    ;;
                5)
                    show_api_key_info
                    ;;
                6)
                    test_api_with_new_key
                    ;;
                7)
                    restart_api_service
                    ;;
                8)
                    echo -e "${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please select 1-8.${NC}"
                    ;;
            esac
            
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        # Command line mode
        case $1 in
            generate|gen)
                generate_api_key
                ;;
            validate|val)
                validate_api_key
                ;;
            current|cur)
                show_current_api_key
                ;;
            info)
                show_api_key_info
                ;;
            test)
                test_api_with_new_key
                ;;
            restart)
                restart_api_service
                ;;
            api-gen)
                generate_via_api
                ;;
            --help|-h)
                echo -e "${BLUE}AlrelShop API Key Manager${NC}"
                echo ""
                echo "Usage: $0 [COMMAND]"
                echo ""
                echo "Commands:"
                echo "  generate, gen    Generate new API key (CLI method)"
                echo "  api-gen         Generate new API key (API method)"
                echo "  validate, val   Validate API key synchronization"
                echo "  current, cur    Show current API key"
                echo "  info            Show complete API key information"
                echo "  test            Test API with current key"
                echo "  restart         Restart API Panel service"
                echo "  --help, -h      Show this help message"
                echo ""
                echo "Without arguments: Interactive menu mode"
                ;;
            *)
                echo -e "${RED}Unknown command: $1${NC}"
                echo "Use --help for available commands"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
