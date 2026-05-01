# Running The-Board locally with `run.ps1`

`run.ps1` is the local development runner. It packages the contents of this folder into a Docker image, starts the app alongside a Postgres container, and waits until both are actually responding before handing control back to you.

For the production IIS-fronted deploy, use `install.ps1` and see [`DEPLOY.md`](./DEPLOY.md). This document covers the local dev workflow only.

---

## What it does

1. Detects `docker compose` (v2) or legacy `docker-compose` and fails fast if Docker Desktop isn't running.
2. Warns on host port conflicts (3001 / 5432) before starting.
3. Builds the app image from this folder using the existing `Dockerfile` (multi-stage: React client + Node server).
4. Starts the stack defined in `docker-compose.yml`:
   - **app** (Node) → `http://localhost:3001`
   - **db** (Postgres 16) → `localhost:5432`, schema auto-loaded from `models/*.sql`
5. Polls `pg_isready` and the app URL until both are healthy (120 s timeout).
6. Prints URLs and follow-up commands.

Postgres data lives in the named Docker volume `db-data`, which is **preserved** across normal restarts and rebuilds. Only `fresh` destroys it.

### Existing-database detection

Every `up` and `rebuild` checks for the project's Postgres volume before starting:

- **If the volume exists**, the script logs `Existing database volume detected - preserving data.` and starts Postgres against it. The init scripts in `models/*.sql` are skipped — Postgres only runs them when the data directory is empty, so your tickets, technicians, and reports stay intact.
- **If the volume does not exist**, the script logs `No existing database volume found - Postgres will initialize from models/*.sql.` and seeds a fresh database.

You never have to choose — the script always uses an existing database when it finds one. The only way to overwrite it is `.\run.ps1 fresh`, which prints the exact volume name being deleted before asking for the typed confirmation phrase.

---

## Prerequisites

- Windows 10 / 11 (or Windows Server 2019+)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running, with the WSL2 backend
- PowerShell 5.1+ (built into Windows) or PowerShell 7+
- Ports `3001` and `5432` free on the host

You do **not** need to be Administrator to run `run.ps1`.

---

## First-time run

Open PowerShell, `cd` into the project root (the folder with `docker-compose.yml`), and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

On first run this will:
- Pull the `postgres:16-alpine` and `node:20-alpine` base images (~few hundred MB, one-time).
- Build the React client and bake it into the app image.
- Initialize the Postgres database from `models/schema.sql`, `models/triggers.sql`, and `models/seed.sql`.

When it finishes you'll see:

```
===== The-Board is up =====
  App:        http://localhost:3001
  Board UI:   http://localhost:3001/board
  Postgres:   localhost:5432  (user=postgres db=board)
```

Open <http://localhost:3001/board> in a browser to confirm.

---

## Updating after code changes

Edit code, then re-run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

Docker's layer cache keeps this fast — unchanged steps (e.g. `npm install` if `package.json` didn't change) are reused. The app container is recreated with the new image; the db container and its data are left alone.

---

## Commands

All commands are run from the project root.

| Command | What it does |
|---|---|
| `.\run.ps1` *(default)* | Build (cached) + start + wait for health. Use this every time you make changes. |
| `.\run.ps1 up` | Same as above. |
| `.\run.ps1 rebuild` | `--no-cache` rebuild, then start. Use if the build cache gets stale. |
| `.\run.ps1 fresh` | **DESTRUCTIVE.** Wipe DB volume, rebuild, restart. Re-seeds from `models/*.sql`. Requires typed confirmation phrase. |
| `.\run.ps1 logs` | Tail logs for both services. `Ctrl+C` to stop tailing. |
| `.\run.ps1 status` | Show container state and health (`docker compose ps`). |
| `.\run.ps1 stop` | Stop containers. Data preserved. |
| `.\run.ps1 down` | Stop and remove containers. Volume preserved. |
| `.\run.ps1 shell` | Open a shell inside the running app container. |
| `.\run.ps1 psql` | Open `psql` against the running db container. |
| `.\run.ps1 help` | Print full help via `Get-Help`. |

---

## Parameters

| Parameter | Default | Purpose |
|---|---|---|
| `-AppPort` | `3001` | Host port for the Node container. Must match `docker-compose.yml`. |
| `-DbPort` | `5432` | Host port for Postgres. |
| `-HealthTimeoutSeconds` | `120` | How long to wait for the stack to become healthy before failing. |
| `-Yes` | *(off)* | Reserved for future non-destructive prompts. **Does not** bypass `fresh` confirmation. |

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1 up -HealthTimeoutSeconds 240
```

---

## The `fresh` command (destructive)

`fresh` exists for the case where you want a clean database — for example, after editing `models/schema.sql` or `models/seed.sql`, since Postgres only runs the init scripts on an empty data directory.

It will:

1. Print a danger banner.
2. Require you to type the phrase **`This will delete my database`** exactly (case-sensitive).
3. Run `docker compose down -v` (removes containers **and** the `db-data` volume).
4. Rebuild the image with `--no-cache`.
5. Start the stack and wait for health.

There is **no `-Yes` bypass** for this command — the confirmation phrase is mandatory every time. Anything other than the exact phrase aborts with no changes made.

---

## Troubleshooting

**"Docker daemon not reachable"**
Start Docker Desktop and wait until the tray icon says it's running, then retry.

**"Port 3001 is already in use"**
Either a previous `run.ps1` run is still up (`.\run.ps1 status` to check, `.\run.ps1 down` to clean up), or another process is on the port. Find it with `Get-NetTCPConnection -LocalPort 3001`.

**App came up but `/board` shows a 404 or blank page**
The client build failed silently. Re-run with `.\run.ps1 rebuild` to force a clean build, then check `.\run.ps1 logs` for the error.

**Schema changes aren't showing up**
Postgres only runs the init SQL scripts on a *fresh* data directory. Editing `models/schema.sql` and re-running `.\run.ps1` will **not** apply the changes — you need `.\run.ps1 fresh` (which wipes the DB).

**Health check timed out**
The script will print the last 40 log lines automatically. Check those, then `.\run.ps1 logs` for the full stream.

**Execution policy error**
Always invoke as `powershell -ExecutionPolicy Bypass -File .\run.ps1 ...`. The `-ExecutionPolicy Bypass` flag avoids needing to change your system policy permanently.

---

## How this differs from `install.ps1`

| | `run.ps1` (this doc) | `install.ps1` ([DEPLOY.md](./DEPLOY.md)) |
|---|---|---|
| Purpose | Local dev / testing | Production deploy on a Windows server |
| Admin required | No | Yes |
| IIS / TLS | Not used | Required (TLS termination + ARR reverse proxy) |
| Exposes app to | `localhost` only | The internet, via IIS on 443 |
| When to use | Daily development | One-time server setup + redeploys |
