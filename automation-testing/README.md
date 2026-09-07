# Cassandra automation testing environment

These steps require the base Cassandra image to already be built using the parent directory steps

```
registry.axonops.com/axonops-public/axonops-docker/cassandra:4.1
```

## Build container
```
make build
```

## Run environment
```
make test
```
will startup a single node in the foreground

to start up individual nodes in a cluster you can do
```
make node0
```
which will start the node in detacted mode.

You can run:
```
make clean
```
to tidy up

## Environment Variables in Makefile
```
export CASSANDRA_MAJOR_VERSION = 5.0
export AXONOPS_SERVER_HOSTS := < IP address of your axon server >
export AXONOPS_ORG := < Name of org to register>
export AXONOPS_CLUSTER_NAME := < Name of cluster to register >

# Set true if using a local version of agent and set volume mount
export AXON_AGENT_DEV := true
export AXON_AGENT_SOURCE_DIR := < local location of Axonops git source for Axon agent local dev mode >
export AXON_AGENT_VERSION :=

# Set true if using a local version of java agent and set volume mount
export CASSANDRA_AGENT_DEV := false
export CASSANDRA_AGENT_SOURCE_DIR := < local location of Axonops git source for cassandra agent local dev mode>
export CASSANDRA_AGENT_VERSION :=

export AGENT_REPO_NAME := "prod"

# Args to pass through to JVM
export JAVA_EXTRA_ARGS := -javaagent:/usr/share/axonops/axon-cassandra$(CASSANDRA_MAJOR_VERSION)-agent.jar=/etc/axonops/axon-agent.yml

```

## Initial data load
There is special environment variable CASSANDRA_DATA_LOAD=true that you can put into one of the cassandra nodes.  This will load the sql from the file testdb.sql you will also need to set a volume mount on that node

| ./testdb.sql:/tmp/testdb.sql

## Compose volume mounts

```
      # only if AXON_AGENT_DEV=true
      - ${AXON_AGENT_SOURCE_DIR}/axon-agent:/tmp/axonagent/axon-agent

      # only if AXON_JAVA_AGENT_DEV=true
      - ${CASSANDRA_AGENT_SOURCE_DIR}/build/libs/axon-cassandra${CASSANDRA_MAJOR_VERSION}-agent.jar:/usr/share/axonops/axon-cassandra${CASSANDRA_MAJOR_VERSION}-agent.jar:ro
```
