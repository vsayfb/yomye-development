.PHONY: help setup notification-lambda up up-worker up-chat up-api down clean destroy restart logs

INFRA := docker compose -p infra -f infra.yml
LGTM := docker compose -p lgtm -f lgtm.yml
COMPUTE := docker compose -p compute -f compute.yml

help:
	@echo "Yömye local development"
	@echo ""
	@echo "  make setup      Create the local .env file when it is missing"
	@echo "  make notification-lambda  Build the Lambda package used by LocalStack"
	@echo "  make up         Start infrastructure, observability, and all services"
	@echo "  make up-api     Build and start only Core"
	@echo "  make up-chat    Build and start only Chat"
	@echo "  make up-worker  Build and start only Worker"
	@echo "  make logs       Follow application-service logs"
	@echo "  make restart    Restart the full local environment"
	@echo "  make down       Stop the environment and keep its data"
	@echo "  make clean      Stop it and delete project volumes"
	@echo "  make destroy    Also delete locally built project images"

setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created development/.env from .env.example."; \
		echo "LAMBDA_PROJECT must be set in development/.env before make up is run."; \
	else \
		echo "development/.env already exists; leaving it unchanged."; \
	fi
	@docker network inspect gig-platform >/dev/null 2>&1 || docker network create gig-platform

notification-lambda:
	$(MAKE) -C ../notification build

up: notification-lambda
	$(INFRA) up -d
	$(LGTM) up -d
	$(COMPUTE) up -d --build

up-worker:
	$(COMPUTE) up -d --build categorization-worker

up-chat:
	$(COMPUTE) up -d --build chat-svc

up-api:
	$(COMPUTE) up -d --build api

down:
	$(COMPUTE) down
	$(LGTM) down
	$(INFRA) down

clean:
	$(COMPUTE) down -v --remove-orphans
	$(LGTM) down -v --remove-orphans
	$(INFRA) down -v --remove-orphans
	docker volume prune -f

destroy:
	$(COMPUTE) down -v --remove-orphans --rmi local
	$(LGTM) down -v --remove-orphans --rmi local
	$(INFRA) down -v --remove-orphans --rmi local
	docker volume prune -f

restart: down up

logs:
	$(COMPUTE) logs -f
