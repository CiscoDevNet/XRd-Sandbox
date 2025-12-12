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
	@chmod +x ./scripts/setup/configure-ssh.sh
	@./scripts/setup/configure-ssh.sh

clone-xrd-tools:
	@echo "=== Setting up xrd-tools repository and PATH ==="
	@chmod +x ./scripts/setup/install-xrd-tools.sh
	@./scripts/setup/install-xrd-tools.sh

validate-environment:
	@echo "=== Validating Environment ==="
	@chmod +x ./scripts/validation/environment.sh
	@./scripts/validation/environment.sh

deploy-segment-routing:
	@echo "=== Deploying Segment Routing Sandbox ==="
	@chmod +x ./scripts/deployment/segment-routing.sh
	@./scripts/deployment/segment-routing.sh

undeploy-segment-routing:
	@echo "=== Undeploying Segment Routing Sandbox ==="
	@$(CONTAINER_ENGINE) compose --file $(SANDBOX_ROOT)/topologies/segment-routing/docker-compose.yml down --volumes --remove-orphans

follow-segment-routing-logs:
	@echo "=== Following Segment Routing Sandbox logs ==="
	@$(CONTAINER_ENGINE) compose --file $(SANDBOX_ROOT)/topologies/segment-routing/docker-compose.yml logs --follow

deploy-always-on: inject-local-user-always-on inject-aaa-always-on inject-tacacs-always-on
	@echo "=== Deploying Always-On Sandbox ==="
	@chmod +x ./scripts/deployment/always-on/deploy.sh
	@./scripts/deployment/always-on/deploy.sh

inject-local-user-always-on:
	@echo "=== Injecting Local User Configuration into Always-On Sandbox ==="
	@chmod +x ./scripts/deployment/always-on/inject-local-user.sh
	@./scripts/deployment/always-on/inject-local-user.sh

inject-aaa-always-on:
	@echo "=== Injecting TACACS AAA Configuration into Always-On Sandbox ==="
	@chmod +x ./scripts/deployment/always-on/inject-aaa.sh
	@./scripts/deployment/always-on/inject-aaa.sh

inject-tacacs-always-on:
	@echo "=== Injecting TACACS Configuration into Always-On Sandbox ==="
	@chmod +x ./scripts/deployment/always-on/inject-tacacs.sh
	@./scripts/deployment/always-on/inject-tacacs.sh

undeploy-always-on:
	@echo "=== Undeploying Always-On Sandbox ==="
	@$(CONTAINER_ENGINE) compose --file $(SANDBOX_ROOT)/topologies/always-on/docker-compose.yml down --volumes --remove-orphans

follow-always-on-logs:
	@echo "=== Following Always-On Sandbox logs ==="
	@$(CONTAINER_ENGINE) compose --file $(SANDBOX_ROOT)/topologies/always-on/docker-compose.yml logs --follow

extract-xrd:
	@echo "=== Extracting XRd Container Archive ==="
	@chmod +x ./scripts/setup/extract-container.sh
	@./scripts/setup/extract-container.sh

load-xrd:
	@echo "=== Loading XRd Container into $(CONTAINER_ENGINE_NAME) ==="
	@chmod +x ./scripts/setup/load-container.sh
	@./scripts/setup/load-container.sh

setup-xrd: extract-xrd load-xrd
	@echo "=== XRd Container Setup Complete ==="
	@echo "Container has been extracted and loaded into $(CONTAINER_ENGINE_NAME)"
	@echo "You can now use it with $(CONTAINER_ENGINE_NAME) compose or $(CONTAINER_ENGINE_NAME) run commands"

cleanup-environment:
	@echo "=== Cleaning Up Environment After Setup ==="
	@chmod +x ./scripts/maintenance/cleanup.sh
	@./scripts/maintenance/cleanup.sh

help:
	@echo "Available targets:"
	@echo "  setup-ssh                   - Set up SSH keys for Git operations"
	@echo "  clone-xrd-tools             - Clone xrd-tools repository and add scripts to PATH"
	@echo "  validate-environment        - Validate environment for XRd Sandbox"
	@echo "  deploy-segment-routing      - Deploy Segment Routing Sandbox"
	@echo "  undeploy-segment-routing    - Undeploy Segment Routing Sandbox"
	@echo "  follow-segment-routing-logs - Follow Segment Routing Sandbox logs"
	@echo "  deploy-always-on            - Deploy Always-On Sandbox"
	@echo "  inject-local-user-always-on - Inject local user configuration into Always-On startup files"
	@echo "  inject-aaa-always-on - Inject TACACS AAA configuration into Always-On startup files"
	@echo "  inject-tacacs-always-on - Inject TACACS configuration into Always-On startup files"
	@echo "  undeploy-always-on          - Undeploy Always-On Sandbox"
	@echo "  follow-always-on-logs       - Follow Always-On Sandbox logs"
	@echo "  extract-xrd                 - Extract XRd container archive"
	@echo "  load-xrd                    - Load XRd container into $(CONTAINER_ENGINE_NAME)"
	@echo "  setup-xrd                   - Extract and load XRd container (full setup)"
	@echo "  cleanup-environment         - Clean up environment after successful setup"
	@echo "  help                        - Show this help message"

.PHONY: setup-ssh clone-xrd-tools validate-environment deploy-segment-routing undeploy-segment-routing follow-segment-routing-logs deploy-always-on inject-local-user-always-on inject-tacacs-always-on undeploy-always-on follow-always-on-logs extract-xrd load-xrd setup-xrd cleanup-environment help