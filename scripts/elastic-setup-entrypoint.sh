#!/bin/sh
set -eu

SLEEP_SECONDS="${SLEEP_SECONDS:-5}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-60}"

echo "Esperando a que Elasticsearch esté listo..."
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  http_code=$(curl -s -o /tmp/es-health.txt -w "%{http_code}" \
    -u "elastic:${ELASTIC_PASSWORD}" \
    "http://elasticsearch:9200/_cluster/health")

  case "$http_code" in
    200)
      if grep -Eq '"status"\s*:\s*"(green|yellow|red)"' /tmp/es-health.txt; then
        break
      fi
      ;;
    401)
      echo "ERROR: Credenciales inválidas para 'elastic'."
      echo "Esto suele ocurrir cuando mantienes el volumen de datos y la password real no coincide con ELASTIC_PASSWORD."
      echo "Respuesta de Elasticsearch:"
      cat /tmp/es-health.txt
      exit 1
      ;;
  esac

  echo "No listo (HTTP $http_code), esperando ${SLEEP_SECONDS}s... (intento ${attempt}/${MAX_ATTEMPTS})"
  sleep "$SLEEP_SECONDS"
  done

if [ "$attempt" -gt "$MAX_ATTEMPTS" ]; then
  echo "ERROR: Elasticsearch no estuvo listo tras ${MAX_ATTEMPTS} intentos."
  cat /tmp/es-health.txt || true
  exit 1
fi

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