#!/bin/bash -e

RED='\e[31m'
BLUE='\e[36m'
GREEN='\e[0;32m'
NC='\e[39m' # No Color

ARCH=$(uname -m)

# End script on CTRL + C keypress
trap "exit" INT

# root check
if [ "$(id -u)" -ne 0 ]; then
  echo "Please start the script as ${RED}root${NC}."
  exit
fi

# check if RustDesk binaries are in place (meaning RustDesk has been installed)
if ! [ -f /usr/bin/hbbr ]; then
  echo -e "File /usr/bin/hbbr not found. ${RED}Is RustDesk installed?${NC}"
  exit
fi

if ! [ -f /usr/bin/hbbs ]; then
  echo -e "File /usr/bin/hbbs not found. ${RED}Is RustDesk installed?${NC}"
  exit
fi

echo " "
read -n 1 -r -s -p $'Press any key to start updating RustDesk...\n\n'

echo -e "${BLUE}Version before updating:${NC} $(hbbr -V)"
echo -e "${BLUE}Version before updating:${NC} $(hbbs -V)"

echo " "
echo -e "${GREEN}Stopping hbbr service...${NC}"
systemctl stop rustdesk-hbbr.service

echo " "
echo -e "${GREEN}Stopping hbbs service...${NC}"
systemctl stop rustdesk-hbbs.service

# Download latest version of RustDesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')

echo " "
echo -e "${GREEN}Updating RustDesk...${NC}"
if [ "${ARCH}" = "x86_64" ] ; then
        echo " "
        echo -e "${BLUE}Architecture:${NC} x86_64"
        echo " "
        wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip"
        unzip rustdesk-server-linux-amd64.zip
        sudo mv amd64/hbbr /usr/bin/
        sudo mv amd64/hbbs /usr/bin/
        rm -rf amd64/
elif [ "${ARCH}" = "armv7l" ] ; then
        echo " "
        echo -e "${BLUE}Architecture:${NC} armv7l"
        echo " "
        wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip"
        unzip rustdesk-server-linux-armv7.zip
        sudo mv armv7/hbbr /usr/bin/
        sudo mv armv7/hbbs /usr/bin/
        rm -rf armv7/
elif [ "${ARCH}" = "aarch64" ] ; then
        echo " "
        echo -e "${BLUE}Architecture:${NC} aarch64"
        echo " "
        wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip"
        unzip rustdesk-server-linux-arm64v8.zip
        sudo mv arm64v8/hbbr /usr/bin/
        sudo mv arm64v8/hbbs /usr/bin/
        rm -rf arm64v8/
fi

sudo chmod +x /usr/bin/hbbs
sudo chmod +x /usr/bin/hbbr

echo " "
echo -e "${BLUE}Version after updating:${NC} $(hbbr -V)"
echo -e "${BLUE}Version after updating:${NC} $(hbbs -V)"

echo " "
echo -e "${GREEN}Starting hbbr service...${NC}"
systemctl start rustdesk-hbbr.service

echo " "
echo -e "${GREEN}Starting hbbs service...${NC}"
systemctl start rustdesk-hbbs.service

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
echo -e "${BLUE}Update process finished.${NC}"

echo " "
echo -e "${RED}###########################${NC}"
echo -e "${RED}# !!! IMPORANT NOTICE !!! #${NC}"
echo -e "${RED}###########################${NC}"
echo " "
echo -e "${BLUE}This update script ${RED}DOES NOT update the installer scripts and the rustdesk-api-server!${NC}"
echo " "
echo -e "${BLUE}You have to ${RED}manually${BLUE} check the corresponding repository (${NC}https://github.com/infiniteremote/rustdesk-api-server${BLUE}) and update the scripts in ${NC}/opt/rustdesk-api-server/static/configs${BLUE} accordingly (${NC}https://github.com/infiniteremote/rustdesk-api-server/tree/master/static/configs${BLUE}) io keep them up to date.${NC}"
