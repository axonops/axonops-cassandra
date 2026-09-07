#!/bin/bash


set -e
set -x

if [[ "${AXON_AGENT_DEV}" != "True" && "${AXON_AGENT_DEV}" != "true" ]] || [[ "${CASSANDRA_AGENT_DEV}" != "True" && "${CASSANDRA_AGENT_DEV}" != "true" ]]; then

  if [ "$AGENT_REPO" = "dev" ]; then \
    AGENT_REPO_NAME=axonops-apt-dev; \
  elif [ "$AGENT_REPO" = "beta" ]; then \
    AGENT_REPO_NAME=axonops-apt-beta; \
  else \
    AGENT_REPO_NAME=axonops-apt; \
  fi; \
  echo "deb https://packages.axonops.com/apt $AGENT_REPO_NAME main" | tee /etc/apt/sources.list.d/axonops-apt.list

  apt-get -y update
  apt policy

fi

if [ ! -d /var/lib/axonops ]; then
  mkdir -p /var/lib/axonops
fi

chown axonops /var/lib/axonops

if [ ! -d /var/log/axonops ]; then
  mkdir /var/log/axonops
  chown axonops /var/log/axonops
fi

echo "agent repo name -> ${AGENT_REPO_NAME}"

if [ -n "${AXON_AGENT_VERSION}" ]; then
  AXON_AGENT_STRING=axon-agent=${AXON_AGENT_VERSION}
else
  AXON_AGENT_STRING=axon-agent
fi

if [[ "${AXON_AGENT_DEV}" != "True" && "${AXON_AGENT_DEV}" != "true" ]]; then
  apt-get -y install ${AXON_AGENT_STRING}
fi

if [ -n "${CASSANDRA_AGENT_VERSION}" ]; then
    CASSANDRA_AGENT_STRING=axon-cassandra${CASSANDRA_MAJOR_VERSION}-agent=${CASSANDRA_AGENT_VERSION}-jdk17
else
    CASSANDRA_AGENT_STRING=axon-cassandra${CASSANDRA_MAJOR_VERSION}-agent-jdk17
fi

if [[ "${CASSANDRA_AGENT_DEV}" != "True" && "${CASSANDRA_AGENT_DEV}" != "true" ]]; then
  apt-get -y install -t ${AGENT_REPO_NAME} ${CASSANDRA_AGENT_STRING} --allow-downgrades
  su -c "chmod g+r /usr/share/axonops/axon-cassandra${CASSANDRA_MAJOR_VERSION}-agent.jar"
fi

if [[ "${AXON_AGENT_DEV}" != "True" && "${AXON_AGENT_DEV}" != "true" ]]; then
  AXON_AGENT_CONFIG_LOCATION=/etc/axonops/axon-agent.yml
else
  mkdir -p /tmp/axonops/config
  chown -R axonops:axonops /tmp/axonops
  AXON_AGENT_CONFIG_LOCATION=/tmp/axonops/config/test_config.yml

  cat <<EOF > ${AXON_AGENT_CONFIG_LOCATION}
  axon-server:
      hosts: "${AXON_AGENT_SERVER_HOST}"
      port: ${AXON_AGENT_SERVER_PORT}

  axon-agent:
      org: "${AXON_AGENT_ORG}"
      # tls:
      #   mode: "DISABLED"
      cluster_name: "${CASSANDRA_CLUSTER_NAME}"
      OpenTSDB_service_test: true
      # key: "1a5a56fc12d9e39b7d2fb84dffdee455"
EOF

fi

apt-get clean

touch /var/run/utmp

touch /var/log/axonops/axon-agent.log
chown axonops:axonops /var/log/axonops/axon-agent.log

if [ ! -f /etc/axonops/axon-agent.yml ]; then
echo 'axon-agent:' > /etc/axonops/axon-agent.yml
fi

su -c "chown cassandra /etc/axonops/axon-agent.yml"
su -c "ls -l /etc/axonops/"

# Run the provided command if it is not "cassandra" (optionally with arguments)
if [ "$1" != "cassandra" ]
then
  exec "$@"
  exit $?
fi

if [ "$CASSANDRA_NATIVE_TRANSPORT_PORT" != "" ]
then
  sed -i "s/^native_transport_port:.*$/native_transport_port: $CASSANDRA_NATIVE_TRANSPORT_PORT/" "$CASSANDRA_CONF/cassandra.yaml"
fi

# # REMOVE ME
# apt install less
# sed -i '/^rack=/d' /etc/cassandra/cassandra-rackdc.properties

touch /var/log/axonops/axon-agent.log
chown axonops:axonops /var/log/axonops/axon-agent.log

if [ ${AXON_AGENT_DEV} == true ]; then
  cd /tmp/axonagent
  su axonops -c "/tmp/axonagent/axon-agent $AXON_AGENT_ARGS" &
else
  su axonops -c "/usr/share/axonops/axon-agent $AXON_AGENT_ARGS" &
fi

check_seed_status (){
  echo "Checking Cassandra Seeds node status"
  MAX_ATTEMPTS=30
  ATTEMPTS=0
  DELAY_TIME=20

  until cqlsh ${CASSANDRA_SEEDS} -e "DESCRIBE KEYSPACES" >/dev/null 2>&1; do
      ATTEMPTS=$((ATTEMPTS+1))
      if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
          echo "Failed to connect after $MAX_ATTEMPTS attempts"
          exit 1
      fi
      echo "Attempt $ATTEMPTS/$MAX_ATTEMPTS: Cassandra not ready, retrying in ${DELAY_TIME} seconds..."
      sleep ${DELAY_TIME}
  done

}

if [ "${CASSANDRA_SEED_NODE}" == false ]; then
  check_seed_status
fi

if [ "${CASSANDRA_DATA_LOAD}" == true ]; then
  check_seed_status

  cqlsh -f /tmp/testdb.sql ${CASSANDRA_SEEDS}
fi


#exec /usr/local/bin/docker-entrypoint.sh "$@"
exec /axonops-entrypoint.sh "$@"
