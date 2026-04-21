#!/bin/sh
set -eu

echo '--- INICIALIZANDO ---'

if [ ! -f /etc/suricata/suricata.yaml ]; then
  cp -r /etc/suricata.dist/* /etc/suricata/ 2>/dev/null || true
fi

if [ -n "${SURICATA_INTERFACES:-}" ]; then
  INTERFACES="$SURICATA_INTERFACES"
else
  EXT_IF="$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)"
  if [ -z "${EXT_IF}" ]; then
    EXT_IF="$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | head -n1)"
  fi

  DOCKER_IFS=""
  if ip link show docker0 >/dev/null 2>&1; then
    DOCKER_IFS="docker0"
  fi

  BR_IFS="$(ip -o link show | awk -F': ' '{print $2}' | grep '^br-' || true)"

  INTERFACES="$EXT_IF"
  [ -n "$DOCKER_IFS" ] && INTERFACES="$INTERFACES $DOCKER_IFS"
  [ -n "$BR_IFS" ] && INTERFACES="$INTERFACES $BR_IFS"
fi

suricata-update update-sources || true

suricata-update --no-reload || true

echo "Iniciando Suricata en interfaces: $INTERFACES"

IF_ARGS=""
for iface in $INTERFACES; do
  [ -n "$iface" ] || continue
  IF_ARGS="$IF_ARGS -i $iface"
done

exec /usr/bin/suricata -c /etc/suricata/suricata.yaml $IF_ARGS
