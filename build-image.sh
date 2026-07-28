#!/bin/sh
set -e

if [ "$IMGBASE" = "" ]
then
  echo "FATAL: IMGBASE is not set"
  exit 1
fi

VER=$1
case "$VER" in
  5.0|4.1|4.0)
    echo "Building image for Cassandra $VER"
  ;;
  *)
    echo "Unknown or unsupported Cassandra version $VER"
    exit 1
  ;;
esac
ARCH=${2:-amd64}

# Build our own Cassandra base image or use the offical one
if [ -d cassandra/$VER ]
then
  (cd cassandra/$VER && docker build -t=cassandra:${VER} .)
else
  docker pull cassandra:$VER
fi

IMAGE="$IMGBASE:${VER}-${ARCH}"
STAGE="${IMAGE}-unstamped"

TMPFILE=Dockerfile-$VER
sed "s/{{CASSANDRA_VER}}/$VER/g" <Dockerfile-template >$TMPFILE
docker build -t="$STAGE" -f $TMPFILE .
rm -f $TMPFILE

# apt resolves the axon-agent version during the build, so it can only be read
# afterwards. List the installed packages and pick the axon-cassandra agent
# (native arch, image already local), then stamp it as a label so consumers and
# CI can read it with `docker inspect` instead of having to run the image.
# The package is named axon-cassandra<ver>-agent (or -agent-jdk17 on 5.0), so
# match on the prefix rather than relying on a dpkg-query wildcard.
# The version extraction assumes a Debian version of the form
# [epoch:]upstream[-revision]; strip a leading epoch and the trailing Debian
# revision, keeping the upstream version for the label (e.g. 1:2.1.0-1 -> 2.1.0).
AGENT_VER=$(docker run --rm --entrypoint sh "$STAGE" -c \
  "dpkg-query -W -f='\${Package} \${Version}\n' 2>/dev/null \
     | awk '\$1 ~ /^axon-cassandra[0-9.]+-agent(-jdk[0-9]+)?\$/ {print \$2; exit}'" \
  | sed 's/^[0-9]*://; s/-[^-]*$//')

if [ -z "$AGENT_VER" ]
then
  echo "FATAL: could not determine the axon-agent version in $STAGE"
  echo "Installed axon* packages:"
  docker run --rm --entrypoint sh "$STAGE" -c \
    "dpkg-query -W -f='\${Package}\t\${Version}\n' 'axon*' 2>&1 || true"
  docker image rm "$STAGE" >/dev/null 2>&1 || true
  exit 1
fi
echo "Stamping axon-agent version $AGENT_VER"

echo "FROM $STAGE" | docker build \
  --label "com.axonops.agent.version=${AGENT_VER}" \
  -t="$IMAGE" -

docker image rm "$STAGE" >/dev/null 2>&1 || true
