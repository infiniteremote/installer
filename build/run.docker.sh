#!/bin/bash
cd /opt/rustdesk-api-server
source /opt/rustdesk-api-server/api/env/bin/activate
if [ ! -f /data/hasbeeninitialized ]; then

    pubname=$(find /data/ -name *.pub)
    key=$(cat "${pubname}")

    SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 80 | head -n 1)
    UNISALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
    echo "SECRET_KEY = '${SECRET_KEY}'
SALT_CRED = '${UNISALT}'
CSRF_TRUSTED_ORIGINS = ['https://${URL}']
" > /opt/rustdesk-api-server/rustdesk_server_api/secret_config.py

    echo "Grabbing installers"
    string="{\"host\":\"${URL}\",\"key\":\"${key}\",\"api\":\"https://${URL}\"}"
    string64=$(echo -n "$string" | base64 -w 0 | tr -d '=')
    string64rev=$(echo -n "$string64" | rev)

    echo "$string64rev"

    wget -O /opt/rustdesk-api-server/static/configs/rustdesk-licensed-$string64rev.exe https://github.com/rustdesk/rustdesk/releases/download/1.2.2/rustdesk-1.2.2-x86_64.exe 

    sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/api/templates/installers.html
    sed -i "s|UniqueKey|${key}|g" /opt/rustdesk-api-server/api/templates/installers.html
    sed -i "s|UniqueURL|${URL}|g" /opt/rustdesk-api-server/api/templates/installers.html
    sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install.ps1
    sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install.bat
    sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install-mac.sh
    sed -i "s|secure-string|${string64rev}|g" /opt/rustdesk-api-server/static/configs/install-linux.sh

    qrencode -o /opt/rustdesk-api-server/static/configs/qrcode.png config=${string64rev}

    python manage.py makemigrations
    python manage.py migrate
    python manage.py createsuperuser --noinput --username "${SUPERUSER_USERNAME}" --password "${SUPERUSER_PASSWORD}"
    deactivate
    touch /data/hasbeeninitialized
fi
/opt/rustdesk-api-server/api/env/bin/gunicorn -c /opt/rustdesk-api-server/api/api_config.py