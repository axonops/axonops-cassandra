# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow `.github/workflows/update-version.yml` (`workflow_dispatch`) replacing the Bitbucket `update-version` custom pipeline: loops Cassandra versions `4.1 4.0 5.0`, runs `update-version.sh`, and commits/pushes `[skip ci] Updating upstream versions` to the default branch.
- GitHub Actions workflow `.github/workflows/build-images.yml` (`workflow_dispatch`) replacing the Bitbucket `build-images` and `Publish images` pipelines: a version × arch matrix (`4.1/4.0/5.0` × `amd64/arm64`) builds and pushes `${VER}-${ARCH}` images, then a final job assembles and pushes the multi-arch manifests `4.1/4.0/5.0`. arm64 legs run on GitHub-hosted arm64 runners (`ubuntu-24.04-arm`), removing the self-hosted `linux.arm64` runner and custom arm64 cloud-sdk image.
- Full-version image tags: published manifests are now tagged `<cassandra_version>-<axon_agent_version>-<repo_tag>` (e.g. `5.0.8-2.1.0-1.0.0`) alongside the moving `<minor>` alias (e.g. `5.0`). The Cassandra patch version and axon-agent version are read from the built image; the repo tag is a required `repo_tag` `workflow_dispatch` input on `build-images.yml`.
- Process supervision and automatic restart for the `axon-agent` sidecar in `axonops-entrypoint.sh`: if the agent exits it is restarted automatically, with crash-loop protection (>5 restarts in 60s triggers a 30s backoff) and death/restart events logged to stdout and `/var/log/axonops/axon-agent.log`. Previously a dead agent was never detected or restarted for the life of the container.
- `com.axonops.agent.version` image label, stamped by `build-image.sh` with the axon-agent version apt actually resolved during the build. Readable with `docker inspect` without running the image.
- `CHANGELOG.md` (this file).

### Changed
- `Dockerfile-template` now installs the AxonOps apt repo signing key into `/usr/share/keyrings/axonops.gpg` (via `gpg --dearmor`) and references it with `signed-by=` in the sources list, replacing the deprecated `apt-key add`. Adds `ca-certificates` to the install set.
- Repository migrated from Bitbucket (`git@bitbucket.org:digitalisio/dk-axonops-cassandra.git`) to GitHub (`git@github.com:axonops/axonops-cassandra.git`); `README.md` updated with the new clone URL and CI documentation.
- Image registry changed from Google Artifact Registry (`europe-docker.pkg.dev/axonops-public/axonops-docker/cassandra`) to the GitHub Container Registry (`ghcr.io/axonops/axonops-cassandra`). Publishing authenticates with the built-in `GITHUB_TOKEN` (`packages: write`) via `docker login --password-stdin`; the `GCLOUD_API_KEYFILE` secret is no longer required. The `axonops-cassandra` package name avoids collision with the pre-existing `ghcr.io/axonops/cassandra` package owned by `axonops-workbench-containers`.

### Deprecated
- `bitbucket-pipelines.yml` — retained for reference with a deprecation header; CI now runs on GitHub Actions.
