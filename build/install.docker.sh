#!/bin/bash
cd /opt/rustdesk-api-server/api
python3 -m venv env
source /opt/rustdesk-api-server/api/env/bin/activate
cd /opt/rustdesk-api-server/api/
pip install --no-cache-dir --upgrade pip
pip install --no-cache-dir setuptools wheel
pip install --no-cache-dir -r /opt/rustdesk-api-server/requirements.txt
deactivate
