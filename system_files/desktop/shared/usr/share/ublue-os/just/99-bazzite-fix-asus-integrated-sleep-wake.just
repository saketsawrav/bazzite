# Fix ASUS integrated mode bug where NVIDIA module re-enables after suspend
# Currently there is a bug in asus-linux (asusctl and supergfxd) where when a user
# is in Integrated mode and wakes the laptop from sleep, it sometimes re-enables

# the NVIDIA module. This recipe implements a workaround for this issue.
fix-asus-integrated-mode:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors for beautiful UI
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color

    # Unicode symbols
    CHECK="✓"
    CROSS="✗"
    ARROW="→"
    INFO="ℹ"
    WARNING="⚠"
    QUESTION="❓"

    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                 ASUS Integrated Mode Fix                   ║${NC}"
    echo -e "${PURPLE}║          Fixing NVIDIA re-enable after suspend bug        ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    echo -e "${CYAN}${INFO} This script will make the following changes to your system:${NC}"
    echo
    echo -e "${WHITE}  1. ${ARROW} Check and modify /etc/supergfxd.conf if needed${NC}"
    echo -e "${WHITE}     • Set vfio_enable to true (if currently false)${NC}"
    echo -e "${WHITE}     • Create backup of original config${NC}"
    echo -e "${WHITE}     • Restart supergfxd service${NC}"
    echo
    echo -e "${WHITE}  2. ${ARROW} Create system script: /usr/local/bin/dgpu_toggle_forceoff.sh${NC}"
    echo -e "${WHITE}     • Handles DGPU toggle after suspend/resume${NC}"
    echo -e "${WHITE}     • Make script executable${NC}"
    echo
    echo -e "${WHITE}  3. ${ARROW} Create and enable systemd service: dgpu_toggle_forceoff.service${NC}"
    echo -e "${WHITE}     • Automatically runs after system suspend${NC}"
    echo -e "${WHITE}     • Prevents NVIDIA module from re-enabling${NC}"
    echo
    echo -e "${YELLOW}${WARNING} This script requires root privileges (sudo access)${NC}"
    echo

    # Confirmation prompt
    while true; do
        echo -e "${GREEN}${QUESTION} Do you want to proceed with these changes? ${WHITE}[y/N]${NC} "
        read -r response
        case $response in
            [Yy]* ) 
                echo -e "${GREEN}${CHECK} Proceeding with installation...${NC}"
                echo
                break
                ;;
            [Nn]* | "" ) 
                echo -e "${YELLOW}${INFO} Installation cancelled by user${NC}"
                exit 0
                ;;
            * ) 
                echo -e "${RED}${CROSS} Please answer yes (y) or no (n)${NC}"
                ;;
        esac
    done

    # Check if supergfxd config exists
    CONFIG_FILE="/etc/supergfxd.conf"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}${CROSS} Error: $CONFIG_FILE not found${NC}"
        echo -e "${YELLOW}${INFO} This script requires supergfxd to be installed${NC}"
        exit 1
    fi

    echo -e "${CYAN}${INFO} Checking supergfxd configuration...${NC}"

    # Check current vfio_enable setting
    CURRENT_VFIO=$(grep -o '"vfio_enable": *[^,]*' "$CONFIG_FILE" | grep -o '[^: ]*$')

    if [[ "$CURRENT_VFIO" == "true" ]]; then
        echo -e "${GREEN}${CHECK} vfio_enable is already set to true${NC}"
    else
        echo -e "${YELLOW}${ARROW} vfio_enable is currently $CURRENT_VFIO, updating to true...${NC}"

        # Prompt for sudo password upfront
        echo -e "${WHITE}${INFO} Root privileges required to modify supergfxd configuration${NC}"
        sudo -v

        # Create backup
        sudo cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}${INFO} Created backup of configuration file${NC}"

        # Update vfio_enable to true
        sudo sed -i 's/"vfio_enable": false/"vfio_enable": true/' "$CONFIG_FILE"
        echo -e "${GREEN}${CHECK} Updated vfio_enable to true${NC}"

        # Restart supergfxd service
        echo -e "${CYAN}${ARROW} Restarting supergfxd service...${NC}"
        sudo systemctl restart supergfxd.service
        echo -e "${GREEN}${CHECK} supergfxd service restarted${NC}"
    fi

    echo
    echo -e "${CYAN}${INFO} Creating DGPU toggle script...${NC}"

    # Create the script content
    SCRIPT_CONTENT='#!/bin/bash

    # Get current graphics mode and power status
    CURRENT_MODE="$(supergfxctl -g)"
    CURRENT_STATUS="$(supergfxctl -S)"

    # If current graphics mode is '\''Integrated'\'' and the current power status is not '\''off'\''
    if [[ "$CURRENT_MODE" == *"Integrated"* && "$CURRENT_STATUS" != *"off"* ]]; then
      sleep 4

      # Set graphics mode to Vfio
      supergfxctl -m Vfio
      sleep 1

      # Set graphics mode back to Integrated
      supergfxctl -m Integrated
    fi'

    # Write script to file
    echo "$SCRIPT_CONTENT" | sudo tee /usr/local/bin/dgpu_toggle_forceoff.sh > /dev/null
    sudo chmod +x /usr/local/bin/dgpu_toggle_forceoff.sh
    echo -e "${GREEN}${CHECK} Created and made executable: /usr/local/bin/dgpu_toggle_forceoff.sh${NC}"

    echo -e "${CYAN}${INFO} Creating systemd service...${NC}"

    # Create systemd service content
    SERVICE_CONTENT='[Unit]
    Description=toggle vfio mode after suspend...
    After=suspend.target

    [Service]
    User=root
    Type=simple
    ExecStart=/usr/local/bin/dgpu_toggle_forceoff.sh

    [Install]
    WantedBy=suspend.target'

    # Write service file
    echo "$SERVICE_CONTENT" | sudo tee /etc/systemd/system/dgpu_toggle_forceoff.service > /dev/null
    echo -e "${GREEN}${CHECK} Created systemd service: dgpu_toggle_forceoff.service${NC}"

    # Reload systemd and enable service
    echo -e "${CYAN}${ARROW} Enabling systemd service...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable --now dgpu_toggle_forceoff.service
    echo -e "${GREEN}${CHECK} Service enabled and started${NC}"

    echo
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    Setup Complete!                        ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}${CHECK} ASUS integrated mode fix has been successfully applied${NC}"
    echo -e "${WHITE}${INFO} The system will now automatically handle NVIDIA module${NC}"
    echo -e "${WHITE}   re-enabling after suspend/resume cycles.${NC}"
    echo
    echo -e "${YELLOW}Note: You can check service status with:${NC}"
    echo -e "${CYAN}  sudo systemctl status dgpu_toggle_forceoff.service${NC}"
