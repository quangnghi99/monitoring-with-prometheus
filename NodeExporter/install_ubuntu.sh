#!/bin/bash

#Nhập user/passwd:
read -p "Enter your username: " username
read -sp "Enter your password: " password

#Cài đặt Node exporter
if [[ ! -n $VERSION ]];then
    export VERSION=1.8.2
fi
wget https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz
tar xvfz node_exporter-*.*-amd64.tar.gz
cd node_exporter-*.*-amd64
mv node_exporter /usr/local/bin/

# Basic_auth_users
apt-get install apache2-utils -y
if [[ -n "$username" && -n "$password" ]]; then
    hashed_password=$(htpasswd -nbB "$username" "$password" | awk -F: '{print $2}')
    BASIC_AUTH="$username: $hashed_password"
else
    echo "Username or password was not entered. Skipping..."
fi

if [[ -n $BASIC_AUTH ]];then
    mkdir -p /etc/node_exporter
cat << EOF > /etc/node_exporter/web-config.yml
basic_auth_users:
  $BASIC_AUTH
EOF
    NODE_EXPORTER_ARGS="--web.config.file=/etc/node_exporter/web-config.yml"
fi

cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/node_exporter $NODE_EXPORTER_ARGS
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
cd ../ && rm -rf node_exporter-*
echo "installation has been successfully completed"