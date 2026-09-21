# Yömye local development

This directory starts the complete local backend. The `Makefile` is the entry point for development commands. Commands should be run from this directory through `make`. The Compose files should not normally be started one by one.

## Configuration files

### `development/.env.example`

`.env.example` is the committed configuration template:

```env
LAMBDA_PROJECT=<notification-service-path>
```

`LAMBDA_PROJECT` points to the local Notification repository. LocalStack uses this path to mount:

- `lambda.zip`, which contains the local Notification Lambda;
- Notification's `.env.example`, which provides local Lambda settings;
- `firebase-credentials.json`, which is required when local Firebase delivery is tested.

An absolute path should be used for `LAMBDA_PROJECT`. Personal paths and secrets should not be added to `.env.example`.

### `development/.env`

`.env.example` should be copied to `.env`. The same variable names should be kept, and each placeholder should be replaced with its local value. This copy is performed by:

```bash
make setup
```

For example:

```env
LAMBDA_PROJECT=/absolute/path/to/yomye/notification
```

Docker Compose reads `development/.env` and replaces `${LAMBDA_PROJECT}` in `infra.yml`. This file is used by the development Compose project only. It is not passed to every service container and does not replace each service's own `.env` file.

`development/.env` is ignored by Git and must not be committed.

### Service environment files

Core, Chat, and Worker each have an `.env.example` in their own repository. Each service template should be copied to that service's local `.env`, and its placeholders should be filled with local values. These files contain settings such as database endpoints, queue endpoints, API credentials, and storage settings.

| File | Used by | Purpose |
| --- | --- | --- |
| `development/.env` | Development Compose project | Locates the Notification repository |
| `core/.env` | Core container | Configures Core |
| `chat/.env` | Chat container | Configures Chat |
| `worker/.env` | Worker container | Configures Worker |
| `notification/.env.example` | LocalStack Notification Lambda | Supplies local Lambda settings |

Real staging or production secrets must not be placed in local `.env` files. Staging and production load their settings from their own cloud configuration and secret stores.

## First-time setup

The following tools and files are required:

- Docker with Docker Compose;
- Go and `zip` for the Notification Lambda build;
- local service `.env` files for the services that will be run;
- Firebase credentials when local push delivery will be tested;
- Ollama on the host when Worker classification will be tested.

The development setup should be prepared through the Makefile:

```bash
cd development
make setup
```

`make setup` performs two actions:

1. `.env.example` is copied to `.env` when `.env` does not exist.
2. The shared `gig-platform` Docker network is created when it does not exist.

After setup, the placeholder in `development/.env` should be replaced with the absolute Notification repository path. The Core, Chat, and Worker `.env` files should also be prepared from their own examples.

## Development commands

The available commands are shown by:

```bash
make help
```

The complete local environment is started by:

```bash
make up
```

Before the containers are started, `make up` calls the Notification repository's Makefile and builds `lambda.zip`. The local system is then started without requiring its parts to be built or started by hand.

The Notification Lambda package can be built separately with:

```bash
make notification-lambda
```

`make up` starts:

- PostgreSQL and pgAdmin;
- MongoDB as a replica set;
- LocalStack with category, chat, and notification SQS queues;
- the local Notification Lambda;
- OpenTelemetry Collector, Prometheus, Loki, Tempo, and Grafana;
- Core, Chat, and Worker.

One application service can be rebuilt and started while the shared infrastructure is already running:

```bash
make up-api
make up-chat
make up-worker
```

Application logs are followed with:

```bash
make logs
```

The complete environment is restarted with:

```bash
make restart
```

Containers are stopped without deleting database and LocalStack volumes with:

```bash
make down
```

Containers and project volumes are deleted with:

```bash
make clean
```

Locally built project images are also deleted with:

```bash
make destroy
```

`make clean` and `make destroy` remove local development data. Docker's unused-volume cleanup is also run, so other stopped Docker projects should be reviewed first.

## Environment use

- Local development should be used for coding, local integration work, queue-flow tests, database migrations, and observability checks.
- AWS staging should be used when a change must be tested with real cloud networking, permissions, managed PostgreSQL, SQS, Lambda, and deployment workflows.
- GCP production should be used only for reviewed releases intended for real users.

Local development data and files must not be treated as staging or production state.
