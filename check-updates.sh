#!/bin/sh
# Compare the upstream Cassandra and axon-agent versions against what is
# currently published in the registry, and report which Cassandra minor
# versions are out of date.
#
# Upstream sources (both readable without building anything):
#   Cassandra  - the docker-library/cassandra Dockerfile for the minor version
#   axon-agent - the AxonOps apt repository package index
#
# Published state is read from the moving "<minor>" manifest already in the
# registry: CASSANDRA_VERSION from the image environment and the
# com.axonops.agent.version label stamped by build-image.sh.
#
# Environment:
#   IMGBASE  - image repository (default ghcr.io/axonops/axonops-cassandra)
#   VERSIONS - space separated Cassandra minor versions (default "4.0 4.1 5.0")
#
# Output: one human readable line per version, then a final machine readable
# line "STALE_VERSIONS=<space separated list>" (empty when everything is
# current). Always exits 0 unless a version could not be resolved at all.
set -e

IMGBASE=${IMGBASE:-ghcr.io/axonops/axonops-cassandra}
VERSIONS=${VERSIONS:-"4.0 4.1 5.0"}
APT_DIST_URL=${APT_DIST_URL:-https://packages.axonops.com/apt/dists/axonops-apt/main}
CASSANDRA_REPO_URL=${CASSANDRA_REPO_URL:-https://raw.githubusercontent.com/docker-library/cassandra/master}

# Cache the apt indexes; they are the same files for every version. The agent
# packages are split across the per-architecture indexes and the "all" index
# (recent releases are architecture independent), so all three are merged.
APT_INDEX=$(mktemp)
trap 'rm -f "$APT_INDEX"' EXIT
for arch in all amd64 arm64; do
  curl -fsSL "${APT_DIST_URL}/binary-${arch}/Packages" >>"$APT_INDEX"
done

# Strip a Debian epoch and revision, keeping the upstream version, so that the
# apt version (e.g. 1:2.1.0-1) compares against the image label (2.1.0).
normalise_version() {
  echo "$1" | sed 's/^[0-9]*://; s/-[^-]*$//'
}

# The package name mirrors the logic in Dockerfile-template: Cassandra 5.0 uses
# the JDK 17 build of the agent, everything else the default package.
agent_package() {
  if [ "$1" = "5.0" ]; then
    echo "axon-cassandra${1}-agent-jdk17"
  else
    echo "axon-cassandra${1}-agent"
  fi
}

# Highest available version of the given package in the apt index.
upstream_agent_version() {
  awk -v pkg="$1" '
    $1 == "Package:" { match_pkg = ($2 == pkg) }
    match_pkg && $1 == "Version:" { print $2 }
  ' "$APT_INDEX" | while read -r v; do normalise_version "$v"; done | sort -V | tail -1
}

# CASSANDRA_VERSION as pinned by the official image for this minor version.
# Handles both "ENV CASSANDRA_VERSION 5.0.8" and "ENV CASSANDRA_VERSION=5.0.8".
upstream_cassandra_version() {
  curl -fsSL "${CASSANDRA_REPO_URL}/$1/Dockerfile" \
    | sed -n 's/^ENV CASSANDRA_VERSION[[:space:]=]\{1,\}//p' \
    | head -1
}

# Versions baked into the currently published image, or empty when the image
# does not exist yet (first ever build).
published_versions() {
  image="${IMGBASE}:$1"
  if ! docker pull -q "$image" >/dev/null 2>&1; then
    echo " "
    return 0
  fi
  cassandra=$(docker inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}' \
    | sed -n 's/^CASSANDRA_VERSION=//p')
  agent=$(docker inspect "$image" \
    --format '{{index .Config.Labels "com.axonops.agent.version"}}')
  echo "$cassandra $agent"
}

stale=""
for ver in $VERSIONS; do
  pkg=$(agent_package "$ver")

  up_cassandra=$(upstream_cassandra_version "$ver")
  up_agent=$(upstream_agent_version "$pkg")
  if [ -z "$up_cassandra" ] || [ -z "$up_agent" ]; then
    echo "FATAL: could not resolve upstream versions for $ver (cassandra='$up_cassandra' agent='$up_agent' package='$pkg')"
    exit 1
  fi

  pub=$(published_versions "$ver")
  pub_cassandra=$(echo "$pub" | cut -d' ' -f1)
  pub_agent=$(echo "$pub" | cut -d' ' -f2)

  if [ -z "$pub_cassandra" ] || [ -z "$pub_agent" ]; then
    echo "$ver STALE   upstream=${up_cassandra}/${up_agent} published=<none>"
    stale="$stale $ver"
  elif [ "$up_cassandra" != "$pub_cassandra" ] || [ "$up_agent" != "$pub_agent" ]; then
    echo "$ver STALE   upstream=${up_cassandra}/${up_agent} published=${pub_cassandra}/${pub_agent}"
    stale="$stale $ver"
  else
    echo "$ver current upstream=${up_cassandra}/${up_agent} published=${pub_cassandra}/${pub_agent}"
  fi
done

# Trim the leading space so an empty result is genuinely empty.
echo "STALE_VERSIONS=$(echo "$stale" | sed 's/^ *//')"
