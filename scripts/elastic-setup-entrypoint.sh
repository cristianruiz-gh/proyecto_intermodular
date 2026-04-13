#!/bin/sh
set -eu

echo "Esperando a que Elasticsearch esté listo..."

# Nota importante:
# - Un 401 suele venir con un JSON que incluye "status":401, lo que provoca falsos positivos
#   si sólo buscamos la cadena "status".
# - Aquí validamos HTTP 200 y un status de cluster válido (green/yellow/red).

SLEEP_SECONDS="${SLEEP_SECONDS:-5}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-60}" # 60 * 5s = ~5 min

attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  http_code=$(curl -s -o /tmp/es-health.txt -w "%{http_code}" \
    -u "elastic:${ELASTIC_PASSWORD}" \
    "http://elasticsearch:9200/_cluster/health")

  if [ "$http_code" = "200" ] && grep -Eq '"status"\s*:\s*"(green|yellow|red)"' /tmp/es-health.txt; then
    break
  fi

  if [ "$http_code" = "401" ]; then
    echo "ERROR: Elasticsearch responde 401 (credenciales inválidas para el usuario 'elastic')."
    echo "Esto suele ocurrir cuando mantienes el volumen de datos y la password real no coincide con ELASTIC_PASSWORD."
    echo "Solución: resetea la password del usuario 'elastic' dentro del contenedor y actualiza tu .env, o elimina el volumen de Elasticsearch."
    echo "Respuesta de Elasticsearch:"
    cat /tmp/es-health.txt
    exit 1
  fi

  echo "Elasticsearch no está listo todavía (HTTP $http_code), esperando ${SLEEP_SECONDS}s... (intento ${attempt}/${MAX_ATTEMPTS})"
  sleep "$SLEEP_SECONDS"
  attempt=$((attempt + 1))
done

if [ "$attempt" -gt "$MAX_ATTEMPTS" ]; then
  echo "ERROR: Elasticsearch no estuvo listo tras ${MAX_ATTEMPTS} intentos. Última respuesta:"
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
