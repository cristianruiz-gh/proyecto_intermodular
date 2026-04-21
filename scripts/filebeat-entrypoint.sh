#!/bin/bash
set -euo pipefail

cat > /usr/share/filebeat/filebeat.yml <<EOF
filebeat.inputs:
  - type: filestream
    id: docker-containers
    paths:
      - /var/lib/docker/containers/*/*.log
    parsers:
      - container:
          stream: all
          format: docker
    processors:
      - add_docker_metadata:
          host: 'unix:///var/run/docker.sock'

  - type: filestream
    id: varlog
    paths:
      - /var/log/*.log
    prospector.scanner.check_interval: 10s

# Habilitamos el módulo de Suricata específicamente
filebeat.modules:
  - module: suricata
    eve:
      enabled: true
      var.paths: ["/var/log/suricata/eve.json"]

output.elasticsearch:
  hosts: ['http://elasticsearch:9200']
  username: '\${ELASTICSEARCH_USERNAME}'
  password: '\${ELASTICSEARCH_PASSWORD}'

setup.kibana:
  host: 'http://kibana:5601'
  username: '\${ELASTICSEARCH_USERNAME}'
  password: '\${ELASTICSEARCH_PASSWORD}'

# Configuración para cargar dashboards automáticamente
setup.dashboards.enabled: true

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_docker_metadata: ~
EOF

chown root:root /usr/share/filebeat/filebeat.yml
chmod 644 /usr/share/filebeat/filebeat.yml

filebeat setup -e || echo "Setup inicial fallido, reintentando en segundo plano..."

exec filebeat -e