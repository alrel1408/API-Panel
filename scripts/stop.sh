#!/bin/bash

# AlrelShop Auto Script - API Panel Stop Service
# Script untuk menghentikan API Panel service

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name
SERVICE_NAME="api-panel"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo -e "${BLUE}=== AlrelShop API Panel - Stop Service ===${NC}"
echo -e "${YELLOW}Stopping API Panel service...${NC}"

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to stop API Panel service
stop_api_service() {
    echo -e "${YELLOW}Checking API Panel service status...${NC}"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}Stopping $SERVICE_NAME service...${NC}"
        systemctl stop $SERVICE_NAME
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ API Panel service stopped successfully${NC}"
        else
            echo -e "${RED}✗ Failed to stop API Panel service${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}API Panel service is not running${NC}"
    fi
}

# Function to disable API Panel service
disable_api_service() {
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}Disabling $SERVICE_NAME service from auto-start...${NC}"
        systemctl disable $SERVICE_NAME
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ API Panel service disabled from auto-start${NC}"
        else
            echo -e "${RED}✗ Failed to disable API Panel service${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}API Panel service is not enabled for auto-start${NC}"
    fi
}

# Function to kill Python processes related to API Panel
kill_api_processes() {
    echo -e "${YELLOW}Checking for running API Panel processes...${NC}"
    
    # Find Python processes running main_api.py
    API_PIDS=$(pgrep -f "main_api.py")
    
    if [ -n "$API_PIDS" ]; then
        echo -e "${YELLOW}Found API Panel processes: $API_PIDS${NC}"
        echo -e "${YELLOW}Terminating API Panel processes...${NC}"
        
        # First try graceful termination
        kill $API_PIDS 2>/dev/null
        sleep 3
        
        # Check if processes still running
        REMAINING_PIDS=$(pgrep -f "main_api.py")
        if [ -n "$REMAINING_PIDS" ]; then
            echo -e "${YELLOW}Force killing remaining processes...${NC}"
            kill -9 $REMAINING_PIDS 2>/dev/null
        fi
        
        echo -e "${GREEN}✓ API Panel processes terminated${NC}"
    else
        echo -e "${YELLOW}No API Panel processes found${NC}"
    fi
}

# Function to show service status
show_status() {
    echo -e "\n${BLUE}=== Service Status ===${NC}"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "Service Status: ${GREEN}RUNNING${NC}"
    else
        echo -e "Service Status: ${RED}STOPPED${NC}"
    fi
    
    if systemctl is-enabled --quiet $SERVICE_NAME; then
        echo -e "Auto-start: ${GREEN}ENABLED${NC}"
    else
        echo -e "Auto-start: ${RED}DISABLED${NC}"
    fi
    
    # Check for any remaining processes
    API_PIDS=$(pgrep -f "main_api.py")
    if [ -n "$API_PIDS" ]; then
        echo -e "Running Processes: ${YELLOW}$API_PIDS${NC}"
    else
        echo -e "Running Processes: ${GREEN}NONE${NC}"
    fi
}

# Main execution
main() {
    check_root
    
    echo -e "${BLUE}Starting stop procedure...${NC}\n"
    
    # Stop the service
    stop_api_service
    
    # Ask if user wants to disable auto-start
    echo ""
    read -p "Do you want to disable auto-start? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        disable_api_service
    fi
    
    # Kill any remaining processes
    kill_api_processes
    
    # Show final status
    show_status
    
    echo -e "\n${GREEN}=== API Panel Stop Complete ===${NC}"
    
    # Show how to start again
    echo -e "\n${BLUE}To start API Panel again:${NC}"
    echo -e "  ${YELLOW}sudo systemctl start $SERVICE_NAME${NC}"
    echo -e "  ${YELLOW}sudo systemctl enable $SERVICE_NAME${NC} (to enable auto-start)"
}

# Handle script arguments
case "${1:-}" in
    --force)
        check_root
        echo -e "${YELLOW}Force stopping API Panel...${NC}"
        systemctl stop $SERVICE_NAME 2>/dev/null
        systemctl disable $SERVICE_NAME 2>/dev/null
        kill_api_processes
        show_status
        ;;
    --status)
        show_status
        ;;
    --help|-h)
        echo -e "${BLUE}AlrelShop API Panel - Stop Service${NC}"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --force    Force stop and disable service"
        echo "  --status   Show current service status"
        echo "  --help     Show this help message"
        echo ""
        echo "Without options: Interactive stop procedure"
        ;;
    *)
        main
        ;;
esac
