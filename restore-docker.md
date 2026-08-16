[[reimaging-guide#Phase 12 — Restore Apps|← Back to Mac Reimaging Guide]]

# Restore Docker

**Last updated:** 2026-08-05

Restore Docker Desktop, resource tuning, registry credentials, and the local development container fleet on the reimaged Mac — Redis, RabbitMQ, Elasticsearch (+ Kibana), and MarkLogic (single-node with ml-gradle deployment). This runbook is the dedicated Phase 12 Docker handoff that [[restore-apps|restore-apps.md]] hands to; the companion script `bin/restore-docker.sh` writes a per-run plan-note that surveys the available pre-image sources, checks whether Docker Desktop and the daemon are up on the reimaged Mac, and provides the sign-off checklist.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Generate the Docker Plan-Note|Step 1 — Generate the Docker Plan-Note]]
    - [[#Step 2 — Install Docker Desktop|Step 2 — Install Docker Desktop]]
    - [[#Step 3 — Apply Resource Settings|Step 3 — Apply Resource Settings]]
    - [[#Step 4 — Validate the Docker CLI|Step 4 — Validate the Docker CLI]]
    - [[#Step 5 — Restore Registry Credentials|Step 5 — Restore Registry Credentials]]
    - [[#Step 6 — Restart Redis|Step 6 — Restart Redis]]
    - [[#Step 7 — Restart RabbitMQ|Step 7 — Restart RabbitMQ]]
    - [[#Step 8 — Restart Elasticsearch and Kibana|Step 8 — Restart Elasticsearch and Kibana]]
    - [[#Step 9 — Restart MarkLogic Single-Node|Step 9 — Restart MarkLogic Single-Node]]
    - [[#Step 10 — Deploy MarkLogic Security and Application|Step 10 — Deploy MarkLogic Security and Application]]
    - [[#Step 11 — Close the Plan-Note Sign-Off|Step 11 — Close the Plan-Note Sign-Off]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#MarkLogic Multi-Node Cluster Reference|MarkLogic Multi-Node Cluster Reference]]
    - [[#Container Quick Reference|Container Quick Reference]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves · `[!info] Return` how to get back after an out-of-sequence detour.

---

## Purpose

Bring Docker Desktop and the local development container fleet back to a working state after the reimage without carrying forward stale registry credentials, stale image cache pressure, or half-initialised MarkLogic volumes. That means installing Docker Desktop from the approved channel, restoring the small set of resource settings that actually affect Mac stability (CPU, Memory, File sharing), restoring the encrypted `~/.docker/config.json` from the DMG rather than typing tokens by hand, restarting the low-touch containers first (Redis, RabbitMQ) so the fast wins are visible before the slow ones, and then reinitialising the stateful services (Elasticsearch, MarkLogic) from their project compose files.

This runbook owns:

```text
generating the Docker-specific restore plan-note and sign-off checklist
installing Docker Desktop from the approved channel
Docker Desktop resource settings (CPUs, Memory, Swap, Disk image, File sharing, Kubernetes off)
Docker CLI smoke validation (docker version, docker info, docker system df)
restoring ~/.docker/config.json from the encrypted DMG and validating docker login per registry
restarting Redis, RabbitMQ, Elasticsearch (+ Kibana), and MarkLogic
MarkLogic single-node deploy via ml-gradle (mlDeploySecurity, mlDeploy, mlLoadModules)
```

It does not own:

```text
generic app restore (Office, Chrome, Obsidian, Postman, VS Code, Raycast) — restore-apps.md
IntelliJ IDE state and HTTP Client env files — restore-intellij.md
JDK/Node/Gradle runtime install — Phase 10A (restore-runtime)
secret restore beyond ~/.docker/config.json (SSH, GPG, certs, licenses) — Phase 10B (restore-access)
repository re-clone (needed for the MarkLogic compose files and Gradle deploys) — Phase 11B (restore-repos)
MarkLogic multi-node cluster steady-state operation — noted here as reference only; see the carrier-services-storage project README
```

This runbook can be rerun. Regenerating the plan-note produces a fresh timestamped file under `reimaged-system/restore-notes/`; container `docker start` operations are idempotent, and compose deploys are structured to re-run cleanly against an existing volume.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. Docker restore has three overlapping concerns that each need a different treatment: the Docker Desktop application itself and its resource settings; per-registry authentication material; and the local container fleet with its data volumes.

Docker Desktop is treated as a fresh install. Backing up and overlaying the full internal state (`~/Library/Containers/com.docker.docker/`) is intentionally avoided — Docker Desktop reinitialises cleanly on first run, and dragging forward the prior VM disk image consumes disk without benefit. The only pre-image settings that get restored are the operator-facing Resources knobs (CPUs, Memory, Swap, Disk image size, File sharing), and those come from the performance-audit notes rather than a blind file copy.

Registry credentials are the one piece of Docker state that must be preserved carefully. `~/.docker/config.json` is captured pre-image into `secrets-encrypted/docker/` because it may embed base-64 encoded credentials for private registries; on restore, it lands from the encrypted DMG, and `docker login` is used as a confirmation rather than a first-time interactive credential entry.

The container fleet restarts in an order that trades cheap-and-fast for slow-and-stateful. Redis and RabbitMQ are single-container recipes that come back in seconds; Elasticsearch and Kibana are project-driven compose stacks with security-mode nuances (the `elastic` user password must match `.env` or the container has to be recreated); MarkLogic is the heaviest and requires a 30–60 second first-boot cluster-initialisation window plus a two-step Gradle deploy (security first, then the full app). Starting slow-and-stateful last means the fast containers are already validated when MarkLogic startup issues show up, so the operator knows where to look.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later steps refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/restore-docker.sh   # entrypoint
```

Artifact locations:

```text
$REIMAGE_ARTIFACT_ROOT/app-settings-backup/docker/
$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-docker-plan-*.md
```

Directory shape this runbook reads (the full layout lives in [[master-directory-reference|Master Directory Reference]]):

```text
$REIMAGE_ARTIFACT_ROOT/
├── ...
├── app-settings-backup/
│   └── docker/
│       ├── compose-projects.txt
│       ├── container-inventory.txt
│       ├── contexts/
│       ├── daemon.json
│       ├── image-inventory.txt
│       └── settings-store.json
├── ...
├── reimaged-system/
│   └── restore-notes/
│       └── restore-docker-plan-YYYYMMDD-HHMMSS.md
├── ...
└── secrets-encrypted/
    └── docker/
        └── config.json
```

Project checkouts (post Phase 11B) referenced by the compose steps:

```text
<workspace>/carrier-services-storage/src/main/docker/elastic/
<workspace>/carrier-services-storage/src/main/docker/marklogic/
```

### Environment Variables

The `reimage.env` values this runbook depends on. Resolved and written during [[prepare-artifact-root|prepare-artifact-root.md]].

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Mounted external artifact volume that holds every pre-image backup and every post-image record. Required for `bin/restore-docker.sh`. |
| `FRACTOGENESIS_HOME` | Local checkout of `fractogenesis-toolkit`. Set by the shell session; the runbook assumes you are at this directory. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- Phases 8, 9, 10A, 10B, 11A, and 9B are complete. In particular, the JDK required for `./gradlew` is installed (Phase 10A), the encrypted secrets DMG is available (Phase 10B), and `carrier-services-storage` (or the equivalent project holding the Elasticsearch and MarkLogic compose files) has been re-cloned (Phase 11B).
- The external artifact volume is mounted and `$REIMAGE_ARTIFACT_ROOT` resolves; the pre-image `app-settings-backup/docker/` subtree is reachable.
- You have generated the Phase 12 umbrella plan-note via [[restore-apps|restore-apps.md]] Step 1.

> [!bug] Troubleshooting
> If `$REIMAGE_ARTIFACT_ROOT` is unset or unreachable, either mount the artifact volume and re-source `reimage.env`, or pass `--artifact-root PATH` explicitly to `bin/restore-docker.sh`.

### Confirm Your Intent

- Are you restoring every container the pre-image system ran, or only the ones you actively need this week? The pre-image inventory records what was installed, not what still matters — reinstall is a chance to prune.
- Do you want persisted MarkLogic and Elasticsearch data volumes carried forward if they exist in the Docker VM, or a clean slate (`docker compose down -v`)? A clean slate means re-running `mlDeploySecurity` and `mlDeploy`.
- Do you want the plan-note under the default `reimaged-system/restore-notes/`, or a scratch location (`--output-root ~/Desktop/…`)? Phase 14 `reimaged-system-checks.md` reads from the default path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Each numbered step corresponds to a row (or row group) in the sign-off checklist emitted by `bin/restore-docker.sh`.

### Step 1 — Generate the Docker Plan-Note

Emit the plan-note that surveys pre-image Docker sources, checks Docker Desktop and daemon state on the reimaged Mac, and provides the sign-off checklist:

```bash
./bin/restore-docker.sh --open
```

The generated file lives under:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restore-notes/restore-docker-plan-YYYYMMDD-HHMMSS.md
```

Confirm the **Local Docker State** table before continuing — if `Docker Desktop app` is `INSTALLED` and `Docker daemon reachable` is `REACHABLE`, Step 2 collapses to "confirm settings" rather than a full install.

### Step 2 — Install Docker Desktop

Install Docker Desktop from the approved source:

```text
Corporate Mac:  Self Service / Company Portal (if available)
Apple Silicon:  Docker Desktop for Mac (Apple Silicon) — https://www.docker.com/products/docker-desktop/
Intel:          Docker Desktop for Mac (Intel) — same page
```

Launch Docker Desktop and complete onboarding. Confirm the daemon is running:

```bash
docker version
docker context ls
docker info
docker system df
```

> [!note]
> When Self Service / Company Portal offers Docker Desktop, prefer it over the docker.com installer to avoid managed-app conflicts.

### Step 3 — Apply Resource Settings

Restore resource settings from the pre-image performance-audit / system-inventory notes rather than copying Docker Desktop internal state blindly.

**Settings → Resources** — target values:

| Setting | Typical dev value | Notes |
|---|---|---|
| CPUs | 4–6 | Reduce if Office / Outlook is sluggish. |
| Memory | 8–12 GB | MarkLogic alone needs ≥4 GB. |
| Swap | 1–2 GB |  |
| Disk image size | 64–100 GB | Increase only if `docker system df` shows pressure. |
| Disk image location | `~/Library/Containers/com.docker.docker/…` | Default is fine; change only for space reasons. |
| File sharing | Add project roots, e.g. `~/Development` | Required for bind mounts. |
| Kubernetes | Disabled unless actively needed | Saves ~1 GB RAM. |

Restart Docker Desktop after changes, then re-run `docker info` to confirm the values took effect.

### Step 4 — Validate the Docker CLI

```bash
docker run --rm hello-world
docker ps -a
docker images
docker network ls
docker volume ls
```

The `hello-world` pull is the smoke test for network reachability + registry auth-in-the-clear.

### Step 5 — Restore Registry Credentials

Mount the encrypted secrets area (or the consolidated `all-secrets-*.dmg`) and restore `~/.docker/config.json`:

```bash
mkdir -p ~/.docker
[[ -f "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json" ]] \
  && cp "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/docker/config.json" ~/.docker/config.json
chmod 600 ~/.docker/config.json 2>/dev/null || true
```

Confirm each private registry the pre-image config referenced:

```bash
docker login <registry-host>
```

> [!warning] Pitfall
> Copying `config.json` from the plain-text `app-settings-backup/` path is a bug even if the file happens to sit there — that path is not encrypted and this file may embed credentials. Always take it from `secrets-encrypted/docker/`.

### Step 6 — Restart Redis

Redis is a lightweight standalone container for caching and session storage.

Start (one-time or after a full reimage):

```bash
docker run -d \
  --name redis \
  -p 6379:6379 \
  --restart unless-stopped \
  redis:7-alpine
```

Restart an existing container (when the Docker VM preserved state):

```bash
docker ps -a --filter name=redis
docker start redis
```

Verify:

```bash
docker ps --filter name=redis
docker exec -it redis redis-cli ping
# expected: PONG
```

Optional local client via Homebrew:

```bash
brew install redis   # installs CLI only, no daemon
redis-cli -h localhost -p 6379 ping
```

### Step 7 — Restart RabbitMQ

RabbitMQ is the message broker. The `3.12-management` image bundles the web management UI.

Start:

```bash
docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  --restart unless-stopped \
  rabbitmq:3.12-management
```

Restart existing:

```bash
docker ps -a --filter name=rabbitmq
docker start rabbitmq
```

Verify (wait ~15 s for RabbitMQ to finish booting):

```bash
docker ps --filter name=rabbitmq
curl -s -o /dev/null -w "%{http_code}" http://localhost:15672
# expected: 200
```

Management UI: [http://localhost:15672](http://localhost:15672) — default credentials `guest` / `guest` for local dev only.

| Port | Purpose |
|---|---|
| `5672` | AMQP (application connections) |
| `15672` | Management UI / HTTP API |

### Step 8 — Restart Elasticsearch and Kibana

Project location: `src/main/docker/elastic/` in `carrier-services-storage`.

The project ships two compose files:

| File | What it starts |
|---|---|
| `docker-compose.yml` | Elasticsearch only (`ES_JAVA_OPTS` capped, `restart: always`). |
| `docker-compose-es-kibana.yml` | Elasticsearch + Kibana (no `restart: always`). |

Configuration is driven by `.env` in the same directory:

```bash
# .env (carrier-services-storage/src/main/docker/elastic/.env)
ELASTIC_PASSWORD=fake-test      # change for any non-local use
KIBANA_PASSWORD=fake-test
STACK_VERSION=8.13.0
ES_PORT=9200
KIBANA_PORT=5601
```

> [!warning] Pitfall
> Update the passwords in `.env` before running in any shared or non-ephemeral environment. The default `fake-test` credentials are for local development only.

Elasticsearch only:

```bash
cd <workspace>/carrier-services-storage/src/main/docker/elastic/
docker compose -f docker-compose.yml up -d
# wait ~20s, then:
curl -s -o /dev/null -w "%{http_code}" \
  -u elastic:fake-test http://localhost:9200
# expected: 200
```

Generate a local API key and write it to `gradle-elastic-local.properties`:

```bash
bash start-local-docker.sh
```

Elasticsearch + Kibana:

```bash
bash start-local-docker-with-kibana.sh
```

Kibana UI: [http://localhost:5601](http://localhost:5601) — credentials `elastic` / `fake-test` for local dev only.

Stop:

```bash
docker compose -f docker-compose-es-kibana.yml down
# or, Elasticsearch only:
docker compose -f docker-compose.yml down
```

| Port | Service |
|---|---|
| `9200` | Elasticsearch HTTP API |
| `5601` | Kibana UI |

Key Elasticsearch settings for reference:

| Setting | Value |
|---|---|
| `discovery.type` | `single-node` (no cluster formation) |
| `xpack.security.enabled` | `true` (authentication required) |
| `xpack.security.http.ssl` | `false` (plain HTTP for local dev) |
| `ES_JAVA_OPTS` | `-Xms512m -Xmx512m` (in `docker-compose.yml`) |

### Step 9 — Restart MarkLogic Single-Node

Project location: `src/main/docker/marklogic/` in `carrier-services-storage`. The single-node compose file is `docker-compose.marklogic.yml`, which pulls `progressofficial/marklogic-db` directly (no custom build for local dev).

Populate the admin credentials (default to `admin` / `admin` for local dev; do not commit real credentials):

```bash
cd <workspace>/carrier-services-storage/src/main/docker/marklogic/
cat secrets/mldb_admin_username.txt
cat secrets/mldb_admin_password.txt
```

Start the container:

```bash
docker compose -f docker-compose.marklogic.yml up -d
```

`MARKLOGIC_INIT=true` in the compose file triggers first-boot cluster initialisation. Wait ~30–60 seconds for MarkLogic to finish initialising, then verify:

```bash
# Health endpoint (HTTP 200 = ready)
curl -s -o /dev/null -w "%{http_code}" http://localhost:7997
# expected: 200

# Admin UI
open http://localhost:8001
# Login: admin / admin

# Management API
curl -s -o /dev/null -w "%{http_code}" \
  --anyauth -u admin:admin \
  http://localhost:8002/manage/v2
# expected: 200
```

Run the sanity-check script before any Gradle deploy:

```bash
bash scripts/ml-setup-sanity-checks.sh
```

Non-zero exit means one of `:7997`, `:8001`, `:8002/manage/v2` is failing — fix that before Step 10.

### Step 10 — Deploy MarkLogic Security and Application

Deploy security resources first, from the **project root** (`carrier-services-storage/`):

```bash
./gradlew -PenvironmentName=local mlDeploySecurity
```

This creates the roles and users below (tokens resolved from `gradle.properties`).

Roles created:

| Role | Inherits | Purpose |
|---|---|---|
| `carrier-services-storage-admin-role` | `rest-admin`, `manage-admin`, `tde-admin`, `qconsole-user` | Full deployment / module-loading role. |
| `carrier-services-storage-reader-role` | `rest-reader` | Read-only REST API consumer. |
| `carrier-services-storage-writer-role` | reader-role, `rest-writer`, `qconsole-user` | Read/write REST API consumer. |
| `carrier-services-storage-power-role` | writer-role, `tde-admin`, `tde-view` | Elevated role with temporal document management. |
| `carrier-services-storage-application-permission-role` | _(none)_ | Default document permission anchor for writer. |
| `carrier-services-storage-power-permission-role` | _(none)_ | Default document permission anchor for power user. |

Users created:

| User | Role(s) | Purpose |
|---|---|---|
| `carrier-services-storage-admin` | `admin` | Deployment / REST admin (used by Gradle). |
| `carrier-services-storage-reader` | reader-role | Read-only API consumer. |
| `carrier-services-storage-writer` | writer-role + application-permission-role | Read/write API consumer. |
| `carrier-services-storage-power-user` | power-role + power-permission-role | Elevated / temporal document user. |

> [!note]
> The `mlSecurityUsername=admin` / `mlSecurityPassword=admin` values in `gradle.properties` must match the admin credentials set in the Docker secrets files.

Then deploy the full application:

```bash
./gradlew -PenvironmentName=local mlDeploy
```

This creates:

- `carrier-services-storage-content` database — full-text search indexes, range path indexes on `/timestamp` and `/input/timestamp`, metadata fields (`referrer`, `clientName`, `contentType`, `division`).
- `carrier-services-storage-modules` database — server-side modules storage.
- `carrier-services-storage-schemas` database — TDE and XML schemas.
- `carrier-services-storage-triggers` database — trigger definitions.
- `carrier-services-storage` HTTP app server on port `8042` — REST API rewriter, digest + basic auth.

Verify the app server:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  --anyauth -u carrier-services-storage-admin:carrier-services-storage-admin-password \
  http://localhost:8042
# expected: 200 or 404 (404 is fine — server is up, no root handler)
```

Incremental module reload:

```bash
./gradlew -PenvironmentName=local mlLoadModules
```

Tear down when done experimenting:

```bash
cd <workspace>/carrier-services-storage/src/main/docker/marklogic/
docker compose -f docker-compose.marklogic.yml down

# Remove the persisted data volume too (full clean slate):
docker compose -f docker-compose.marklogic.yml down -v
```

> [!warning] Pitfall
> `down -v` removes the persisted MarkLogic data volume. The next `up` re-initialises from scratch and you will need to re-run `mlDeploySecurity` and `mlDeploy`. Use it deliberately.

### Step 11 — Close the Plan-Note Sign-Off

Reopen the plan-note and flip every completed row from `TODO` to `Done`. Leave any row still open with a short note explaining why (e.g. `MarkLogic deferred — not needed this week`). Phase 14 `reimaged-system-checks.md` reads these plan-notes and will flag outstanding rows.

Return to [[restore-apps|restore-apps.md]] Step 9 and mark the `Docker dedicated restore completed` row in the umbrella plan-note before continuing to Step 10 of that runbook.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The scripts do X; these judgment calls stay with you.

| Decision | Why it stays with you |
|---|---|
| Whether to preserve the pre-image Docker VM disk image or start clean | Preserving state saves re-pulls and re-inits at the cost of dragging forward accumulated cache pressure. Clean-slate is safer after any Docker Desktop major version bump. |
| Which containers to restart at all | The pre-image inventory records what was running, not what still matters. Reinstall is a chance to prune. |
| Whether to keep persisted MarkLogic / Elasticsearch volumes | Preserved volumes skip re-init but tie you to the pre-image data shape. `down -v` gives a clean baseline at the cost of `mlDeploySecurity` + `mlDeploy` again. |
| Whether to update `.env` credentials on Elasticsearch / Kibana | The `fake-test` defaults are appropriate for a local-only, ephemeral environment and inappropriate anywhere else. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

### Docker daemon not running

```bash
open -a Docker   # launch Docker Desktop
# wait ~10 s, then:
docker info
```

### Docker containers fail after restore

Check:

```bash
docker context ls
docker info
docker system df
```

Confirm Docker file sharing includes the project directories the containers bind-mount.

### Port conflict

```bash
lsof -i :9200                                                                     # example: Elasticsearch
python3 <workspace>/carrier-services-storage/src/main/docker/marklogic/scripts/port-checker.py   # MarkLogic cluster ports
```

### MarkLogic container exits immediately

```bash
docker logs marklogic-server
```

Common causes:

- Memory limit too low — increase Docker Desktop memory to ≥4 GB.
- Stale lock files from a previous unclean shutdown — `docker compose down -v` to remove the volume and start clean.

### MarkLogic `mlDeploySecurity` fails with 401

Credentials mismatch. Confirm:

1. `mlSecurityUsername=admin` in `gradle.properties`.
2. `secrets/mldb_admin_username.txt` contains the same username.
3. `secrets/mldb_admin_password.txt` contains the matching password.
4. Run `bash scripts/ml-setup-sanity-checks.sh` to confirm auth works before retrying Gradle.

### Elasticsearch returns 401

```bash
# verify the password matches .env
curl -u elastic:fake-test http://localhost:9200/_cluster/health?pretty
```

If `.env` was changed after the container was created, the password in the running container will not update. Recreate:

```bash
docker compose -f docker-compose.yml down -v
docker compose -f docker-compose.yml up -d
```

### Kibana `Status: Red` after restart

Kibana's `kibana_system` user password must be reset after the Elasticsearch container is recreated:

```bash
bash start-local-docker-with-kibana.sh
```

This resets the password and restarts Kibana automatically.

### RabbitMQ management UI unreachable

```bash
docker logs rabbitmq | tail -30
```

RabbitMQ takes 10–20 seconds to boot. If the container is running but the UI is still unreachable after 30 seconds, restart:

```bash
docker restart rabbitmq
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

### MarkLogic Multi-Node Cluster Reference

For a 3-node cluster with nginx load balancing, use the cluster compose file:

```bash
cd <workspace>/carrier-services-storage/src/main/docker/marklogic/
python3 scripts/port-checker.py                              # confirm cluster ports are free
docker compose -f docker-compose.marklogic-cluster.yml up -d
```

The cluster file builds a custom image from the local `Dockerfile` and starts:

- `node1_bootstrap` (bootstrap, ports `71xx`)
- `node2` (joiner, depends on `node1`, ports `72xx`)
- `node3` (joiner, depends on `node1`, ports `73xx`)
- `marklogic-proxy` (nginx, ports `8000–8002`, `8042`)

After the cluster is healthy, deploy with the same Gradle commands as single-node (`mlHost=localhost`; the proxy forwards to the cluster). Full cluster documentation lives in the project README: `carrier-services-storage/src/main/docker/marklogic/README.md`.

### Container Quick Reference

| Container | Image | Ports | Start command |
|---|---|---|---|
| Redis | `redis:7-alpine` | `6379` | `docker start redis` |
| RabbitMQ | `rabbitmq:3.12-management` | `5672`, `15672` | `docker start rabbitmq` |
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:8.13.0` | `9200` | `docker compose -f docker-compose.yml up -d` |
| Kibana | `docker.elastic.co/kibana/kibana:8.13.0` | `5601` | included in `docker-compose-es-kibana.yml` |
| MarkLogic | `progressofficial/marklogic-db` | `8000–8002`, `8042`, `7997` | `docker compose -f docker-compose.marklogic.yml up -d` |

After a reimage, when volumes were preserved:

```bash
docker start redis
docker start rabbitmq
# Elasticsearch / Kibana and MarkLogic: re-run compose up from project directories
```

[[#Table of Contents|⬆ Back to Table of Contents]]
