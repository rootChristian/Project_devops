#!/bin/bash


IP=$(hostname -I | awk '{print $2}')

echo "START - install myapp $IP"

echo "[1] - install consul"

apt-get -qq update >/dev/null

apt-get -qq install -y wget unzip dnsutils python-pip python-flask >/dev/null

wget -q https://releases.hashicorp.com/consul/1.13.1/consul_1.13.1_linux_amd64.zip >/dev/null
unzip consul_1.13.1_linux_amd64.zip
mv consul /usr/local/bin/ 
groupadd --system consul
useradd -s /sbin/nologin --system -g consul consul 
mkdir -p /var/lib/consul 
chown -R consul:consul /var/lib/consul 
chmod -R 775 /var/lib/consul 
mkdir /etc/consul.d 
chown -R consul:consul /etc/consul.d

echo "[2] - install configuration file"

echo '{
    "advertise_addr": "'$IP'",
    "bind_addr": "'$IP'",
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
    "192.168.56.100"
    ]
}' >/etc/consul.d/config.json

echo "[3] - install service systemd consul"
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
  -data-dir=/var/lib/consul \
  -config-dir=/etc/consul.d

ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=consul

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/consul.service

systemctl enable consul
service consul start

echo "[4] - install myapp"

pip install -q prometheus_client
mkdir /var/myapp/
echo "#!/usr/bin/python
from flask import Flask,request,Response
from prometheus_client import (generate_latest,CONTENT_TYPE_LATEST )             
import socket
app = Flask(__name__)

@app.route('/')
def hello_world():
  hostname = socket.gethostname()
  message = 'Hi, i am ' + hostname + '\n'
  return message

@app.route('/metrics')
def metrics():
  return Response(generate_latest(),mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=80)
">/var/myapp/myapp.py
chmod 755 /var/myapp/myapp.py

echo "[5] - install myapp service systemd"
echo '[Unit]
Description=MyApp service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/var/myapp/myapp.py \
ExecReload=/bin/kill -HUP $KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/myapp.service

systemctl enable myapp
service myapp start

echo "[6] - add service myapp to consul"

echo '
{"service":
  {
  "name": "myapp",
  "tags": ["myapp","python","metrics","url:myapp.localhost"],
  "port": 80,
  "check": {
     "http": "http://localhost:80/metrics",
     "interval": "3s"
    }
  }
}
' >/etc/consul.d/service_myapp.json
consul reload

echo "[7] - install linkerd"
apt-get -y -q install openjdk-11-jdk >/dev/null
wget -q https://github.com/linkerd/linkerd/releases/download/1.7.5/linkerd-1.7.5-exec -P /usr/local/bin/
chmod 755 /usr/local/bin/linkerd-1.7.5-exec
mkdir /etc/linkerd/

echo '
admin:
  ip: 0.0.0.0
  port: 9990
routers:
- protocol: http
  label: /http-consul
  service:
    totalTimeoutMs: 20000
    retries:
      budget:
        minRetriesPerSec: 5
        percentCanRetry: 0.2
        ttlSecs: 15
      backoff:
        kind: jittered
        minMs: 2000
        maxMs: 5000
  servers:
  - port: 4040
    ip: 0.0.0.0
  identifier:
   kind: io.l5d.header.token
  dtab: |
       /svc => /#/192.168.56.100/mydc;
  client:
    failureAccrual:
      kind: io.l5d.successRateWindowed
      successRate: 0.7
      window: 60
    loadBalancer:
      kind: p2c
      maxEffort: 3


namers:
- kind: io.l5d.consul
  host: 192.168.56.100
  includeTag: false
  useHealthCheck: true
  prefix: /192.168.56.100
  consistencyMode: stale
  failFast: true


telemetry:
- kind: io.l5d.prometheus
' > /etc/linkerd/linkerd.yml

echo '[Unit]
Description=Linkerd
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/linkerd-1.7.5-exec /etc/linkerd/linkerd.yml
KillSignal=SIGINT
TimeoutStopSec=10
Restart=on-failure
SyslogIdentifier=linkerd

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/linkerd.service

systemctl enable linkerd
service linkerd start

echo "END - install myapp $IP"

