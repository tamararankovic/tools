FROM grafana/grafana:latest

COPY ./tools/grafana/dashboard.yaml /etc/grafana/provisioning/dashboards/main.yaml
COPY ./tools/grafana/dashboards /var/lib/grafana/dashboards
COPY ./tools/grafana/datasources.yaml /etc/grafana/provisioning/datasources/main.yaml