#!/bin/sh
set -eu

echo '--- INICIALIZANDO ---'

if [ ! -f /etc/suricata/suricata.yaml ]; then
  cp -r /etc/suricata.dist/* /etc/suricata/ 2>/dev/null || true
fi

INTERFACE="$(ip route show default | awk '/default/ {print $5}')"
if [ -z "$INTERFACE" ]; then
  INTERFACE="$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1)"
fi

# Actualizar fuentes antes de reglas
suricata-update update-sources || true

# Actualizar reglas (evitar que suricata-update intente recargar por socket durante el arranque)
suricata-update --no-reload || true

exec /usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE"