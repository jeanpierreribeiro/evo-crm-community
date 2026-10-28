# Evo CRM Community — Setup Guide

This guide gets the full Evo CRM Community stack running from a clean checkout.

## Supported deployment methods

There are exactly **two** supported ways to run the stack:

| Method | File | Use case |
| ------ | ---- | -------- |
| `docker compose up` | `docker-compose.yml` | Local development (builds the Ruby/Python/JS services from the submodules, pulls the Go core image). |
| `docker stack deploy` | `docker-compose.swarm.yaml` | Production on Docker Swarm (all images pulled from Docker Hub, fronted by the nginx gateway + Traefik). |

> **`docker run` is NOT supported.** The services depend on a shared Postgres,
> Redis, RabbitMQ, ClickHouse and on service-to-service URLs that are wired by
> the compose/stack files. Running a single service with `docker run` will not
> bring up a usable environment. Use one of the two methods above.

## Prerequisites

- Git
- Docker + Docker Compose v2 (`docker compose version`)
- A running Docker daemon

## Quick start (local development)

```bash
git clone --recurse-submodules https://github.com/evolution-foundation/evo-crm-community.git
cd evo-crm-community
cp .env.example .env        # defaults work out of the box — no edits needed
make setup                  # builds images, starts infra, seeds the DB, boots everything
```

Or run the interactive script, which does the same steps with prompts:

```bash
bash setup.sh
```

### First access

There is **no pre-seeded login**. Open the setup wizard and create your admin
user:

```
http://localhost:5173/setup
```

### Service URLs (host ports)

These are the **host** ports published by `docker-compose.yml` (the browser
talks to them directly):

| Service      | URL                       |
| ------------ | ------------------------- |
| Frontend     | http://localhost:5173     |
| Nginx Gateway| http://localhost:3030     |
| CRM API      | http://localhost:3010     |
| Auth API     | http://localhost:3011     |
| Scheduling   | http://localhost:3012     |
| Projects     | http://localhost:3013     |
| Core API     | http://localhost:5565     |
| Processor    | http://localhost:8011     |
| Bot Runtime  | http://localhost:8092     |
| Mailhog      | http://localhost:18025    |

The frontend's `VITE_*` URLs in `.env.example` already point at these host
ports — if they don't match, every API/WebSocket call fails with *connection
refused* (see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)). The frontend image
substitutes these into the built assets at **container start** (the entrypoint
replaces `VITE_*_PLACEHOLDER` tokens), so changing one only needs
`docker compose up -d --force-recreate evo-frontend` — no image rebuild.

### Database seeding & migrations

`make setup` runs `make seed`, which is the canonical flow:

1. `evo-crm` creates the DB and loads the **master schema** (`db:schema:load`).
2. The auth service's migrations are **marked as applied** (the schema load
   already created their tables).
3. Application seeds run for CRM and then auth.
4. The projects service migrations run via the dedicated `evo-projects-migrate` container (`prisma migrate deploy` under the isolated `projects` schema with DDL user `projects_migrator`). In local dev or CI, it can also be run directly via `pnpm --dir evo-projects-service run db:migrate`.

`setup.sh` performs the same sequence — keep the two in sync if you change one.

### Projects Service: Storage, Attachments, and Backups

The Projects submodule (`evo-projects-service`) includes secure file attachment storage:

1. **Storage Directory (`PROJECTS_STORAGE_DIR`):**
   - Configured via environment variable `PROJECTS_STORAGE_DIR` (defaults to `./.storage/attachments` in local development or `/app/.storage/attachments` in containerized environments).
   - Ensure the runtime user (`projects_app` or node container user) has read and write permissions on this directory.
2. **Attachment Limits & Nginx Configuration:**
   - File size limit per upload is **20 MiB**.
   - The Nginx Gateway (`nginx/default.conf.template`) includes a dedicated directive with `client_max_body_size 25M;` for the route `~ ^/api/v1/projects/tasks/[^/]+/attachments$` to allow multipart overhead without compromising the global 10M limit on other APIs.
3. **Database Schema & Migrations:**
   - Isolated under PostgreSQL schema `projects` (`?schema=projects`).
   - Schema migrations run strictly through `prisma migrate deploy` using the DDL role `projects_migrator`.
4. **Backup and Recovery:**
   - **Database Backup:** Dump the `projects` schema with `pg_dump -U postgres -d evo_community -n projects -Fc -f projects_backup.dump`.
   - **Storage Backup:** Periodically back up the volume/directory referenced by `PROJECTS_STORAGE_DIR`. Both the database records and physical files must be restored together for consistency.
   - **Diagnostic Tooling:** Run `AttachmentDiagnosticService` to verify consistency between physical files on disk and records in the `TaskAttachment` table.

### Projects Service: MCP Server and CRM Integrations

1. **Enabling the MCP Server:**
   - Set `PROJECTS_MCP_ENABLED=true` in `.env` to activate the Streamable HTTP endpoint (`POST /mcp` and `/api/v1/projects/mcp`).
   - When disabled (`false`), all MCP endpoints immediately return `503 MCP_DISABLED`.
2. **ServicePrincipal Credentials (`sp_*`):**
   - Service credentials are generated via `IntegrationService.issueCredential(principalId)`.
   - Secret keys follow the format `sp_<prefix>_<secret>` and are stored in the database exclusively as SHA-256 hashes.
   - Grants (`IntegrationGrant`) dictate which tools (`allowedTools`) and whether sharing (`canShare`) are permitted per workspace.
3. **CRM Integration Headers:**
   - Authenticated runtimes (`evo-ai-processor-community` / `evo-bot-runtime`) inject confidential headers (`X-CRM-Instance-ID`, `X-CRM-Contact-ID`, `X-CRM-Conversation-ID`).
   - Resolution strictly obeys DP14: ambiguous or missing links will return `AMBIGUOUS` or `NOT_FOUND` and will never write to the database.

### The Core service image

In development, `evo-core` pulls the public image
`evoapicloud/evo-ai-core-service-community:latest` from Docker Hub — the same
image used by `swarm`. No local Go build is required.

To develop the Core locally instead, swap the `image:` line for a `build:`
against `./evo-ai-core-service-community` (a separate community Go module file —
e.g. `go.community.mod`, selected via `-modfile` — is needed because the default
`go.mod` references the enterprise licensing sibling, which only
exists in enterprise checkouts).

## Production (Docker Swarm)

The Swarm stack (`docker-compose.swarm.yaml`) uses **inline** values — it does
**not** read a `.env` file. `.env.swarm.example` is a reference checklist only.

1. Edit `docker-compose.swarm.yaml` directly: replace `SUBDOMAIN_API` /
   `SUBDOMAIN_FRONTEND` with your domains, fill every empty secret (using the
   **same** value everywhere each secret appears), set the Postgres password,
   and SMTP/S3 if used.
2. Create the external network/volumes and a pgvector Postgres reachable as
   host `pgvector` on the `evonet` network (full list is in the file header).
3. Deploy:

   ```bash
   docker stack deploy -c docker-compose.swarm.yaml evo_crm
   ```

The nginx gateway routes all backend services by URL path; its upstream
defaults are documented in [`nginx/README.md`](../nginx/README.md).

## Useful commands

```bash
make status   # service status
make logs     # tail all logs (make logs SERVICE=evo-crm to filter)
make stop     # stop everything
make start    # start everything
make clean    # remove all data volumes and start fresh
```
