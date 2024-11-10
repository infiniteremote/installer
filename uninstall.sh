#!/bin/bash

# Get username
usern=$(whoami)

# Stop and disable RustDesk services
echo "Stopping and disabling RustDesk services"
sudo systemctl stop rustdesk-hbbs.service
sudo systemctl stop rustdesk-hbbr.service
sudo systemctl disable rustdesk-hbbs.service
sudo systemctl disable rustdesk-hbbr.service
sudo rm /etc/systemd/system/rustdesk-hbbs.service
sudo rm /etc/systemd/system/rustdesk-hbbr.service
sudo systemctl daemon-reload

# Remove RustDesk executables and folders
echo "Removing RustDesk files and folders"
sudo rm /usr/bin/hbbs
sudo rm /usr/bin/hbbr
sudo rm -rf /var/lib/rustdesk-server
sudo rm -rf /var/log/rustdesk-server

# Remove InfiniteRemote files and services
echo "Removing InfiniteRemote files and services"
sudo systemctl stop rustdesk-api
sudo systemctl disable rustdesk-api
sudo rm /etc/systemd/system/rustdesk-api.service
sudo systemctl daemon-reload
sudo rm -rf /opt/rustdesk-api-server
sudo rm -rf /var/log/rustdesk-server-api

# Remove nginx and Python virtual environment for InfiniteRemote
echo "Removing nginx and certbot for InfiniteRemote"
if [ "$(uname -s)" == "Linux" ]; then
    if command -v apt > /dev/null; then
        sudo apt -y remove nginx python3-certbot-nginx
    elif command -v yum > /dev/null; then
        sudo yum -y remove nginx python3-certbot-nginx
    elif command -v pacman > /dev/null; then
        sudo pacman -R nginx python3-certbot-nginx
    else
        echo "Unsupported OS for package removal"
        exit 1
    fi
fi

# Remove ufw firewall rules if they exist
echo "Removing firewall rules"
if command -v ufw > /dev/null; then
    sudo ufw delete allow 21115:21119/tcp
    sudo ufw delete allow 22/tcp
    sudo ufw delete allow 21116/udp
fi

echo "InfiniteRemote and RustDesk have been removed successfully."
