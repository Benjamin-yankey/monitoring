#!/bin/bash
set -e

# Update system
yum update -y
yum install -y docker git wget curl

# Start Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Create directories for Grafana
mkdir -p /var/lib/grafana /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards
chmod -R 777 /var/lib/grafana

# Create Prometheus datasource configuration
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Create dashboard provisioning configuration
cat > /etc/grafana/provisioning/dashboards/dashboards.yml <<'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Run Grafana in Docker
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_INSTALL_PLUGINS=grafana-piechart-panel \
  -e GF_USERS_ALLOW_SIGN_UP=false \
  -v /var/lib/grafana:/var/lib/grafana \
  -v /etc/grafana/provisioning:/etc/grafana/provisioning:ro \
  grafana/grafana:latest

# Log completion
echo "Grafana setup completed" >> /var/log/grafana-setup.log
