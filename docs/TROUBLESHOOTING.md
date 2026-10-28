# Evo CRM Community — Troubleshooting

Common issues when bringing up the stack from a clean checkout, and how to fix
them. See [SETUP-GUIDE.md](./SETUP-GUIDE.md) for the full setup flow.

## The UI loads but every API/login call fails with "connection refused"

The frontend has the wrong API URLs. The `VITE_*` variables are read by the
browser, so they must point at the **host** ports published by
`docker-compose.yml`:

```
VITE_API_URL=http://localhost:3010
VITE_AUTH_API_URL=http://localhost:3011
VITE_WS_URL=http://localhost:3010
VITE_EVOAI_API_URL=http://localhost:5565
VITE_AGENT_PROCESSOR_URL=http://localhost:8011
```

The frontend image substitutes these into the built assets at **container
start** (no rebuild needed). After changing a value in `.env`, just recreate
the container so the entrypoint re-runs:

```bash
docker compose up -d --force-recreate evo-frontend
```

## WebSocket / live updates don't work

Make sure `VITE_WS_URL` is set (it must point at the CRM host port, `:3010` in
dev). If it's missing, the frontend falls back to the wrong port and the
WebSocket connection never opens. Recreate the frontend container after setting
it (`docker compose up -d --force-recreate evo-frontend`).

## `docker compose config` prints "variable is not set" warnings

A secret in `.env` contains an unescaped `$`. In `.env`, `$` starts a variable
reference. Escape it by doubling it (`$$`) — the shared secrets in
`.env.example` are already escaped this way.

## `evo-core` never becomes healthy

The dev stack pulls `evoapicloud/evo-ai-core-service-community:latest` from
Docker Hub. Confirm the image pulled and check its logs:

```bash
docker compose pull evo-core
docker compose logs evo-core
```

The Core needs Postgres reachable as host `postgres`; if it crashes on boot,
verify the `postgres` service is healthy (`docker compose ps`).

## Login wizard doesn't appear / "account already exists"

There is no pre-seeded login. The first user is created at
`http://localhost:5173/setup`.

> ⚠️ Do **not** run `make seed` to "fix" this on an existing install — it runs
> `db:schema:load`, which **drops and recreates every table** and wipes all
> your data. `make seed` is only for a fresh database (it's part of
> `make setup`).

If the wizard genuinely never ran (brand-new, empty database), seeding once is
fine:

```bash
make seed
```

If the database is in a bad state and you're OK losing all data, wipe and start
fresh:

```bash
make clean && make setup
```

## Ports already in use

The dev stack publishes non-default host ports to avoid collisions: CRM `3010`,
Auth `3011`, Core `5565`, Processor `8011`, Bot Runtime `8092`, Frontend
`5173`, Mailhog `18025`, plus Postgres `55434`, Redis `56381`. If one is taken,
stop the conflicting process or change the host side of the `ports:` mapping in
`docker-compose.yml`.

## Swarm: every request returns 502 Bad Gateway

The nginx gateway can't resolve the backend service names. The Swarm stack uses
`evocrm_`-prefixed names and sets the `*_UPSTREAM` env vars accordingly — if you
renamed services, update those vars on `evocrm_gateway`. See
[`nginx/README.md`](../nginx/README.md).

## Swarm: my `.env` changes have no effect

`docker-compose.swarm.yaml` does **not** read a `.env` file — all values are
inline. Edit the YAML directly. `.env.swarm.example` is only a reference
checklist of the values you need to fill in.

## Projects Service: `401 Unauthorized` or token errors

1. **JWT secret mismatch:** Ensure `JWT_SECRET_KEY` in `evo-projects-service/.env` (or environment) matches `DOORKEEPER_JWT_SECRET_KEY` in the auth service.
2. **Missing Algorithm/Issuer:** The auth service signs tokens with `HS256` and issuer `evo-auth-service`. If these claims differ, token verification fails.
3. **Revocation / Inactive User:** If a user was suspended or logged out, `AuthClient` checks the live revocation status against `evo-auth-service` and rejects the request.

## Projects Service: `evo-projects-migrate` fails on startup

1. **Role permissions:** Schema migrations require DDL permissions. In production, `DATABASE_URL` for `evo-projects-migrate` must use the `projects_migrator` user.
2. **Database connectivity:** Ensure PostgreSQL is healthy and accepting connections on the specified port.
3. **Pending migrations:** Run `npx prisma migrate status` inside `evo-projects-service` to inspect unapplied migrations.

## Projects Service: Member shows "Reconciliação Pendente" badge

Legacy records created prior to Phase 1 may contain temporary emails or non-canonical IDs. An administrator should run the reconciliation script:
```bash
npx tsx scripts/reconcile-members/reconcile.ts --apply
```
If the user cannot be resolved in the Auth directory, verify that the user is registered and confirmed in `evo-auth-service`.

## Projects Service: `409 Conflict` (VERSION_CONFLICT) on Task Update

The Projects service implements Optimistic Concurrency Control (OCC) using monotonic task version numbers.
1. **Cause:** Another operator or process updated the task since your frontend loaded it (`expectedVersion !== currentVersion`).
2. **Resolution:** The frontend automatically captures this error, preserves your unsaved draft in memory, alerts the operator, and prompts you to refresh the latest state before reapplying your edits.

## Projects Service: Task Attachment Upload Fails (`413` or `400`)

1. **Size Limit Exceeded:** The application maximum file size is **20 MiB**. If you receive `413 Payload Too Large`, ensure the file is under 20 MiB and verify that the Nginx Gateway configuration includes `client_max_body_size 25M;` for `/api/v1/projects/tasks/[^/]+/attachments`.
2. **Executable or Unsafe Content (`400 Bad Request`):** Dangerous file extensions (`.exe`, `.sh`, `.php`, `.html`, `.svg`) and polyglot files containing script injections in their binary header are rejected by security design.
3. **Storage Directory Permissions:** Ensure the directory configured by `PROJECTS_STORAGE_DIR` (or `./.storage/attachments`) exists and is writable by the process.

## Projects Service: Client Cannot Unlock Public Share (PIN Lockout)

1. **Brute-Force Protection:** After 5 consecutive failed PIN attempts, the public link is locked with a lockout cooldown to prevent automated guessing.
2. **Resolution:** An internal operator must re-issue the public share from the task details modal ("Reemitir Link e PIN"), which generates a fresh URL token and a new 6-digit PIN.

## Projects Service: Column Reordering Fails with `403 Forbidden`

1. **Role Requirement:** Reordering workflow columns is an administrative operation restricted to operators with the `ADMIN` role in the respective workspace. Members with `MEMBER` or `VIEWER` roles cannot alter the column sequence.

## Projects Service: Tasks Missing from Gantt Timeline Canvas

1. **Temporal Fidelity (DP11 / U0):** The Gantt chart strictly renders tasks with valid declared dates.
2. **Unscheduled Tasks:** Tasks without both start date and due date are never assigned fake synthetic dates; they are listed in the collapsible "Tarefas sem planejamento ou datas definidas" drawer at the bottom of the Gantt view. Click any task to open its drawer and set its start and due dates.

## Projects Service: MCP Connection Returns `403 FORBIDDEN_ORIGIN` or `503 MCP_DISABLED`

1. **`503 MCP_DISABLED`:** Verify that `PROJECTS_MCP_ENABLED=true` is set in `evo-projects-service/.env`. When disabled, all MCP requests are rejected by containment hook.
2. **`403 FORBIDDEN_ORIGIN`:** Browsers and web-based IDEs sending an `Origin` header must match one of the comma-separated domains declared in `CORS_ORIGINS` (e.g. `http://localhost:5173`). Non-browser runtimes (bots, CLIs) should omit the `Origin` header.

## Projects Service: CRM Context Returns `AMBIGUOUS`

1. **Inviolable Invariant DP14:** If a CRM contact is mapped to more than one active workspace in the same CRM instance, the system returns `AMBIGUOUS` with the candidates count and refuses to perform write operations.
2. **Resolution:** A workspace administrator must review `WorkspaceContactLink` configurations at `GET /workspaces/:id/crm/contact-links` and prune obsolete links or route the conversation through an exclusive inbox route (`WorkspaceInboxRoute` with `isExclusive: true`).

