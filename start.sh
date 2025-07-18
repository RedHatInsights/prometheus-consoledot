#!/bin/bash
# Run prometheus in background
/opt/prometheus/prometheus \
    --storage.tsdb.path=/var/lib/prometheus \
    --config.file=/opt/prometheus/prometheus.yml \
    --web.listen-address=:8000 \
    --web.enable-admin-api &

# Wait a couple of seconds
sleep 2

# Start promethes importer API
echo "Starting Prometheus Importer on port 9000..."
python3 /opt/prometheus/utils/prometheus-importer.py 