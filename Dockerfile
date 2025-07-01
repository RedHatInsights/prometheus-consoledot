FROM registry.access.redhat.com/ubi9/ubi:9.6-1751287003 AS build
USER 0
ARG PROMETHEUS_VERSION=2.49.1
ARG TARGET_ARCH="amd64"

# Download and extract Prometheus
RUN mkdir -p /opt/prometheus \
  && curl -L "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${TARGET_ARCH}.tar.gz" -o prometheus-bin.tar.gz \
  && tar -xzf prometheus-bin.tar.gz -C /opt/prometheus \
  && mv /opt/prometheus/prometheus-${PROMETHEUS_VERSION}.linux-${TARGET_ARCH}/* /opt/prometheus/

# Runtime
FROM registry.access.redhat.com/ubi9/openjdk-17
COPY --from=build /opt/prometheus /opt/prometheus
COPY config/prometheus.yml /opt/prometheus/prometheus.yml
LABEL maintainer="Red Hat, Inc."
LABEL version="ubi9"
USER 0

WORKDIR /opt/prometheus

# Create the data directory for Prometheus query logs
RUN mkdir -p /var/lib/prometheus && \
    mkdir -p /opt/prometheus/data

EXPOSE 8000

ENTRYPOINT ["/opt/prometheus/prometheus", \
            "--storage.tsdb.path=/var/lib/prometheus", \
            "--config.file=/opt/prometheus/prometheus.yml", \
            "--web.listen-address=:8000"]