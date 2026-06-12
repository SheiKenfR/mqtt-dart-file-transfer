#!/usr/bin/env bash
# Generates lib/core/mqtt/mqtt_host.g.dart with the local network IP.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT="$PROJECT_DIR/lib/core/mqtt/mqtt_host.g.dart"

HOST_IP=$(hostname -I | awk '{print $1}')

if [ -z "$HOST_IP" ]; then
  echo "ERROR: could not detect local IP" >&2
  exit 1
fi

cat > "$OUTPUT" <<EOF
// GENERATED — do not edit. Run scripts/detect_host_ip.sh to regenerate.
const String mqttHostIp = '$HOST_IP';
EOF

echo "MQTT_HOST=$HOST_IP -> $OUTPUT"
