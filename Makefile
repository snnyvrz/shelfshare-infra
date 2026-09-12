.ONESHELL:
SHELL := /bin/bash

.DEFAULT_GOAL := check_configured

CONFIG_STAMP := .configured

.PHONY: check_configured
ifeq ($(CI),true)

check_configured:
	@:

else

check_configured:
	@if [ ! -f "$(CONFIG_STAMP)" ]; then \
		echo "Please run the configure script before using any make commands:"; \
		echo ""; \
		echo "    chmod +x ./configure"; \
		echo "    ./configure"; \
		echo ""; \
		exit 1; \
	fi

endif

.PHONY: help
help: check_configured
help: ## Show the help message
	@echo ""
	@echo "Available make commands:"
	@echo ""
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*##"} {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""

.PHONY: decrypt-secrets
decrypt-secrets: check_configured
decrypt-secrets: ## Decrypt secrets using sops
	./scripts/sops.sh decrypt $(filter-out $@,$(MAKECMDGOALS))

.PHONY: encrypt-secrets
encrypt-secrets: check_configured
encrypt-secrets: ## Encrypt secrets using sops
	./scripts/sops.sh encrypt $(filter-out $@,$(MAKECMDGOALS))

ENV_DEV  := .env
ENV_TEST := .env.test
ENV_LOCALPROD := .env.localprod

INFRA_COMPOSE    := -f docker-compose.infra.yml
POSTGRES_SERVICE := postgres
POSTGRES_CONTAINER := shelfshare-postgres

DC = docker compose --env-file $(ENV_FILE) $(INFRA_COMPOSE)

define wait_for_postgres
	@echo "Waiting for Postgres to become healthy..."
	@while true; do \
		status=$$(docker inspect --format='{{.State.Health.Status}}' $(POSTGRES_CONTAINER) 2>/dev/null || echo "starting"); \
		if [ "$$status" = "healthy" ]; then \
			echo "Postgres is healthy"; \
			break; \
		elif [ "$$status" = "unhealthy" ]; then \
			echo "Postgres is UNHEALTHY — check logs with 'make logs'"; \
			exit 1; \
		else \
			echo "Current status: $$status… waiting 1s"; \
			sleep 1; \
		fi; \
	done
endef

.PHONY: dev
dev: check_configured decrypt-secrets
dev: ## Run development environment
	./scripts/dev.sh $(filter-out $@,$(MAKECMDGOALS))

.PHONY: test
test: check_configured decrypt-secrets
test: ## Run tests
	./scripts/test.sh $(filter-out $@,$(MAKECMDGOALS))

.PHONY: books auth
books auth:
	@:

.PHONY: books-coverage
books-coverage: check_configured decrypt-secrets
books-coverage: ## Run books-service coverage and open report
	bun x nx affected --target=coverage
	nohup xdg-open apps/books-service/coverage/coverage.html >/dev/null 2>&1 & echo "" || true

.PHONY: books-integration-test
books-integration-test: check_configured decrypt-secrets
books-integration-test: ENV_FILE=$(ENV_TEST)
books-integration-test: ## Run books-service integration tests with infra
	@set -e
	echo "Starting infra..."
	$(DC) up -d $(POSTGRES_SERVICE)

	$(call wait_for_postgres)

	echo "Running books-service integration tests..."
	set -a; . $(ENV_TEST); set +a;

	docker exec $(POSTGRES_CONTAINER) psql -U $$POSTGRES_USER -d postgres \
		-tc "SELECT 1 FROM pg_database WHERE datname = '$$POSTGRES_DB'" | grep -q 1 || \
	docker exec $(POSTGRES_CONTAINER) psql -U $$POSTGRES_USER -d postgres \
		-c "CREATE DATABASE $$POSTGRES_DB"

	bun x nx affected --target=integration-test

	echo "books-service integration tests completed."
	echo "Stopping infra..."
	$(DC) down

.PHONY: books-infra-up
books-infra-up: check_configured decrypt-secrets
books-infra-up: ENV_FILE=$(ENV_DEV)
books-infra-up: ## Start only the infra services (Postgres)
	$(DC) up -d $(POSTGRES_SERVICE)

.PHONY: infra-down
infra-down: check_configured
infra-down: ENV_FILE=$(ENV_DEV)
infra-down: ## Stop infra services
	$(DC) down

.PHONY: logs
logs: check_configured
logs: ENV_FILE=$(ENV_DEV)
logs: ## Show logs for infra services
	$(DC) logs -f

.PHONY: localprod-certs
localprod-certs: check_configured
localprod-certs: ## Generate local-production Envoy certificates
	./scripts/generate-localprod-certs.sh

.PHONY: books-localprod
books-localprod: check_configured decrypt-secrets localprod-certs
books-localprod: ## Run local production stack (Postgres + books-api)
	@set -e
	echo "Starting localprod stack (Postgres + Envoy + books-api)..."

	cleanup() {
		echo ""
		echo "Stopping localprod stack..."
		docker compose --env-file $(ENV_LOCALPROD) \
			-f docker-compose.localprod.yml \
			down
	}
	trap cleanup INT TERM EXIT

	docker compose --env-file $(ENV_LOCALPROD) \
		-f docker-compose.localprod.yml \
		up --build

.PHONY: configure-force
configure-force: ## Force re-running the configure script
	@rm -f $(CONFIG_STAMP)
	@./configure

.PHONY: %
%: check_configured
%:
	@echo ""
	@echo "Unknown command: '$@'"
	@echo ""
	@$(MAKE) --no-print-directory help
	@exit 1
