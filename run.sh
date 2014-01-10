#!/bin/bash
ADMIN_PASSWORD=${ADMIN_PASSWORD:-docker}
REGISTRY_NAME=${REGISTRY_NAME:-Docker Registry}

# nginx config
cat << EOF > /usr/local/openresty/nginx/conf/registry.conf
user root;
daemon off;
worker_processes 4;
pid /run/nginx.pid;

events {
	worker_connections 2048;
}

http {
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	server_names_hash_bucket_size 64;
	server_name_in_redirect on;

	include /usr/local/openresty/nginx/conf/mime.types;
	default_type application/octet-stream;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;
	gzip_disable "msie6";

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##
        upstream manage {
          server localhost:4000;
        }
        upstream registry {
          server localhost:5000;
        }
        server {
            listen 443;
            ssl on;
            ssl_certificate /etc/registry.crt;
            ssl_certificate_key /etc/registry.key;
            client_max_body_size 0;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme \$scheme;
            proxy_set_header Authorization  "";
            location / {
                auth_basic "$REGISTRY_NAME";
                auth_basic_user_file /etc/registry.users;
                proxy_pass http://registry;
            }
            location /v1/_ping {
                auth_basic off;
                proxy_pass http://registry;
            }
            location /v1/users {
                auth_basic off;
                proxy_pass http://registry;
            }
            location = /manage { rewrite ^ /manage/; }
            location /manage/ { try_files \$uri @manage; }
            location @manage {
                auth_basic "$REGISTRY_NAME";
                auth_basic_user_file /etc/registry.users;
                proxy_redirect off;
                include uwsgi_params;
                uwsgi_param SCRIPT_NAME /manage;
                uwsgi_modifier1 30;
                uwsgi_pass unix:/tmp/uwsgi-manage.sock;
            }
        }
}
EOF

# uwsgi config (registry)
cat << EOF > /etc/registry.ini
[uwsgi]
chdir = /docker-registry
http-socket = 0.0.0.0:5000
workers = 8
buffer-size = 32768
master = true
max-requests = 5000
static-map = /static=/app/static
module = wsgi:application
EOF

# uwsgi config (manage)
cat << EOF > /etc/manage.ini
[uwsgi]
chdir = /app
socket = /tmp/uwsgi-manage.sock
workers = 8
buffer-size = 32768
master = true
max-requests = 5000
static-map = /static=/app/static
module = wsgi:application
EOF

# supervisor config
cat << EOF > /etc/supervisor/supervisor.conf
[supervisord]
nodaemon=false

[unix_http_server]
file=/var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run//supervisor.sock

[program:registry]
priority=10
user=root
command=/usr/local/bin/uwsgi --ini /etc/registry.ini
directory=/docker-registry
autostart=true
autorestart=true
stopsignal=QUIT

[program:manage]
priority=20
user=root
command=/usr/local/bin/uwsgi --ini /etc/manage.ini
directory=/app
autostart=true
autorestart=true
stopsignal=QUIT

[program:nginx]
priority=50
user=root
command=/usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/nginx/conf/registry.conf
directory=/tmp
autostart=true
autorestart=true
EOF

# create password file if needed
if [ ! -e "/etc/registry.users" ] ; then
    htpasswd -bc /etc/registry.users admin $ADMIN_PASSWORD
fi

# run supervisor
supervisord -c /etc/supervisor/supervisor.conf -n
