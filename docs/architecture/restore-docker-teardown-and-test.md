# Restore Docker — teardown, diagnostics and the test plan

**Status:** plan, not built. Nothing here has been applied to a runbook.
**Written:** 2026-09-02, while the owner was deciding how to test Phase 12.
**For:** `restore-apps.md` → `restore-docker.md`, when that phase is reached.

Everything here came out of one question — *"what is the best way to delete all
my containers and images so I can test the restore?"* — and the answer turned out
to depend on three things nobody had checked.

---

## Table of Contents

- [[#What the backup actually holds|What the backup actually holds]]
- [[#Three findings that change the test|Three findings that change the test]]
- [[#Before teardown — snapshot|Before teardown — snapshot]]
- [[#Graduated teardown|Graduated teardown]]
- [[#What to add to restore-docker.md|What to add to restore-docker.md]]
- [[#Open decision — which stack is the target|Open decision — which stack is the target]]

---

## What the backup actually holds

Two captures ran on 2026-08-16, 4.5 hours apart, and they disagree because Docker
Desktop was running for one and not the other.

| Artifact | Time | Docker daemon | Content |
|---|---|---|---|
| `app-settings-backup/docker/` | 16:42 | **up** | 8 images, 4 containers, 1 compose project, `daemon.json`, `settings-store.json`, `contexts/` |
| `system-inventory/…/12-docker.txt` | 21:16 | **down** | "Cannot connect to the Docker daemon" for images, containers, **volumes**, networks |

So the pre-image Docker state is *not* lost — it is in `app-settings-backup/`,
not in the system inventory where a reader would look first. What was never
captured anywhere is **volumes and networks**.

That costs less than it sounds. Nothing in this workflow backs up volume *data*
— `backup-apps.md` says so plainly: *"`Docker.raw`, image layers, and volumes are
intentionally not backed up."* A volume list would have said what to rebuild, not
let anything be restored. The loss is a checklist item, not a payload.

---

## Three findings that change the test

### 1. The compose file lives inside a repository

```text
NAME       STATUS        CONFIG FILES
elastic    running(1)    …/IdeaProjects/apicoe/carrier-services-storage/
                         src/main/docker/elastic/docker-compose.yml
```

`restore-docker.md` Step 8 cannot run until Phase 11B has cloned
`carrier-services-storage`. That is correct as the phases are ordered — 11B
before 12 — but it is **not stated in `restore-docker.md` Prerequisites**, and it
is the kind of dependency that reads as a broken runbook when hit cold.

The same holds for the current stack, whose compose file is in
`ese-policy-listener`. Whichever stack is chosen, a Docker step depends on a
repository the previous phase restores.

### 2. The running stack is not the stack the runbook restores

The machine was brought back up in a hurry from whichever compose file was to
hand. Full comparison is in
[[docs/runbook-findings/restore-docker/0024-restore-docker-stack-differs-from-pre-image/findings|docs/runbook-findings/restore-docker/0024-restore-docker-stack-differs-from-pre-image/findings.md]];
the short version is different versions of everything, a different compose file
in a different repository, and **MarkLogic — which Steps 9 and 10 spend the most
words on — is not running at all**.

### 3. Nothing notices an empty capture section

`12-docker.txt` says "NOT reachable" four times and the run still indexed as a
complete pre-image system inventory. No Phase 6B row reads inside it. At Phase
13B the same failure would make `compare-restored-state.sh` compare nothing
against nothing, which reads identically to "nothing changed". Parked as
[[docs/cross-cutting-findings/0010-docker-capture-empty-section-passes-unnoticed/findings|docs/cross-cutting-findings/0010-docker-capture-empty-section-passes-unnoticed/findings.md]].

The precondition itself is **already documented** in both runbooks that need it —
`capture-system-inventory.md` Step 2 and Supplemental Reference, and
`backup-apps.md`. Nothing to add there. What is missing is a gate that reads the
result.

---

## Before teardown — snapshot

This fills the volumes-and-networks gap and gives the after-comparison the
runbook cannot. It writes to the workspace root, so it survives a reimage and
does not enter the run index as evidence of a phase.

```bash
source ./reimage.env
OUT="$REIMAGE_WORKSPACE_ROOT/docker-before-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$OUT"
docker images -a          > "$OUT/images.txt"
docker ps -a              > "$OUT/containers.txt"
docker volume ls          > "$OUT/volumes.txt"
docker network ls         > "$OUT/networks.txt"
docker compose ls --all   > "$OUT/compose-projects.txt"
docker system df -v       > "$OUT/disk-usage.txt"
echo "saved: $OUT"
```

**One already exists**, taken 2026-09-02 while the stack was up:
`$REIMAGE_WORKSPACE_ROOT/docker-before-20260902-143519/`. It is the only record
of volumes and networks on either side of the reimage. Two volumes, both
anonymous hashes — which is what makes a full teardown cheap.

---

## Graduated teardown

Each level includes the ones above it. Pick by how much of the runbook is being
exercised.

### Level 1 — containers only

Exercises Steps 6–10, the restart paths, without re-pulling images or needing
registry credentials.

```bash
docker compose ls --all          # note the project and its config file first
docker stop $(docker ps -aq)
docker rm   $(docker ps -aq)
```

For a compose project, `docker compose -f <file> down` is better than
`stop`/`rm`: it removes the network too, so the restart path has to rebuild it.

### Level 2 — images as well

Now Step 5 (registry credentials from the encrypted image) and the pull path get
tested for real. Costs a re-pull of roughly 13 GB.

```bash
docker rmi -f $(docker images -aq)
docker builder prune -af          # daemon.json keeps 20GB of build cache
```

### Level 3 — volumes too

Full clean slate, and the only irreversible level.

```bash
docker volume ls                  # read this list one more time
docker volume rm $(docker volume ls -q)
```

Or all three at once: `docker system prune -a --volumes`.

**What Level 3 costs.** MarkLogic is fine — Step 10 redeploys security and the
application via Gradle, so its data is meant to be rebuilt. Redis and RabbitMQ
are a cache and a queue. **Elasticsearch indices are the exception**: nothing in
the workflow recreates them, and with no pre-image volume inventory there is no
record of which existed. Snapshot or reindex anything that matters first.

**Recommended: Level 2.** It tests everything the runbook claims to restore —
settings, credentials, image pulls, compose restarts — and leaves the volumes,
which the runbook never promised to restore. Level 3 can follow later,
deliberately, with the volume list in hand.

### Not this

Docker Desktop's **Reset to factory defaults** also wipes `settings-store.json`'s
`DataFolder` and CPU allocation, which Step 3 restores. That tests a harder path
than the one being documented.

---

## What to add to `restore-docker.md`

Four edits, none of them large:

| Where | What |
|---|---|
| **Prerequisites** | The compose file lives in a repository Phase 11B clones. Name it, and say the phase order is what satisfies it |
| **Before You Run Anything** | The snapshot block above, as a pre-flight for anyone re-testing rather than restoring for the first time |
| **A new step, or Supplemental Reference** | The graduated teardown, framed as *testing the restore*, not as part of it |
| **Step 2** | Skip when Docker Desktop is already installed — the common case on a re-test |

The teardown belongs in Supplemental Reference rather than Sequential Steps: a
first-time restore never runs it, and a step nobody executes on the happy path
teaches readers to skip steps.

---

## Open decision — which stack is the target

Steps 6–10 restore the pre-image stack. The machine runs a different one. Three
answers, all defensible, none of them mine to pick:

| Option | Consequence |
|---|---|
| Restore the pre-image stack | Steps 6–10 as written. Reverts working versions to older ones, and reintroduces MarkLogic |
| Adopt the current stack | Steps rewritten against `ese-policy-listener`'s compose file; MarkLogic becomes optional |
| Make the steps version-agnostic | Steps name the *services*; the compose file comes from the plan rather than being hardcoded. Most work, ages best |

Recorded in full in
[[docs/runbook-findings/restore-docker/0024-restore-docker-stack-differs-from-pre-image/findings|docs/runbook-findings/restore-docker/0024-restore-docker-stack-differs-from-pre-image/findings.md]].

## Aside, from 2026-09-02

Docker Desktop was signed out of the enterprise account and would only accept the
personal one. Local images and containers survive a sign-out — what is lost is
registry authentication for private pulls, and possibly org licence enforcement.
Worth confirming the stack still starts before planning around it being
unavailable.
