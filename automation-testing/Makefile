

include ./Makefile.variables


help: ## This
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build container image
	${CONTAINER_TYPE} build --no-cache -t $(IMAGE_NAME) -f $(DOCKERFILE) --build-arg CASSANDRA_MAJOR_VERSION=${CASSANDRA_MAJOR_VERSION} .

clean: ## Remove all running containers
	${CONTAINER_TYPE}-compose -f compose.yml down

run: ## Startup Node0
	${CONTAINER_TYPE}-compose -f compose.yml up -d

node0: ## Startup Node0
	${CONTAINER_TYPE}-compose -f compose.yml up -d cassandra-0

node1: ## Startup Node1
	${CONTAINER_TYPE}-compose -f compose.yml up -d cassandra-1

node2: ## Startup Node2
	${CONTAINER_TYPE}-compose -f compose.yml up -d cassandra-2

status:
	${CONTAINER_TYPE}-compose -f compose.yml ps

runsupporting:
	$(CONTAINER_TYPE)-compose -f compose.yml up minio -d
	$(CONTAINER_TYPE)-compose -f compose.yml up minio-init -d
	$(CONTAINER_TYPE)-compose -f compose.yml up ssh-server -d

stopsupporting:
	$(CONTAINER_TYPE)-compose -f compose.yml down minio
	$(CONTAINER_TYPE)-compose -f compose.yml down ssh-server
