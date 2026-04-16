IMAGE_NAME ?= hexstrike-ai
CONTAINER_NAME ?= hexstrike-ai
PORT ?= 8888
HEXSTRIKE_SERVER ?= http://host.docker.internal:$(PORT)
BUILD_ARGS ?=
DOCKER ?= docker

.PHONY: help build build-minimal run run-mcp stop restart logs shell health clean

help:
	@echo "Targets:"
	@echo "  make build         Build the full HexStrike image"
	@echo "  make build-minimal Build the image without full extra tools"
	@echo "  make run           Run the API server container on PORT=$(PORT)"
	@echo "  make run-mcp       Run the MCP client container"
	@echo "  make stop          Stop and remove the container if it exists"
	@echo "  make restart       Recreate the API server container"
	@echo "  make logs          Follow container logs"
	@echo "  make shell         Open a shell in the running container"
	@echo "  make health        Query the API health endpoint"
	@echo "  make clean         Remove the local image"

build:
	$(DOCKER) build $(BUILD_ARGS) -t $(IMAGE_NAME) .

build-minimal:
	$(DOCKER) build --build-arg INSTALL_FULL_TOOLS=false $(BUILD_ARGS) -t $(IMAGE_NAME) .

run:
	$(MAKE) stop
	$(DOCKER) run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):8888 \
		$(IMAGE_NAME)

run-mcp:
	$(MAKE) stop
	$(DOCKER) run -d \
		--name $(CONTAINER_NAME) \
		-e HEXSTRIKE_SERVER=$(HEXSTRIKE_SERVER) \
		$(IMAGE_NAME) mcp

stop:
	-$(DOCKER) rm -f $(CONTAINER_NAME)

restart:
	$(MAKE) run

logs:
	$(DOCKER) logs -f $(CONTAINER_NAME)

shell:
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/bash

health:
	@curl --fail --silent http://127.0.0.1:$(PORT)/health | python3 -m json.tool

clean:
	-$(DOCKER) rmi $(IMAGE_NAME)
