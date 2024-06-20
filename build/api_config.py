bind = "0.0.0.0:8000"
workers = 4  # Number of worker processes (adjust as needed)
timeout = 120  # Maximum request processing time

wsgi_app = "rustdesk_server_api.wsgi:application"

# Logging
loglevel = "info"