<p align="center">
  <a href="https://axonops.com"><img src="https://axonops.com/wp-content/uploads/axonops-logo.png" alt="AxonOps" width="360"/></a>
</p>

# AxonOps Cassandra Docker image

A Cassandra container image based on the [official Cassandra Docker image](https://hub.docker.com/_/cassandra) with the [AxonOps](https://axonops.com) agent added in.

Used by the Docker Compose demo/development cluster, see https://github.com/axonops/axonops-cassandra-dev-cluster.

> **NOTE:** This is not the image used for automated provisioning in AxonOps.

## Home

This repository now lives on GitHub under the **axonops** organisation. It was migrated from Bitbucket (`digitalisio` workspace).

```bash
git clone git@github.com:axonops/axonops-cassandra.git
```

## Building

CI runs on GitHub Actions (manual `workflow_dispatch` triggers):

| Workflow | Purpose |
|----------|---------|
| [`update-version.yml`](.github/workflows/update-version.yml) | Refresh pinned upstream Cassandra versions (4.1, 4.0, 5.0) and commit the result. |
| [`build-images.yml`](.github/workflows/build-images.yml) | Build + push `amd64` and `arm64` images per version, then publish multi-arch manifests. |

Images are published to the GitHub Container Registry: `ghcr.io/axonops/cassandra`.

Each build publishes a multi-arch manifest tagged with the full version triple, plus a moving minor alias:

```
ghcr.io/axonops/cassandra:<cassandra_version>-<axon_agent_version>-<repo_tag>   # e.g. 5.0.8-2.1.0-1.0.0
ghcr.io/axonops/cassandra:<minor>                                              # e.g. 5.0 (moving alias)
```

The `<repo_tag>` (third component) is supplied as the `repo_tag` input when dispatching `build-images.yml`.

To build locally:

```bash
export IMGBASE=ghcr.io/axonops/cassandra
./build-image.sh 5.0 amd64
```

## Contact

Maintained by [AxonOps](https://axonops.com). Support: [axonops.com/contact](https://axonops.com/contact).
