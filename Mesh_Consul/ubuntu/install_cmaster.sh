#!/bin/bash

## install master consul

IP=$(hostname -I | awk '{print $2}')
echo "START - install consul master - "$IP

echo "[1]: install utils"
apt-get update -qq >/dev/null
apt-get install -qq -y wget unzip dnsutils >/dev/null

echo "[2]: install consul"
wget -q https://releases.hashicorp.com/consul/1.13.1/consul_1.13.1_linux_amd64.zip
unzip consul_1.13.1_linux_amd64.zip
mv consul /usr/local/bin/

echo "[3]: create user/group and directory"
groupadd --system consul
useradd -s /sbin/nologin --system -g consul consul
mkdir -p /var/lib/consul
chown -R consul:consul /var/lib/consul
chmod -R 775 /var/lib/consul
mkdir /etc/consul.d
chown -R consul:consul /etc/consul.d

echo "[4]: consul configuration for master"
echo '{
    "advertise_addr": "'$IP'",
    "bind_addr": "'$IP'",
    "bootstrap_expect": 1,
    "client_addr": "0.0.0.0",
    "datacenter": "mydc",
    "data_dir": "/var/lib/consul",
    "domain": "consul",
    "enable_script_checks": true,
    "dns_config": {
        "enable_truncate": true,
        "only_passing": true
    },
    "enable_syslog": true,
    "encrypt": "TeLbPpWX41zMM3vfLwHHfQ==",
    "leave_on_terminate": true,
    "log_level": "INFO",
    "rejoin_after_leave": true,
    "retry_join": [
        "'$IP'"
    ],
    "server": true,
    "start_join": [
        "'$IP'"
    ],
    "ui": true
}' > /etc/consul.d/config.json

echo "[5]: consul create service systemd"
echo '[Unit]
Description=Consul Service Discovery Agent
Documentation=https://www.consul.io/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent \
  -node='$IP' \
  -config-dir=/etc/consul.d

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/consul.service

echo "[6]: consul start service"
systemctl enable consul
service consul start

echo "[7]: add user chagest / psswd= password"
useradd -m -s /bin/bash -p sa3tHJ3/KuYvI -U chagest
echo "%chagest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/chagest

echo "END - install cmaster"
