HOME := $(shell echo $$HOME)
export HOME

include sandbox_env_vars.sh
-include .env

export

# Detect if docker or podman is available and use the one that is available
CONTAINER_ENGINE := $(shell which docker 2>/dev/null || which podman 2>/dev/null)
ifeq ($(CONTAINER_ENGINE),)
$(error Neither Docker nor Podman is installed or in PATH)
endif
CONTAINER_ENGINE_NAME := $(shell basename $(CONTAINER_ENGINE))
export CONTAINER_ENGINE CONTAINER_ENGINE_NAME

# Only used for sandbox development
setup-ssh:
	@echo "=== Setting up SSH keys for Git operations ==="
	chmod +x ./scripts/setup_ssh.sh
	./scripts/setup_ssh.sh

deploy-segment-routing:
	@echo "=== Deploying Segment Routing Sandbox ==="
	chmod +x ./scripts/deploy_segment_routing.sh
	./scripts/deploy_segment_routing.sh
