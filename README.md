# Installation Guide for InfiniteRemote Service via Script 

[Join our discord](https://discord.gg/8AkVusf9)

### Security Disclaimer
Please be aware that while we strive to ensure the security and integrity of our software, no system is entirely immune to vulnerabilities. The InfiniteRemote project is in active development, and while we are committed to security, there could be unintentional risks. We recommend exercising caution, particularly with sensitive information. Consider additional security measures such as running the service on a dedicated server, employing a web application firewall, or limiting access to trusted IPs.

### Why Infinite Remote?
We have started our own project due to the lack of transparency of the RustDesk project and intend on forking and maintaining our own servers and clients, the vulnerabilities in the RustDesk client is too much for business use so we will be working hard on improving the codebase and security.

### Requirements
- A clean installation of Linux we suggest Debian 12 or Ubuntu 22.04.
- A public IP address.
- Open TCP ports 80 (HTTP) and 443 (HTTPS) for external access for the API, open ports 21115-21117 TCP and 21116 UDP for the signal servers and relay servers.
- A Fully Qualified Domain Name (FQDN) pointing to your public IP, e.g., InfiniteRemote.example.com.

## Installation Process
The installation process involves downloading and running the installation script, which automates the setup of the InfiniteRemote service.

Login as Root: Ensure you are logged in as the root user or a user with sufficient privileges to install software and modify system settings.

### Download the Installation Script:

```
wget https://raw.githubusercontent.com/infiniteremote/installer/main/install.sh
```
### Run the Installation Script:

```
bash install.sh
```
Follow the on-screen instructions to complete the installation. The script will guide you through the configuration process, including setting up required software, firewalls, and system services.

### Post-Installation Tasks
After installation, there are several housekeeping tasks you should perform to ensure the smooth operation of your InfiniteRemote service.

Backups: Regularly back up your configuration and data. Pay special attention to any encryption keys or sensitive information managed by the service.
Email Configuration: If your service sends outbound emails (for notifications, alerts, etc.), configure the SMTP settings to ensure reliable email delivery.
Access Control: Review and tighten access controls as necessary. Limit administrative access to trusted users and IPs.
Using the InfiniteRemote Service
Once installed, you can access the InfiniteRemote management interface through your web browser by navigating to your FQDN, e.g., https://InfiniteRemote.example.com and using your username and password setup with the script.

Here, you can download isntallers, view status reports, view connected agents and configure service settings.

### Support and Reporting Issues
If you encounter any issues during installation or while using the service, please open a discussion or [join our discord](https://discord.gg/8AkVusf9).

### Legal Disclaimer
The InfiniteRemote software is provided "as is", without warranty of any kind. By installing and using the software, you accept full responsibility for its deployment and security.

### Conclusion
This guide outlines the steps to install and configure the InfiniteRemote service using an automated script. By following these instructions and recommendations, you can ensure a successful setup and secure operation of your service.
