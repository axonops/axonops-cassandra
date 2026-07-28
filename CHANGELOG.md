# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow `.github/workflows/update-version.yml` (`workflow_dispatch`) replacing the Bitbucket `update-version` custom pipeline: loops Cassandra versions `4.1 4.0 5.0`, runs `update-version.sh`, and commits/pushes `[skip ci] Updating upstream versions` to the default branch.
- GitHub Actions workflow `.github/workflows/build-images.yml` (`workflow_dispatch`) replacing the Bitbucket `build-images` and `Publish images` pipelines: a version × arch matrix (`4.1/4.0/5.0` × `amd64/arm64`) builds and pushes `${VER}-${ARCH}` images, then a final job assembles and pushes the multi-arch manifests `4.1/4.0/5.0`. arm64 legs run on GitHub-hosted arm64 runners (`ubuntu-24.04-arm`), removing the self-hosted `linux.arm64` runner and custom arm64 cloud-sdk image.
- Process supervision and automatic restart for the `axon-agent` sidecar in `axonops-entrypoint.sh`: if the agent exits it is restarted automatically, with crash-loop protection (>5 restarts in 60s triggers a 30s backoff) and death/restart events logged to stdout and `/var/log/axonops/axon-agent.log`. Previously a dead agent was never detected or restarted for the life of the container.
- `CHANGELOG.md` (this file).

### Changed
- `Dockerfile-template` now installs the AxonOps apt repo signing key into `/usr/share/keyrings/axonops.gpg` (via `gpg --dearmor`) and references it with `signed-by=` in the sources list, replacing the deprecated `apt-key add`. Adds `ca-certificates` to the install set.
- Repository migrated from Bitbucket (`git@bitbucket.org:digitalisio/dk-axonops-cassandra.git`) to GitHub (`git@github.com:axonops/axonops-cassandra.git`); `README.md` updated with the new clone URL and CI documentation.
- Google Artifact Registry authentication now decodes the base64 `GCLOUD_API_KEYFILE` secret to a file and logs in via `--password-stdin`, keeping the key out of command lines and logs.

### Deprecated
- `bitbucket-pipelines.yml` — retained for reference with a deprecation header; CI now runs on GitHub Actions.
