#!/bin/bash -e

#
#      ▌  ▗           ▗  ▌    ▌     ▌ 
# ▌▌▛▌▛▌▀▌▜▘█▌▄▖▛▘▌▌▛▘▜▘▛▌█▌▛▘▙▘  ▛▘▛▌
# ▙▌▙▌▙▌█▌▐▖▙▖  ▌ ▙▌▄▌▐▖▙▌▙▖▄▌▛▖▗ ▄▌▌▌
#   ▌                                 
#                   infiniteremote.com
#
#
# This script is provided "as is", without warranty
# of any kind. By using this script, you accept full
# responsibility for its deployment and security.
#
# Copyright        : All rights reserved!
# License          : GNU Affero General Public License v3.0
# Repository url   : https://github.com/infiniteremote/installer
# Author           : codiflow
# Filename         : update-rustdesk.sh
# Created at       : 2024-11-09
# Last changed at  : 2025-04-22
# Version          : 1.2.1
# Description      : Interactive updater for RustDesk components
#                    written for the RustDesk fork 'Infinite Remote'
#
# Usage            : Just execute the script, all relevant components
#                    will be updated automatically. You will be asked
#                    before the update of RustDesk components (and the
#                    custom client scripts) is being performed

VERSION=1.2.1

RED='\e[31m'
BLUE='\e[36m'
GREEN='\e[0;32m'
YELLOW='\e[93m'
NC='\e[39m' # No Color

ARCH=$(uname -m)

# End script on CTRL + C keypress
trap "exit" INT

# root check
if [ "$(id -u)" -ne 0 ]; then
  echo "Please start the script as ${RED}root${NC}."
  exit
fi

# Function calls

is_rustdesk_installed () {
        # check if RustDesk binaries are in place (meaning RustDesk has been installed)
        if ! [ -f /usr/bin/hbbr ]; then
                echo -e "File /usr/bin/hbbr not found. ${RED}Is RustDesk installed?${NC}"
                exit
        fi

        if ! [ -f /usr/bin/hbbs ]; then
                echo -e "File /usr/bin/hbbs not found. ${RED}Is RustDesk installed?${NC}"
                exit
        fi
}

step_1_update_server () {
        # Get current versions of RustDesk server
        HBBRCURRENT=$(hbbr -V | cut -d " " -f 2)
        HBBSCURRENT=$(hbbr -V | cut -d " " -f 2)

        # Get latest version of RustDesk server
        RDSLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

        echo -e "${BLUE}Currently installed version of ${YELLOW}hbbr${BLUE} before updating: ${YELLOW}${HBBRCURRENT}${NC}"
        echo -e "${BLUE}Currently installed version of ${YELLOW}hbbs${BLUE} before updating: ${YELLOW}${HBBSCURRENT}${NC}"

        echo " "
        echo -e "${BLUE}The latest available RustDesk ${YELLOW}server${BLUE} version is ${YELLOW}${RDSLATEST}${NC}"

        if [ "${HBBRCURRENT}" = "${HBBSCURRENT}" ] && [ "${HBBSCURRENT}" = "${RDSLATEST}" ]; then
                echo " "
                echo -e "${BLUE}RustDesk server is ${GREEN}already up to date${BLUE}. Let's continue with STEP 2...${NC}"
                return
        fi

        echo " "
        read -r -p $'STEP 1: Press [ENTER] to start updating RustDesk server or quit using [CTRL] + [C]...\n\n'

        # Stopping running services
        echo " "
        echo -e "${GREEN}Stopping hbbr service...${NC}"
        systemctl stop rustdesk-hbbr.service

        echo " "
        echo -e "${GREEN}Stopping hbbs service...${NC}"
        systemctl stop rustdesk-hbbs.service

        echo " "
        echo -e "${GREEN}Updating RustDesk server...${NC}"

        echo " "
        echo -e "${GREEN}Downloading latest version of RustDesk server...${NC}"

        # Download RustDesk server
        if [ "${ARCH}" = "x86_64" ] ; then
                echo " "
                echo -e "${BLUE}Architecture:${NC} x86_64"
                echo " "
                wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDSLATEST}/rustdesk-server-linux-amd64.zip"
                unzip rustdesk-server-linux-amd64.zip
                sudo mv amd64/hbbr /usr/bin/
                sudo mv amd64/hbbs /usr/bin/
                rm -rf amd64/
        elif [ "${ARCH}" = "armv7l" ] ; then
                echo " "
                echo -e "${BLUE}Architecture:${NC} armv7l"
                echo " "
                wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDSLATEST}/rustdesk-server-linux-armv7.zip"
                unzip rustdesk-server-linux-armv7.zip
                sudo mv armv7/hbbr /usr/bin/
                sudo mv armv7/hbbs /usr/bin/
                rm -rf armv7/
        elif [ "${ARCH}" = "aarch64" ] ; then
                echo " "
                echo -e "${BLUE}Architecture:${NC} aarch64"
                echo " "
                wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDSLATEST}/rustdesk-server-linux-arm64v8.zip"
                unzip rustdesk-server-linux-arm64v8.zip
                sudo mv arm64v8/hbbr /usr/bin/
                sudo mv arm64v8/hbbs /usr/bin/
                rm -rf arm64v8/
        fi

        # Marking downloads as executable
        sudo chmod +x /usr/bin/hbbs
        sudo chmod +x /usr/bin/hbbr

        echo " "
        echo -e "${BLUE}Installed version after updating:${NC} $(hbbr -V)"
        echo -e "${BLUE}Installed version after updating:${NC} $(hbbs -V)"

        # Starting services again
        echo " "
        echo -e "${GREEN}Starting hbbr service...${NC}"
        systemctl start rustdesk-hbbr.service

        echo " "
        echo -e "${GREEN}Starting hbbs service...${NC}"
        systemctl start rustdesk-hbbs.service

        # Cleaning up
        echo " "
        echo -e "${GREEN}Cleaning up...${NC}"

        if [ "${ARCH}" = "x86_64" ] ; then
                rm rustdesk-server-linux-amd64.zip
                rm -rf amd64
        elif [ "${ARCH}" = "armv7l" ] ; then
                rm rustdesk-server-linux-armv7.zip
                rm -rf armv7
        elif [ "${ARCH}" = "aarch64" ] ; then
                rm rustdesk-server-linux-arm64v8.zip
                rm -rf arm64v8
        fi

        echo " "
        echo -e "${GREEN}Update process for RustDesk server finished.${NC}"
}

step_2_update_client () {
        echo " "
        read -r -p $'STEP 2: Press [ENTER] to start updating RustDesk client config version strings now or quit using [CTRL] + [C]...\n\n'

        # Get latest version of RustDesk client
        RDCLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk/releases/latest -s | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

        echo -e "${BLUE}The latest available RustDesk ${YELLOW}client${BLUE} version is ${YELLOW}${RDCLATEST}${NC}"

        echo " "
        read -r -p $'Press any key to start updating RustDesk client config strings or quit using [CTRL] + [C]...\n\n'

        # Updating client config strings
        echo -e "${BLUE}Setting version string for Windows Batch client config (install.bat)...${NC}"
        sed -i "s@^set version=.*@set version=${RDCLATEST}@g" /opt/rustdesk-api-server/static/configs/install.bat

        echo " "
        echo -e "${BLUE}Setting version string for Linux client config (install-linux.sh)...${NC}"
        sed -i "s@^VERSION=\".*\"@VERSION=\"${RDCLATEST}\"@g" /opt/rustdesk-api-server/static/configs/install-linux.sh

        echo " "
        echo -e "${BLUE}Setting version string for macOS client config (install-mac.sh)...${NC}"
        sed -i "s@^VERSION=\".*\"@VERSION=\"${RDCLATEST}\"@g" /opt/rustdesk-api-server/static/configs/install-mac.sh

        echo " "
        echo -e "${BLUE}Setting version string for Windows Powershell client config (install.ps1)...${NC}"
        sed -i "s@^\$version = \".*\"@\$version = \"${RDCLATEST}\"@g" /opt/rustdesk-api-server/static/configs/install.ps1

        echo " "
        echo -e "${BLUE}Downloading new Windows client with config string in filename (rustdesk-licensed-XXX.exe)...${NC}"
        RDCONFIGSTRING=$(find /opt/rustdesk-api-server/static/configs -iname "rustdesk-licensed-*" | head -n 1 | cut -d "-" -f 5 | cut -d "." -f 1)
        FILEOWNER=$(stat -c "%U:%G" "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe")

        # Check if length of config string is not empty
        if ! [ "${RDCONFIGSTRING}" = "" ]; then
                # Remove old file if it exists
                rm -f "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe.old"

                # Create backup
                mv "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe" "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe.old"

                # Get new version from GitHub
                wget -q https://github.com/rustdesk/rustdesk/releases/download/"${RDCLATEST}"/rustdesk-"${RDCLATEST}"-x86_64.exe -O "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe"
                # Change file owner to match the backup
                chown "${FILEOWNER}" "/opt/rustdesk-api-server/static/configs/rustdesk-licensed-${RDCONFIGSTRING}.exe"
        else
                echo " "
                echo -e "${RED}There has been some issue while replacing the new Windows client with config string in filename. Please investigate.${NC}"
        fi

        echo " "
        echo -e "${GREEN}Update process for RustDesk client config version strings finished.${NC}"
}

# Main script starts here

is_rustdesk_installed

# Introduction
echo " "
echo -e "${BLUE}      ▌  ▗           ▗  ▌    ▌     ▌ "
echo -e " ▌▌▛▌▛▌▀▌▜▘█▌▄▖▛▘▌▌▛▘▜▘▛▌█▌▛▘▙▘  ▛▘▛▌"
echo -e " ▙▌▙▌▙▌█▌▐▖▙▖  ▌ ▙▌▄▌▐▖▙▌▙▖▄▌▛▖▗ ▄▌▌▌"
echo -e "   ▌                                 "
echo -e "                   infiniteremote.com"
echo " "
echo -e " Script version:   ${YELLOW}${VERSION}${BLUE}"
echo -e " Architecture:     ${YELLOW}${ARCH}${BLUE}"
echo -e " Author:           ${YELLOW}codiflow${NC}"
echo " "
echo -e "${BLUE}This script updates RustDesk ${YELLOW}server${BLUE} first (STEP 1) and asks to update RustDesk ${YELLOW}client config version strings${BLUE} afterwards (STEP 2).${NC}"

echo " "
read -r -p $'Press [ENTER] to start updating RustDesk components now or quit using [CTRL] + [C]...\n\n'

step_1_update_server

step_2_update_client

echo " "
echo -e "${RED}############################${NC}"
echo -e "${RED}# !!! IMPORTANT NOTICE !!! #${NC}"
echo -e "${RED}############################${NC}"
echo " "
echo -e "${BLUE}This update script ${RED}DOES NOT update the rustdesk-api-server including the client config scripts itself${BLUE} (only the version string has been updated within them)!${NC}"
echo " "
echo -e "${BLUE}You have to ${RED}MANUALLY${BLUE} check the corresponding repository (${NC}https://github.com/infiniteremote/rustdesk-api-server${BLUE}) for relevant changes and update it (including the client config scripts) using ${NC}git pull${BLUE} within ${NC}/opt/rustdesk-api-server${BLUE}.${NC}"
echo " "
