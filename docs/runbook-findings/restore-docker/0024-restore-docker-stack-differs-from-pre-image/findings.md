# The running Docker stack is not the one `restore-docker.md` restores

**Found:** 2026-09-02, comparing a fresh post-image Docker capture against the
pre-image inventory.
**Severity:** planning input for Phase 12. `restore-docker.md` Steps 6–10
describe a stack that is not on this machine.
**Owner:** the repository owner, at `restore-docker.md`.

## The two stacks

The reimaged Mac was brought back up in a hurry from whichever compose file was
to hand, and it is not the one the backup recorded.

| | Pre-image, 2026-08-16 | Now, 2026-09-02 |
|---|---|---|
| Elasticsearch | `8.13.0` | `8.9.0` |
| Kibana | not running | `8.9.0`, port 5601 |
| Redis | `redis:latest` | `redis:7-alpine` |
| RabbitMQ | `3-management` | `3.12-management` |
| MarkLogic | `progressofficial/marklogic-db`, exited | **not present** |
| Compose project | `elastic` | `docker` |
| Compose file | `…/apicoe/carrier-services-storage/src/main/docker/elastic/docker-compose.yml` | `…/orah/ese-policy-listener/docker/docker-compose-es-kibana.yml` |

Different versions, a different compose file, in a **different repository**, and
MarkLogic — which Steps 9 and 10 spend the most words on — is not running at all.

## Why it matters

**Steps 6–10 will not match what is on the machine.** They restart Redis,
RabbitMQ, Elasticsearch/Kibana and MarkLogic from the pre-image compose files.
Walking them as written restores the *pre-image* stack alongside, or instead of,
the one currently working.

**The compose file is inside a repository, and that is an ordering dependency.**
Both compose files live in repositories that Phase 11B clones. Neither Docker
step can run before `restore-repos` has brought its repository back — which is
correct as the phases are ordered, but it is not stated in `restore-docker.md`
Prerequisites.

**Two anonymous volumes exist**, both unnamed hashes. Nothing depends on their
names, which makes a full teardown cheaper than it looked.

## The decision this parks

Which stack is the target? Three answers, all defensible:

| Option | Consequence |
|---|---|
| Restore the pre-image stack | Steps 6–10 as written. Reverts working versions to older ones |
| Adopt the current stack | Steps 6–10 rewritten against `ese-policy-listener`'s compose file; MarkLogic becomes optional |
| Treat the runbook as version-agnostic | Steps name the *services*, and the compose file comes from the plan rather than being hardcoded |

A capture of the current stack is preserved at
`$REIMAGE_WORKSPACE_ROOT/docker-before-20260902-143519/` — images, containers,
volumes, networks, compose projects and disk usage. It survives a future reimage
because it is in the workspace root, and it is the only record of the volumes and
networks that exists on either side of the reimage.
