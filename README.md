# Prometheus

This repo is used for deploying prometheus to EE for IQE testing via Clowder.

Customized to run on port 8000.

Prometheus **v2.49.1** is included as a git submodule at `prometheus/` and built
into the image (Hermeto `gomod` + `pip` for hermetic Konflux builds).
`.gitmodules` pins `branch = v2.49.1`; MintMaker/Renovate is told to ignore
digest bumps of this submodule and all Go module updates (`renovate.json`) so
Konflux does not open tip-of-main / gomod PRs that break the hermetic build.

The Docker/Swarm (`moby`) service-discovery plugin is disabled at image build
time — IQE does not use it, and it pulls in `docker/*` modules that Syft cannot
match to Hermeto PURLs.

Go buildinfo is stripped from the binaries so Syft does not emit a versioned
`pkg:golang/stdlib@…` that Hermeto cannot attribute (module inventory stays in
the Hermeto SBOM from prefetch).

```bash
git submodule update --init --recursive
```
