5. make status page
#!/bin/bash

# Get username
usern=$(whoami)
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)

ARCH=$(uname -m)

echo -ne "Enter your preferred domain/DNS address: "
read wanip
# Check wanip is valid domain
if ! [[ $wanip =~ ^[a-zA-Z0-9]+([a-zA-Z0-9.-]*[a-zA-Z0-9]+)?$ ]]; then
    echo -e "Invalid domain/DNS address"
    exit 1
fi

# Identify OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    UPSTREAM_ID=${ID_LIKE,,}

    # Fallback to ID_LIKE if ID was not 'ubuntu' or 'debian'
    if [ "${UPSTREAM_ID}" != "debian" ] && [ "${UPSTREAM_ID}" != "ubuntu" ]; then
        UPSTREAM_ID="$(echo ${ID_LIKE,,} | sed s/\"//g | cut -d' ' -f1)"
    fi

elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian, Ubuntu, etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSE-release ]; then
    # Older SuSE, etc.
    OS=SuSE
    VER=$(cat /etc/SuSE-release)
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi


# Output debugging info if $DEBUG set
if [ "$DEBUG" = "true" ]; then
    echo "OS: $OS"
    echo "VER: $VER"
    echo "UPSTREAM_ID: $UPSTREAM_ID"
    exit 0
fi

# Setup prereqs for server
# Common named prereqs
PREREQ="curl wget unzip tar git qrencode python3.11-venv"
PREREQDEB="dnsutils ufw"
PREREQRPM="bind-utils"
PREREQARCH="bind"

echo "Installing prerequisites"
if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ] || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y ${PREREQ} ${PREREQDEB} # git
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ] || [ "${UPSTREAM_ID}" = "rhel" ] || [ "${OS}" = "Almalinux" ] || [ "${UPSTREAM_ID}" = "Rocky*" ] ; then
# openSUSE 15.4 fails to run the relay service and hangs waiting for it
# Needs more work before it can be enabled
# || [ "${UPSTREAM_ID}" = "suse" ]
    sudo yum update -y
    sudo yum install -y ${PREREQ} ${PREREQRPM} # git
elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]; then
    sudo pacman -Syu
    sudo pacman -S ${PREREQ} ${PREREQARCH}
else
    echo "Unsupported OS"
    # Here you could ask the user for permission to try and install anyway
    # If they say yes, then do the install
    # If they say no, exit the script
    exit 1
fi

# Setting up firewall
sudo ufw allow 21115:21119/tcp
sudo ufw allow 22/tcp
sudo ufw allow 21116/udp
sudo ufw enable

# Make folder /var/lib/rustdesk-server/
if [ ! -d "/var/lib/rustdesk-server" ]; then
    echo "Creating /var/lib/rustdesk-server"
    sudo mkdir -p /var/lib/rustdesk-server/
fi

sudo chown "${usern}" -R /var/lib/rustdesk-server
cd /var/lib/rustdesk-server/ || exit 1


# Download latest version of RustDesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name"| awk '{print substr($2, 2, length($2)-3) }')

echo "Installing RustDesk Server"
if [ "${ARCH}" = "x86_64" ] ; then
wget https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip
unzip rustdesk-server-linux-amd64.zip
sudo mv amd64/hbbr /usr/bin/
sudo mv amd64/hbbs /usr/bin/
rm -rf amd64/
rm -rf rustdesk-server-linux-amd64.zip
elif [ "${ARCH}" = "armv7l" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip"
unzip rustdesk-server-linux-armv7.zip
sudo mv armv7/hbbr /usr/bin/
sudo mv armv7/hbbs /usr/bin/
rm -rf armv7/
rm -rf rustdesk-server-linux-armv7.zip
elif [ "${ARCH}" = "aarch64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip"
unzip rustdesk-server-linux-arm64v8.zip
sudo mv arm64v8/hbbr /usr/bin/
sudo mv arm64v8/hbbs /usr/bin/
rm -rf arm64v8/
rm -rf rustdesk-server-linux-arm64v8.zip
fi

sudo chmod +x /usr/bin/hbbs
sudo chmod +x /usr/bin/hbbr


# Make folder /var/log/rustdesk-server/
if [ ! -d "/var/log/rustdesk-server" ]; then
    echo "Creating /var/log/rustdesk-server"
    sudo mkdir -p /var/log/rustdesk-server/
fi
sudo chown "${usern}" -R /var/log/rustdesk-server/

# Setup systemd to launch hbbs
rustdeskhbbs="$(cat << EOF
[Unit]
Description=RustDesk Signal Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/usr/bin/hbbs -r $wanip
WorkingDirectory=/var/lib/rustdesk-server/
User=${usern}
Group=${usern}
Restart=always
StandardOutput=append:/var/log/rustdesk-server/hbbs.log
StandardError=append:/var/log/rustdesk-server/hbbs.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskhbbs}" | sudo tee /etc/systemd/system/rustdesk-hbbs.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdesk-hbbs.service
sudo systemctl start rustdesk-hbbs.service

# Setup systemd to launch hbbr
rustdeskhbbr="$(cat << EOF
[Unit]
Description=RustDesk Relay Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/usr/bin/hbbr
WorkingDirectory=/var/lib/rustdesk-server/
User=${usern}
Group=${usern}
Restart=always
StandardOutput=append:/var/log/rustdesk-server/hbbr.log
StandardError=append:/var/log/rustdesk-server/hbbr.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskhbbr}" | sudo tee /etc/systemd/system/rustdesk-hbbr.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable rustdesk-hbbr.service
sudo systemctl start rustdesk-hbbr.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$(sudo systemctl status rustdesk-hbbr.service | grep "Active: active (running)")
  echo -ne "RustDesk Relay not ready yet...${NC}\n"
  sleep 3
done

pubname=$(find /var/lib/rustdesk-server/ -name "*.pub")
key=$(cat "${pubname}")

echo "Tidying up install"
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

cd /opt

git clone https://github.com/infiniteremote/rustdesk-api-server.git

cd rustdesk-api-server

sudo chown -R ${usern}:${usern} /opt/rustdesk-api-server/


SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 80 | head -n 1)
UNISALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)

secret_config="$(
  cat <<EOF
SECRET_KEY = "${SECRET_KEY}"

EOF
)"
echo "${secret_config}" >/opt/rustdesk-api-server/rustdesk_server_api/secret_config.py

if [ ! -d "/var/log/rustdesk-server-api" ]; then
    echo "Creating /var/log/rustdesk-server-api"
    sudo mkdir -p /var/log/rustdesk-server-api/
fi

sudo chown -R ${usern}:${usern} /var/log/rustdesk-server-api/

sed -i "s|xiaomo|${UNISALT}|g" /opt/rustdesk-api-server/api/views_front.py

cd /opt/rustdesk-api-server/api
python3 -m venv env
source /opt/rustdesk-api-server/api/env/bin/activate
cd /opt/rustdesk-api-server/api/
pip install --no-cache-dir --upgrade pip
pip install --no-cache-dir setuptools wheel
pip install --no-cache-dir -r /opt/rustdesk-api-server/requirements.txt
cd /opt/rustdesk-api-server/
python manage.py makemigrations
python manage.py migrate
echo "Please Set your password and username for the Web UI"
python manage.py securecreatesuperuser
deactivate

apiconfig="$(
  cat <<EOF
bind = "127.0.0.1:8000"
workers = 4  # Number of worker processes (adjust as needed)
timeout = 120  # Maximum request processing time
user = "${usern}"  # User to run Gunicorn as
group = "${usern}"  # Group to run Gunicorn as

wsgi_app = "rustdesk_server_api.wsgi:application"

# Logging
errorlog = "/var/log/rustdesk-server-api/error.log"
accesslog = "/var/log/rustdesk-server-api/access.log"
loglevel = "info"
EOF
)"
echo "${apiconfig}" | sudo tee /opt/rustdesk-api-server/api/api_config.py >/dev/null

apiservice="$(
  cat <<EOF
[Unit]
Description=rustdesk-api-server gunicorn daemon

[Service]
User=${usern}
WorkingDirectory=/opt/rustdesk-api-server/
Environment="PATH=/opt/rustdesk-api-server/api/env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/rustdesk-api-server/api/env/bin/gunicorn -c /opt/rustdesk-api-server/api/api_config.py
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
)"
echo "${apiservice}" | sudo tee /etc/systemd/system/rustdesk-api.service >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable rustdesk-api
sudo systemctl start rustdesk-api

echo "Installing nginx"
if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ] || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]; then
    sudo apt -y install nginx
    sudo apt -y install python3-certbot-nginx
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ] || [ "${UPSTREAM_ID}" = "rhel" ] || [ "${OS}" = "Almalinux" ] || [ "${UPSTREAM_ID}" = "Rocky*" ] ; then
# openSUSE 15.4 fails to run the relay service and hangs waiting for it
# Needs more work before it can be enabled
# || [ "${UPSTREAM_ID}" = "suse" ]
    sudo yum -y install nginx
    sudo yum -y install python3-certbot-nginx
elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]; then
    sudo pacman -S install nginx
    sudo pacman -S install python3-certbot-nginx
else
    echo "Unsupported OS"
    # Here you could ask the user for permission to try and install anyway
    # If they say yes, then do the install
    # If they say no, exit the script
    exit 1
fi

rustdesknginx="$(
  cat <<EOF
server {
  server_name ${wanip};
      location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
}
}
EOF
)"
echo "${rustdesknginx}" | sudo tee /etc/nginx/sites-available/rustdesk.conf >/dev/null

sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

sudo ln -s /etc/nginx/sites-available/rustdesk.conf /etc/nginx/sites-enabled/rustdesk.conf

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw enable && ufw reload

sudo certbot --nginx -d ${wanip}

echo "Grabbing installers"
string="{\"host\":\"${wanip}\",\"key\":\"${key}\",\"api\":\"https://${wanip}\"}"
string64=$(echo -n "$string" | base64 -w 0 | tr -d '=')
string64rev=$(echo -n "$string64" | rev)

echo "$string64rev"

wget -O /opt/rustdesk-api-server/static/configs/rustdesk-licensed-$string64rev.exe https://github.com/rustdesk/rustdesk/releases/download/1.2.2/rustdesk-1.2.2-x86_64.exe 

sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/api/templates/installers.html
sed -i "s|UniqueKey|${key}|g" /opt/rustdesk-api-server/api/templates/installers.html
sed -i "s|UniqueURL|${wanip}|g" /opt/rustdesk-api-server/api/templates/installers.html
sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install.ps1
sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install.bat
sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install-mac.sh
sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install-linux.sh

qrencode -o /opt/rustdesk-api-server/static/configs/qrcode.png config=${string64rev}


