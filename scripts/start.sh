#!/bin/bash

# AlrelShop Auto Script - API Panel Start Service
# Script untuk memulai API Panel service

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name
SERVICE_NAME="api-panel"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo -e "${BLUE}=== AlrelShop API Panel - Start Service ===${NC}"

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to check if service file exists
check_service_file() {
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}Error: Service file not found at $SERVICE_FILE${NC}"
        echo -e "${YELLOW}Please install API Panel first using install.sh${NC}"
        exit 1
    fi
}

# Function to start API Panel service
start_api_service() {
    echo -e "${YELLOW}Starting API Panel service...${NC}"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}API Panel service is already running${NC}"
        return 0
    fi
    
    systemctl start $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ API Panel service started successfully${NC}"
        
        # Wait a moment and check if it's really running
        sleep 2
        if systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✓ Service is running properly${NC}"
        else
            echo -e "${RED}✗ Service failed to start properly${NC}"
            echo -e "${YELLOW}Check logs: journalctl -u $SERVICE_NAME -f${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to start API Panel service${NC}"
        return 1
    fi
}

# Function to enable API Panel service
enable_api_service() {
    if ! systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}Enabling $SERVICE_NAME service for auto-start...${NC}"
        systemctl enable $SERVICE_NAME
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ API Panel service enabled for auto-start${NC}"
        else
            echo -e "${RED}✗ Failed to enable API Panel service${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}API Panel service is already enabled for auto-start${NC}"
    fi
}

# Function to show service status
show_status() {
    echo -e "\n${BLUE}=== Service Status ===${NC}"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "Service Status: ${GREEN}RUNNING${NC}"
        
        # Get the port from config
        PORT=$(grep -o '"port": [0-9]*' /etc/API-Panel/config/api_config.json 2>/dev/null | grep -o '[0-9]*' || echo "5000")
        echo -e "API URL: ${GREEN}http://localhost:$PORT${NC}"
        echo -e "API Status: ${GREEN}http://localhost:$PORT/api/status${NC}"
    else
        echo -e "Service Status: ${RED}STOPPED${NC}"
    fi
    
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "Auto-start: ${GREEN}ENABLED${NC}"
    else
        echo -e "Auto-start: ${RED}DISABLED${NC}"
    fi
    
    # Show recent logs
    echo -e "\n${BLUE}Recent Logs:${NC}"
    journalctl -u $SERVICE_NAME --no-pager -n 5 2>/dev/null || echo "No logs available"
}

# Main execution
main() {
    check_root
    check_service_file
    
    echo -e "${BLUE}Starting startup procedure...${NC}\n"
    
    # Start the service
    start_api_service
    
    # Enable auto-start
    enable_api_service
    
    # Show final status
    show_status
    
    echo -e "\n${GREEN}=== API Panel Start Complete ===${NC}"
    
    # Show useful commands
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "  ${YELLOW}sudo systemctl status $SERVICE_NAME${NC} - Check service status"
    echo -e "  ${YELLOW}sudo journalctl -u $SERVICE_NAME -f${NC} - Follow logs"
    echo -e "  ${YELLOW}sudo systemctl restart $SERVICE_NAME${NC} - Restart service"
    echo -e "  ${YELLOW}./scripts/stop.sh${NC} - Stop service"
}

# Handle script arguments
case "${1:-}" in
    --status)
        show_status
        ;;
    --help|-h)
        echo -e "${BLUE}AlrelShop API Panel - Start Service${NC}"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --status   Show current service status"
        echo "  --help     Show this help message"
        echo ""
        echo "Without options: Start API Panel service"
        ;;
    *)
        main
        ;;
esac
