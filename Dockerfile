FROM registry.access.redhat.com/ubi9/ubi:9.6-1749542372 AS build
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
COPY utils/* /opt/prometheus/utils/
COPY start.sh /opt/prometheus/start.sh

LABEL maintainer="Red Hat, Inc."
LABEL version="ubi9"
USER 0

# Install python3
RUN microdnf install -y \
    python3 \
    python3-pip \
    gcc \
    python3-devel
RUN pip3 install flask

WORKDIR /opt/prometheus

# Create directories and set permissions
RUN mkdir -p /var/lib/prometheus && \
    mkdir -p /opt/prometheus/data && \
    chmod +x /opt/prometheus/utils/prometheus-importer.py && \
    chmod +x /opt/prometheus/start.sh

# Expose ports: 8000 for Prometheus, 9000 for Importer
EXPOSE 8000 9000

ENTRYPOINT ["/opt/prometheus/start.sh"] 