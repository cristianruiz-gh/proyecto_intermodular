#!/bin/bash
set -euo pipefail

echo "Creando configuración de Telegraf..."
cat <<EOF > /tmp/telegraf.conf
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = "telegraf-node"
  omit_hostname = false

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUXDB_TOKEN}"
  organization = "${ADMIN_USER}"
  bucket = "telegraf"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.mem]]
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
EOF

echo "Esperando a InfluxDB..."
sleep 15

exec telegraf --config /tmp/telegraf.conf
