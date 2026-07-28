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
# afterwards. Query it once here (native arch, image already local) and stamp it
# as a label, so consumers and CI can read it with `docker inspect` instead of
# having to run the image.
AGENT_VER=$(docker run --rm --entrypoint sh "$STAGE" -c \
  "dpkg-query -W -f='\${Version}\n' 'axon-cassandra*-agent*' 2>/dev/null | head -1" \
  | sed 's/-.*//')

if [ -z "$AGENT_VER" ]
then
  echo "FATAL: could not determine the axon-agent version in $STAGE"
  docker image rm "$STAGE" >/dev/null 2>&1 || true
  exit 1
fi
echo "Stamping axon-agent version $AGENT_VER"

echo "FROM $STAGE" | docker build \
  --label "com.axonops.agent.version=${AGENT_VER}" \
  -t="$IMAGE" -

docker image rm "$STAGE" >/dev/null 2>&1 || true
