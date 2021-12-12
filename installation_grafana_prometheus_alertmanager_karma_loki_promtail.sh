#!/bin/bash



#----------------------------------------------------------------------------WEBSITE SOURCE & WEBSITE APPLICATIF------------------------------------------------------------------------------
#loki
#https://levelup.gitconnected.com/loki-installation-in-ubuntu-2eb8407de291
#https://lindevs.com/install-loki-on-ubuntu/
#https://www.aukfood.fr/collecter-et-afficher-les-logs-avec-grafana-loki/
#https://itnext.io/monitoring-your-docker-containers-logs-the-loki-way-e9fdbae6bafd

#prometheus & alertmanager
#https://www.leaseweb.com/labs/2020/03/measuring-and-monitoring-with-prometheus-and-alertmanager/
#https://www.leaseweb.com/labs/2021/01/measuring-and-monitoring-with-prometheus-and-alertmanager-part-2/
#https://timber.io/blog/promql-for-humans/
#https://awesome-prometheus-alerts.grep.to/
#https://www.robustperception.io/tag/prometheus
#https://prometheus.io/docs/instrumenting/exporters/
#https://prometheus.io/docs/introduction/overview/
#http://<ip>:9090/
#Prometheus provides two convenient endpoints for monitoring its health and status
#http://<ip>:9090/-/healthy
#http://<ip>:9090/-/ready
#This default target collects metrics about the performance of the Prometheus server. You can view the metrics that are being recorded under http://<server IP>:9090/metrics.
#http://<ip>:9090/metrics

#karma
#https://github.com/prymitive/karma/blob/main/docs/CONFIGURATION.md
#http://<ip>:8092/karma/
#karma

#grafana
#http://<ip>:3000/

#alertmanager
#http://<ip>:9093/#/status

#The node exporter listens on TCP port 9100. You should be able to see the node exporter metrics now at http://<server IP>:9100/metrics
#http://<ip>:9100

#----------------------------------------------------------------------------FIN WEBSITE SOURCE & WEBSITE APPLICATIF------------------------------------------------------------------------------

#----------------------------------------------------------------------------VARIABLES GLOBALES------------------------------------------------------------------------------
#LOKI
URL_GITHUB_LOKI_ZIP="https://github.com/grafana/loki/releases/download/v2.2.1/loki-linux-amd64.zip"
#URL_GITHUB_LOKI_YAML="https://raw.githubusercontent.com/grafana/loki/v2.2.1/cmd/loki/loki-local-config.yaml"
USER_LOKI="loki"
GROUP_LOKI="loki"
PATH_CONFIG_LOKI="/etc/loki"
CONFIG_FILE_LOKI="loki.yaml"
PATH_LOKI="/usr/local/bin"

#PROMTAIL
URL_GITHUB_PROMTAIL_ZIP="https://github.com/grafana/loki/releases/download/v2.2.1/promtail-linux-amd64.zip"
#URL_GITHUB_PROMTAIL_YAML="https://raw.githubusercontent.com/grafana/loki/v2.2.1/cmd/promtail/promtail-local-config.yaml"
USER_PROMTAIL="promtail"
GROUP_PROMTAIL="promtail"
PATH_CONFIG_PROMTAIL="/etc/promtail"
CONFIG_FILE_PROMTAIL="promtail.yaml"
PATH_PROMTAIL="/usr/local/bin"

#PROMETHEUS
URL_GITHUB_PROMETHEUS_TAR_GZ="https://github.com/prometheus/prometheus/releases/download/v2.31.1/prometheus-2.31.1.linux-amd64.tar.gz"
URL_GITHUB_PROMETHEUS_SHASUM="https://github.com/prometheus/prometheus/releases/download/v2.31.1/sha256sums.txt"
USER_PROMETHEUS="prometheus"
GROUP_PROMETHEUS="prometheus"
PATH_CONFIG_PROMETHEUS="/etc/prometheus"
CONFIG_FILE_PROMETHEUS="prometheus.yml"
PATH_PROMETHEUS="/usr/local/bin"
PATH_LIB_PROMETHEUS="/var/lib/prometheus"
PATH_RULE_PROMETHEUS="/etc/prometheus/rules"
RULE_FILE_PROMETHEUS="alert-rules.yml"

#NODE_EXPORTER
URL_GITHUB_NODE_EXPORTER_TAR_GZ="https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz"
URL_GITHUB_NODE_EXPORTER_SHASUM="https://github.com/prometheus/node_exporter/releases/download/v1.3.1/sha256sums.txt"

#ALERTMANAGER
URL_GITHUB_ALERTMANAGER_TAR_GZ="https://github.com/prometheus/alertmanager/releases/download/v0.23.0/alertmanager-0.23.0.linux-amd64.tar.gz"
URL_GITHUB_ALERTMANAGER_SHASUM="https://github.com/prometheus/alertmanager/releases/download/v0.23.0/sha256sums.txt"
USER_ALERTMANAGER="alertmanager"
GROUP_ALERTMANAGER="alertmanager"
PATH_CONFIG_ALERTMANAGER="/etc/alertmanager"
CONFIG_FILE_ALERTMANAGER="alertmanager.yml"
PATH_ALERTMANAGER="/usr/local/bin"

#KARMA
URL_GITHUB_KARMA_TAR_GZ="https://github.com/prymitive/karma/releases/download/v0.93/karma-linux-amd64.tar.gz"
URL_GITHUB_KARMA_SHASUM="https://github.com/prymitive/karma/releases/download/v0.93/sha512sum.txt"
USER_KARMA="karma"
GROUP_KARMA="karma"
PATH_CONFIG_KARMA="/etc/karma"
CONFIG_FILE_KARMA="karma.yml"
PATH_KARMA="/usr/local/bin"

#---------------------------------------------------------------------------FIN VARIABLES GLOBALES-----------------------------------------------------------------------------


#--------------------------------------------Installation de Loki-----------------------------------------------------------------------------------------------------------------------


cd /tmp || exit 2
sudo useradd -M -r -s /bin/false ${USER_LOKI}
sudo mkdir ${PATH_CONFIG_LOKI}
sudo chown -R ${USER_LOKI}:${GROUP_LOKI} ${PATH_CONFIG_LOKI}
curl -O -L ${URL_GITHUB_LOKI_ZIP}
unzip /tmp/loki-linux-amd64.zip
sudo mv /tmp/loki-linux-amd64 ${PATH_LOKI}
sudo chown ${USER_LOKI}:${GROUP_LOKI} ${PATH_LOKI}/loki-linux-amd64
#wget URL_GITHUB_LOKI_YAML
#sudo mv loki-local-config.yaml ${PATH_LOKI}
rm -f /tmp/loki-linux-amd64.zip

cat << EOF | sudo tee -a ${PATH_CONFIG_LOKI}/${CONFIG_FILE_LOKI}
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  wal:
    enabled: true
    dir: /tmp/wal
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /tmp/loki/rules
  rule_path: /tmp/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
EOF

sudo chown ${USER_LOKI}:${GROUP_LOKI} ${PATH_CONFIG_LOKI}/${CONFIG_FILE_LOKI}

cat << EOF | sudo tee -a /etc/systemd/system/loki.service
[Unit]
Description=Loki log aggregation system
After=network.target
 
[Service]
ExecStart=/usr/local/bin/loki-linux-adm64 -config.file=/etc/loki/loki.yaml
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start loki
sudo systemctl enable loki
sudo systemctl restart grafana-server

#------------------------------------------------Fin Installation de Loki-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------Installation de promtail----------------------------------------------------------------------------------------------------------------
cd /tmp || exit 3
sudo useradd -M -r -s /bin/false ${USER_PROMTAIL}
sudo mkdir ${PATH_CONFIG_PROMTAIL}
sudo chown -R ${USER_PROMTAIL}:${GROUP_PROMTAIL} ${PATH_CONFIG_PROMTAIL}
curl -O -L ${URL_GITHUB_PROMTAIL_ZIP}
unzip /tmp/promtail-linux-amd64.zip
sudo mv /tmp/promtail-linux-amd64 ${PATH_PROMTAIL}
sudo chown ${USER_PROMTAIL}:${GROUP_PROMTAIL} ${PATH_PROMTAIL}/promtail-linux-amd64
#wget URL_GITHUB_PROMTAIL_YAML
#sudo mv promtail-local-config.yaml ${PATH_PROMTAIL}
rm -f /tmp/promtail-linux-amd64.zip

cat << EOF | sudo tee -a ${PATH_CONFIG_PROMTAIL}/${CONFIG_FILE_PROMTAIL}
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push
# - url: http://{loki_server}:3100/loki/api/v1/push
scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log
- job_name: systemd-journal
  journal:
    labels:
      job: systemd-journal
  relabel_configs:
    - source_labels: ['__journal__systemd_unit']
      target_label: 'unit'    
  pipeline_stages:
  - match:
      selector: '{job="systemd-journal"}'
      stages:
      - regex:
          expression: ".*(?P<error_message>error*)"
      - metrics:
          error_total_journal:
            type: Counter
            description: "total count of errors"
            source: error_message
            config:
              action: inc    
- job_name: my-container-logs
  static_configs:
  - targets: # tells promtail to look for the logs on the current machine/host
      - localhost
    labels: # labels with which all the following logs should be labelled
      job: my-container  # label-1
      host: localhost    # label-2
      __path__: /var/lib/docker/containers/{,*/}{*.log}
EOF

sudo chown ${USER_PROMTAIL}:${GROUP_PROMTAIL} ${PATH_CONFIG_PROMTAIL}/${CONFIG_FILE_PROMTAIL}

cat << EOF | sudo tee -a /etc/systemd/system/promtail.service
[Unit]
Description=Loki log aggregation system
After=network.target
 
[Service]
ExecStart=/usr/local/bin/promtail-linux-amd64 -config.file=/etc/promtail/promtail.yaml
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start promtail
sudo systemctl enable promtail
sudo systemctl restart grafana-server

#-----------------------------------------Fin installation de promtail----------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------Installation Prometheus-------------------------------------------------------------------------------------
cd /tmp || exit 4
wget ${URL_GITHUB_PROMETHEUS_TAR_GZ}
wget -O - -q ${URL_GITHUB_PROMETHEUS_SHASUM} | grep linux-amd64 | shasum -c -
sudo useradd -M -r -s /bin/false ${USER_PROMETHEUS}
sudo mkdir ${PATH_CONFIG_PROMETHEUS} ${PATH_LIB_PROMETHEUS}
sudo chown -R ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_CONFIG_PROMETHEUS}
sudo chown ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_LIB_PROMETHEUS}
tar xzf prometheus-2.31.1.linux-amd64.tar.gz
sudo cp prometheus-2.31.1.linux-amd64/{prometheus,promtool} ${PATH_PROMETHEUS}
sudo chown ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_PROMETHEUS}/{prometheus,promtool}
sudo cp -r prometheus-2.31.1.linux-amd64/{consoles,console_libraries} ${PATH_LIB_PROMETHEUS}
#sudo cp prometheus-2.31.1.linux-amd64/${CONFIG_FILE_PROMETHEUS} ${PATH_CONFIG_PROMETHEUS}/${CONFIG_FILE_PROMETHEUS}
#sudo chown -R ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_CONFIG_PROMETHEUS}/${CONFIG_FILE_PROMETHEUS}
rm -f /tmp/prometheus-2.31.1.linux-amd64.tar.gz
rm -rf /tmp/prometheus-2.31.1.linux-amd64

cat << EOF | sudo tee -a ${PATH_CONFIG_PROMETHEUS}/${CONFIG_FILE_PROMETHEUS}
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "/etc/prometheus/rules/*.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
  - job_name: 'node'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
      - targets: ['<ip_second_server>:9100']
EOF

sudo chown ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_CONFIG_PROMETHEUS}/${CONFIG_FILE_PROMETHEUS}

#sudo cat  << EOF >> /etc/systemd/system/prometheus.service
cat  << EOF | sudo tee -a /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Time Series Collection and Processing Server
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl restart grafana-server

#-----------------------------------------------------------Fin installation Prometheus-------------------------------------------------------------------------------------


#-------------------------------------------------------Installation node_exporter---------------------------------------------------------------------------------------
cd /tmp || exit 5
sudo useradd -M -r -s /bin/false prometheus
sudo mkdir /etc/prometheus /var/lib/prometheus
wget ${URL_GITHUB_NODE_EXPORTER_TAR_GZ}
wget -O - -q ${URL_GITHUB_NODE_EXPORTER_SHASUM}  | grep linux-amd64 | shasum -c -
tar xzf node_exporter-1.3.1.linux-amd64.tar.gz
sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/node_exporter
rm -f /tmp/node_exporter-1.3.1.linux-amd64.tar.gz
rm -rf /tmp/node_exporter-1.3.1.linux-amd64

cat  << EOF | sudo tee -a /etc/systemd/system/node_exporter.service 
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service
sudo systemctl restart grafana-server
sudo systemctl restart prometheus


#-------------------------------------------------------Fin installation node_exporter---------------------------------------------------------------------------------------

#--------------------------------------------------------Installation Alertmanager-----------------------------------------------------------------------
sudo useradd -M -r -s /bin/false ${USER_ALERTMANAGER}
sudo mkdir ${PATH_CONFIG_ALERTMANAGER}
sudo chown ${USER_ALERTMANAGER}:${GROUP_ALERTMANAGER} ${PATH_CONFIG_ALERTMANAGER}
cd /tmp || exit 6
wget ${URL_GITHUB_ALERTMANAGER_TAR_GZ}
wget -O - -q ${URL_GITHUB_ALERTMANAGER_SHASUM}  | grep linux-amd64 | shasum -c -
tar xzf alertmanager-0.23.0.linux-amd64.tar.gz
sudo cp alertmanager-0.23.0.linux-amd64/{alertmanager,amtool} ${PATH_ALERTMANAGER}
sudo chown alertmanager:alertmanager /usr/local/bin/{alertmanager,amtool}
rm -f /tmp/alertmanager-0.23.0.linux-amd64.tar.gz
rm -rf /tmp/alertmanager-0.23.0.linux-amd64

#in /etc/alertmanager/alertmanager.yml
cat << EOF | sudo tee -a ${PATH_CONFIG_ALERTMANAGER}/${CONFIG_FILE_ALERTMANAGER}
global:
  smtp_from: 'AlertManager <alertmanager@example.com>'
  smtp_smarthost: 'smtp.example.com:587'
  smtp_hello: 'alertmanager'
  smtp_auth_username: ''
  smtp_auth_password: 'password'
  smtp_require_tls: true
 
route:
  group_by: ['instance', 'alert']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
  receiver: myteam
 
receivers:
  - name: 'myteam'
    email_configs:
      - to: 'user@example.com'
EOF

sudo chown ${USER_ALERTMANAGER}:${GROUP_ALERTMANAGER} ${PATH_CONFIG_ALERTMANAGER}/${CONFIG_FILE_ALERTMANAGER}

cat << EOF | sudo tee -a /etc/systemd/system/alertmanager.service
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target
 
[Service]
User=alertmanager
Group=alertmanager
Type=simple
WorkingDirectory=/etc/alertmanager/
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --web.external-url http://<ip>:9093
 
[Install]
WantedBy=multi-user.target
EOF

	
sudo mkdir ${PATH_RULE_PROMETHEUS}
sudo chown ${USER_PROMETHEUS}:${GROUP_PROMETHEUS} ${PATH_RULE_PROMETHEUS}

#Let’s create our first alert by creating the file /etc/prometheus/rules/alert-rules.yml with the following content:
cat << EOF | sudo tee -a ${PATH_RULE_PROMETHEUS}/${RULE_FILE_PROMETHEUS}
groups:
- name: alert-rules
  rules:
  - alert: ExporterDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      description: 'Metrics exporter service for {{ $labels.job }} running on {{ $labels.instance }} has been down for more than 5 minutes.'
      summary: 'Exporter down (instance {{ $labels.instance }})'
EOF

sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl restart prometheus
sudo systemctl restart grafana-server

#You should be able to see the alert rule in the prometheus web interface now too, by going to the Alerts section.
#Now the easiest way for us to check if this alert actually fires, and we get our email notification, is to stop the node exporter service:
#sudo systemctl status node_exporter
#sudo systemctl stop node_exporter
#sudo systemctl start node_exporter


#--------------------------------------------------------Fin Installation Alertmanager-----------------------------------------------------------------------


#---------------------------------------------installation Karma-----------------------------------------------------------------------------------------------------------
sudo useradd -M -r -s /bin/false ${USER_KARMA}
sudo mkdir ${PATH_CONFIG_KARMA}
sudo chown ${USER_KARMA}:${GROUP_KARMA} 
sudo chmod 640 ${PATH_CONFIG_KARMA}/${CONFIG_FILE_KARMA}
cd /tmp || exit 7
wget ${URL_GITHUB_KARMA_TAR_GZ}
wget -O - -q ${URL_GITHUB_KARMA_SHASUM} | grep linux-amd64 | shasum -c -
tar xzf karma-linux-amd64.tar.gz
sudo mv karma-linux-amd64 ${PATH_KARMA}/karma
rm -f karma-linux-amd64.tar.gz

cat << EOF | sudo tee -a ${PATH_CONFIG_KARMA}/${CONFIG_FILE_KARMA}
alertmanager:
  interval: 1m
  servers:
    - name: alertmanager
      uri: http://localhost:9093
      timeout: 20s
authentication:
  basicAuth:
    users:
      - username: <username>
        password: <password>
listen:
  address: 0.0.0.0
  port: 8092
  prefix: /karma/
EOF

cat << EOF | sudo tee -a /etc/systemd/system/karma.service
[Unit]
Description=Karma Alertmanager dashboard
Wants=network-online.target
After=network-online.target
After=alertmanager.service
 
[Service]
User=karma
Group=karma
Type=simple
WorkingDirectory=/etc/karma/
ExecStart=/usr/local/bin/karma \
    --config.file=/etc/karma/karma.yml
 
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start karma
sudo systemctl enable karma
sudo systemctl restart alertmanager
sudo systemctl restart prometheus
sudo systemctl restart grafana-server
#---------------------------------------------Fin installation Karma--------------------------------------------------------
