#!/bin/sh
set -eu

echo "Esperando a que Elasticsearch esté listo..."
until curl -s -u "elastic:${ELASTIC_PASSWORD}" http://elasticsearch:9200/_cluster/health | grep -q '"status"'; do
  echo "Elasticsearch no está listo todavía, esperando 5s..."
  sleep 5
done

echo "Configurando contraseña de kibana_system..."
response=$(curl -s -o /tmp/resp.txt -w "%{http_code}" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -X POST "http://elasticsearch:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"${KIBANA_SYSTEM_PASSWORD}\"}")

if [ "$response" = "200" ]; then
  echo "kibana_system configurado correctamente."
else
  echo "Error configurando kibana_system (HTTP $response):"
  cat /tmp/resp.txt
  exit 1
fi