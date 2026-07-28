#!/bin/bash

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

touch /var/log/axonops/axon-agent.log
chown axonops:axonops /var/log/axonops/axon-agent.log
if [ -f /usr/share/axonops/axonops-jvm.options ]; then
  echo ". /usr/share/axonops/axonops-jvm.options" >> $CASSANDRA_CONF/cassandra-env.sh
else
  MAJOR_VERSION=$(echo "$CASSANDRA_VERSION" | sed -r 's/^([0-9]+\.[0-9]+).*$/\1/')
  echo "JVM_OPTS=\"\$JVM_OPTS -javaagent:/usr/share/axonops/axon-cassandra$MAJOR_VERSION-agent.jar=/etc/axonops/axon-agent.yml\"" >> $CASSANDRA_CONF/cassandra-env.sh
fi
# Supervise axon-agent: restart forever on exit, with crash-loop backoff.
# Runs as the axonops user in the background so the container lifecycle stays
# tied to Cassandra (exec'd below), not the agent. If the agent dies it is
# restarted automatically; the loop survives the exec by being reparented to
# the Cassandra process. The agent is piped through tee, so its real exit code
# is read from PIPESTATUS. Previously a dead agent was never restarted.
export AXON_AGENT_ARGS
su axonops -c '
  log=/var/log/axonops/axon-agent.log
  fails=0
  window=$(date +%s)
  while true; do
    echo "[axonops-supervise] starting axon-agent" | tee -a "$log" 2>/dev/null
    /usr/share/axonops/axon-agent $AXON_AGENT_ARGS 2>&1 | tee -a "$log" 2>/dev/null
    rc=${PIPESTATUS[0]}
    echo "[axonops-supervise] axon-agent exited rc=${rc}, restarting" | tee -a "$log" 2>/dev/null
    now=$(date +%s)
    if [ $((now - window)) -gt 60 ]; then
      fails=0
      window=$now
    fi
    fails=$((fails + 1))
    if [ "$fails" -gt 5 ]; then
      echo "[axonops-supervise] >5 restarts in 60s, backing off 30s" | tee -a "$log" 2>/dev/null
      sleep 30
      fails=0
      window=$(date +%s)
    else
      sleep 2
    fi
  done
' &

exec /usr/local/bin/docker-entrypoint.sh "$@"
