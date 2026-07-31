<p align="center">
  <a href="https://axonops.com">
    <img src="https://digitalis-marketplace-assets.s3.us-east-1.amazonaws.com/AxonopsDigitalMaster_AxonopsFullLogoBlue.jpg" alt="AxonOps" width="300">
  </a>
</p>

# AxonOps Cassandra Docker image

Apache Cassandra container image with the [AxonOps](https://axonops.com) monitoring agent baked in. Built on the [official Cassandra image](https://hub.docker.com/_/cassandra) for versions 4.0, 4.1 and 5.0 on both `amd64` and `arm64`, so a single tag gives you Cassandra plus the AxonOps agent with no extra setup.

Used by the Docker Compose demo/development cluster: <https://github.com/axonops/axonops-cassandra-dev-cluster>.

> **NOTE:** This is not the image AxonOps uses for automated provisioning of managed clusters.

## Quick start

Pull an image and run a single node. The agent starts automatically alongside Cassandra:

```bash
docker run -d --name cassandra \
  -p 9042:9042 \
  -v "$PWD/axon-agent.yml:/etc/axonops/axon-agent.yml:ro" \
  ghcr.io/axonops/axonops-cassandra:5.0
```

`axon-agent.yml` is your AxonOps agent config (SaaS organisation + key, or a self-hosted server endpoint). Without a valid config the agent runs but cannot report to AxonOps. See the [AxonOps agent docs](https://docs.axonops.com/).

Images are published to the GitHub Container Registry:

```
ghcr.io/axonops/axonops-cassandra:<cassandra_version>-<axon_agent_version>-<repo_tag>   # e.g. 5.0.8-2.1.0-1.0.0
ghcr.io/axonops/axonops-cassandra:<minor>                                              # e.g. 5.0 (moving alias)
```

## Usage examples

### Three-node cluster with Docker Compose

```yaml
services:
  cassandra-1:
    image: ghcr.io/axonops/axonops-cassandra:5.0
    environment:
      CASSANDRA_CLUSTER_NAME: demo
      CASSANDRA_SEEDS: cassandra-1
    volumes:
      - ./axon-agent.yml:/etc/axonops/axon-agent.yml:ro
    ports:
      - "9042:9042"

  cassandra-2:
    image: ghcr.io/axonops/axonops-cassandra:5.0
    environment:
      CASSANDRA_CLUSTER_NAME: demo
      CASSANDRA_SEEDS: cassandra-1
    volumes:
      - ./axon-agent.yml:/etc/axonops/axon-agent.yml:ro

  cassandra-3:
    image: ghcr.io/axonops/axonops-cassandra:5.0
    environment:
      CASSANDRA_CLUSTER_NAME: demo
      CASSANDRA_SEEDS: cassandra-1
    volumes:
      - ./axon-agent.yml:/etc/axonops/axon-agent.yml:ro
```

### Custom native transport port

```bash
docker run -d --name cassandra \
  -e CASSANDRA_NATIVE_TRANSPORT_PORT=9142 \
  -p 9142:9142 \
  -v "$PWD/axon-agent.yml:/etc/axonops/axon-agent.yml:ro" \
  ghcr.io/axonops/axonops-cassandra:4.1
```

### Read the baked-in agent version without running the image

```bash
docker inspect ghcr.io/axonops/axonops-cassandra:5.0 \
  --format '{{index .Config.Labels "com.axonops.agent.version"}}'
```

## Configuration

Image-specific settings. All [official Cassandra image](https://hub.docker.com/_/cassandra) variables (`CASSANDRA_CLUSTER_NAME`, `CASSANDRA_SEEDS`, `CASSANDRA_DC`, …) also apply.

| Variable | Type | Default | Example | Description |
|----------|------|---------|---------|-------------|
| `CASSANDRA_NATIVE_TRANSPORT_PORT` | int | `9042` (image default) | `9142` | Overrides `native_transport_port` in `cassandra.yaml` at startup. |
| `AXON_AGENT_ARGS` | string | *(empty)* | `-log-level debug` | Extra arguments passed to the `axon-agent` process. |

| Mount / path | Purpose |
|--------------|---------|
| `/etc/axonops/axon-agent.yml` | AxonOps agent configuration (organisation, key, server endpoint). Mount your own to connect the agent to AxonOps. |
| `/var/log/axonops/axon-agent.log` | Agent log file (also mirrored to stdout). |

The agent is supervised: if it exits it is restarted automatically, with crash-loop protection (>5 restarts in 60s triggers a 30s backoff). The container lifecycle stays tied to Cassandra, not the agent.

## Building

This repository lives on GitHub under the **axonops** organisation (migrated from Bitbucket `digitalisio`).

```bash
git clone git@github.com:axonops/axonops-cassandra.git
```

CI runs on GitHub Actions:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [`update-version.yml`](.github/workflows/update-version.yml) | `workflow_dispatch` | Refresh pinned upstream Cassandra versions (4.1, 4.0, 5.0) and commit the result. |
| [`build-images.yml`](.github/workflows/build-images.yml) | push `v*` tag / `workflow_dispatch` / `workflow_call` | Build + push `amd64` and `arm64` images per version, then publish multi-arch manifests. |
| [`daily-refresh.yml`](.github/workflows/daily-refresh.yml) | daily at 03:00 UTC / `workflow_dispatch` | Rebuild and republish when a new upstream Cassandra release or axon-agent package appears. |

The `<repo_tag>` (third tag component) is taken from the pushed tag name with the leading `v` stripped (`v1.0.0` → `1.0.0`), or from the `repo_tag` input when dispatched manually or called by `daily-refresh.yml`.

To build locally:

```bash
export IMGBASE=ghcr.io/axonops/axonops-cassandra
./build-image.sh 5.0 amd64
```

### Automatic rebuilds

`daily-refresh.yml` runs [`check-updates.sh`](check-updates.sh), which compares the upstream versions against the versions baked into the currently published `<minor>` manifests:

| Component | Upstream source |
|-----------|-----------------|
| Cassandra | `ENV CASSANDRA_VERSION` in the [docker-library/cassandra](https://github.com/docker-library/cassandra) Dockerfile for that minor version |
| axon-agent | Highest `axon-cassandra<minor>-agent[-jdk17]` version in the [AxonOps apt index](https://packages.axonops.com/apt) |

If anything drifted, every version is rebuilt (so one repo tag consistently describes all published manifests), the patch component of the newest `v*` tag is bumped, and that tag is created on the built commit.

Run the check locally — it only reads, never builds:

```bash
./check-updates.sh
# 4.0 current upstream=4.0.20/1.0.18 published=4.0.20/1.0.18
# ...
# STALE_VERSIONS=
```

## Contact

Maintained by [AxonOps](https://axonops.com). Support: [axonops.com/contact](https://axonops.com/contact).
