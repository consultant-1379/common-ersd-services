FROM armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/grafana/grafana:5.4.3

COPY ./datasource-prometheus.yaml /etc/grafana/provisioning/datasources/
COPY ./dashboard-provider.yaml /etc/grafana/provisioning/dashboards/
COPY ./local-dashboards/docker-metrics-dashboard.json /var/lib/grafana/dashboards/common/
COPY ./local-dashboards/mongo-metrics-dashboard.json /var/lib/grafana/dashboards/common/
COPY ./local-dashboards/prometheus-metrics-dashboard.json /var/lib/grafana/dashboards/common/

COPY ./local-dashboards/express-ktt-metrics-dashboard.json /var/lib/grafana/dashboards/ktt/
COPY ./local-dashboards/express-emt-metrics-dashboard.json /var/lib/grafana/dashboards/emt/
COPY ./local-dashboards/express-amt-metrics-dashboard.json /var/lib/grafana/dashboards/amt/

ARG GRAFANA_VIEWER_PASSWORD
ENV GRAFANA_VIEWER_PASSWORD=${GRAFANA_VIEWER_PASSWORD}
ARG GRAFANA_ADMIN_PASSWORD
ENV GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}

COPY init.sh .
USER root
RUN sed -i.bak 's/\r$//' ./init.sh
RUN sh ./init.sh
