# Build Prometheus + promtool from the prometheus/ git submodule (no upstream release tarball).
# Hermetic Konflux: Hermeto prefetches Go modules to /cachi2.
FROM registry.access.redhat.com/ubi9/go-toolset:9.8-1791182877 AS build
USER 0
WORKDIR /opt/app-root/src/prometheus
COPY prometheus/ .

# IQE does not use Docker/Swarm service discovery. Dropping the moby plugin removes
# github.com/docker/{docker,distribution} from the binary so Syft does not emit
# unattributed pkg:golang/... entries for them (Hermeto PURLs use ?type=module and
# do not merge with Syft's module PURLs — would fail hermeto_attribution_required
# after 2027-01-15).
RUN sed -i '/discovery\/moby/d' plugins.yml \
  && sed -i '/Register moby plugin\./,+1d' plugins/plugins.go

RUN mkdir -p /opt/prometheus \
  && if [ -f /cachi2/cachi2.env ]; then . /cachi2/cachi2.env; fi \
  && CGO_ENABLED=0 go build -o /opt/prometheus/prometheus ./cmd/prometheus \
  && CGO_ENABLED=0 go build -o /opt/prometheus/promtool ./cmd/promtool \
  && objcopy --remove-section=.go.buildinfo /opt/prometheus/prometheus \
  && objcopy --remove-section=.go.buildinfo /opt/prometheus/promtool
# Strip Go buildinfo so Syft does not emit synthetic pkg:golang/stdlib@<toolchain>
# (Hermeto lists stdlib as unversioned ?type=package entries; Conforma only
# auto-exempts empty-version golang PURLs). Module inventory remains in the
# Hermeto gomod SBOM from prefetch. go-toolset already provides objcopy.

# Runtime: Python base for the IQE importer (Flask) without microdnf network installs.
FROM registry.access.redhat.com/ubi9/python-312:1791160037
USER 0
COPY --from=build /opt/prometheus /opt/prometheus
COPY config/prometheus.yml /opt/prometheus/prometheus.yml
COPY utils/* /opt/prometheus/utils/
COPY start.sh /opt/prometheus/start.sh
COPY requirements.txt /tmp/requirements.txt

LABEL maintainer="Red Hat, Inc."
LABEL version="ubi9"
LABEL com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

# Hermetic: source Hermeto env so pip uses the prefetched offline index.
# Local: install from PyPI using the same pinned requirements.
RUN if [ -f /cachi2/cachi2.env ]; then \
      . /cachi2/cachi2.env && pip3 install --no-cache-dir -r /tmp/requirements.txt; \
    else \
      pip3 install --no-cache-dir -r /tmp/requirements.txt; \
    fi \
  && rm -f /tmp/requirements.txt

WORKDIR /opt/prometheus

RUN mkdir -p /var/lib/prometheus /opt/prometheus/data \
  && chmod +x /opt/prometheus/utils/prometheus-importer.py \
  && chmod +x /opt/prometheus/start.sh

EXPOSE 8000 9000

ENTRYPOINT ["/opt/prometheus/start.sh"]
