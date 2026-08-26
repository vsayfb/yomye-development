.PHONY: up down clean restart logs

INFRA := docker compose -p infra -f infra.yml
LGTM := docker compose -p lgtm -f lgtm.yml
COMPUTE := docker compose -p compute -f compute.yml

up:
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
