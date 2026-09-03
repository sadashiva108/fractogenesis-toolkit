# An empty Docker section captures cleanly and nothing downstream notices

**Found:** 2026-09-02, while planning a `restore-docker` teardown test.
**Severity:** low to hit, moderate to leave — a comparison silently compares
nothing against nothing.
**Owner:** unassigned. Touches `capture-system-inventory.sh`,
`bin/reimage-checklist.sh` (Phase 6B) and `bin/compare-restored-state.sh`.

## What is *not* wrong

The precondition is documented, in both runbooks that need it:

- `capture-system-inventory.md` Step 2 — *"If you want section 12 to capture your
  Docker images, containers, volumes, and networks, start Docker Desktop before
  you run"*, and again in its Supplemental Reference.
- `backup-apps.md` — *"`image-inventory.txt` and `container-inventory.txt` are
  produced by querying the running daemon — with Docker stopped they are
  silently skipped and the run still reports success."*

Neither runbook is missing anything. And the capture is *right* to be permissive:
the runbook explicitly allows a `clean-boot` snapshot taken with Docker
intentionally off.

## What is wrong

Nothing reports that the section came back empty.

On 2026-08-16 the two captures ran 4.5 hours apart. `backup-apps.sh` ran at
16:42 with the daemon up and got real content — 8 images, 4 containers, the
compose project. `capture-system-inventory.sh` ran at 21:16 with Docker quit, and
`12-docker.txt` records:

```text
Docker daemon: NOT reachable — start Docker Desktop to capture images/containers/volumes.
--- Docker images ---
Cannot connect to the Docker daemon at unix:///Users/dkittrell/.docker/run/docker.sock…
--- Volumes ---
Cannot connect to the Docker daemon…
--- Networks ---
Cannot connect to the Docker daemon…
```

Four sections, no content, and the run indexed as a complete pre-image system
inventory. No Phase 6B row reads section 12, so nothing said so at the time, and
the fact surfaced two weeks later only because someone opened the file.

The consequence lands at Phase 13B. `compare-restored-state.sh` compares the
post-image capture against the pre-image one. If the post-image run is also taken
with Docker down, both sides are empty and the comparison reports nothing —
which reads identically to "nothing changed".

## What was actually lost

Less than it appears. `app-settings-backup/docker/` holds the images, containers
and compose project, captured while the daemon was up. Only **volumes and
networks** were never recorded anywhere.

And nothing in the workflow backs up volume *data* in the first place, so a
volume list would have told the operator what to rebuild, not let them restore
it. The loss is a checklist item, not a payload.

## Shape of a fix

Two parts, and the first is the one that would have caught it.

**A Phase 6B row that reads the section rather than the file's existence.** The
pattern already exists — `record-restore-prereqs.sh` grades *"Audit remote URLs
are URLs"* by reading inside `repos.tsv` rather than checking it is there. A row
that greps `12-docker.txt` for `NOT reachable` and records WARN is the same
shape, and generalises: any section that reports unreachable rather than content
is a capture that ran but did not capture.

**A precondition prompt at capture time.** `capture-system-inventory.sh` could
report at the end which sections came back empty, so the operator sees it while
they can still fix it. Not a failure — the clean-boot case is legitimate — but
not silent either.

## Related

This is the same shape as `repo-audit-tsv-column-shift`: the file stated the
problem plainly, in the file, and no gate read it.
