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
	chmod +x ./scripts/deploy-segment-routing.sh
	./scripts/deploy-segment-routing.sh

undeploy-segment-routing:
	@echo "=== Undeploying Segment Routing Sandbox ==="
	$(CONTAINER_ENGINE) compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml down --volumes --remove-orphans

follow-segment-routing-logs:
	@echo "=== Following Segment Routing Sandbox logs ==="
	$(CONTAINER_ENGINE) compose --file ~/XRd-Sandbox/topologies/segment-routing/docker-compose.yml logs --follow

extract-xrd:
	@echo "=== Extracting XRd Container Archive ==="
	chmod +x ./scripts/extract-xrd-container.sh
	./scripts/extract-xrd-container.sh

load-xrd:
	@echo "=== Loading XRd Container into $(CONTAINER_ENGINE_NAME) ==="
	chmod +x ./scripts/load-xrd-container.sh
	./scripts/load-xrd-container.sh

setup-xrd: extract-xrd load-xrd
	@echo "=== XRd Container Setup Complete ==="
	@echo "Container has been extracted and loaded into $(CONTAINER_ENGINE_NAME)"
	@echo "You can now use it with $(CONTAINER_ENGINE_NAME) compose or $(CONTAINER_ENGINE_NAME) run commands"

cleanup-temp-files:
	@echo "=== Cleaning up temporary files after deployment ==="
	@if [ -d "./xrd-container" ]; then \
		echo "Removing extracted container directory..."; \
		rm -rf ./xrd-container; \
	fi
	@echo "Removing XRd container archive files..."
	@find . -name "*.tgz" -type f -exec echo "Removing {}" \; -delete
	@echo "Cleanup complete"

help:
	@echo "Available targets:"
	@echo "  setup-ssh                   - Set up SSH keys for Git operations"
	@echo "  deploy-segment-routing      - Deploy Segment Routing Sandbox"
	@echo "  undeploy-segment-routing    - Undeploy Segment Routing Sandbox"
	@echo "  follow-segment-routing-logs - Follow Segment Routing Sandbox logs"
	@echo "  extract-xrd                 - Extract XRd container archive"
	@echo "  load-xrd                    - Load XRd container into $(CONTAINER_ENGINE_NAME)"
	@echo "  setup-xrd                   - Extract and load XRd container (full setup)"
	@echo "  cleanup-temp-files          - Clean up temporary files after deployment"
	@echo "  help                        - Show this help message"

.PHONY: setup-ssh deploy-segment-routing undeploy-segment-routing follow-segment-routing-logs extract-xrd load-xrd setup-xrd cleanup-temp-files help