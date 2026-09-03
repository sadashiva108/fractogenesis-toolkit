# `MANIFEST.txt` duplicates the category run index

**Found:** 2026-09-01, Restore Repositories Refactor session, while reconciling
the Bundle Layout in `restore-repos.md`.
**Severity:** none. A retention/manifest policy question, deliberately not
decided by an AI session.
**Owner:** the repository owner.

## What it is

`bin/restore-repos.sh` writes a per-run `MANIFEST.txt` naming the run, its input
run, and the files beside it. Since Revision 116-era run indexing, the same
questions are answered by:

- `repo-audit-reports/MANIFEST.md` — which runs exist, which is official, and a
  one-line result per run;
- the run directory itself — which files are in it.

So `MANIFEST.txt` restates a file listing and a pointer the index already holds,
in a third format, per run.

## Why it was not changed

Manifest, timestamping, retention and pointer policy are runbook-level decisions
in this repository, and the script-authoring prompt requires options and
tradeoffs to be presented before any of them changes. This one is small enough
that it is easy to change by accident and annoying to unwind.

## Options, if it is ever picked up

| Option | Cost |
|---|---|
| Leave it | A file nobody reads, written on every run. Zero risk |
| Stop writing it | One less artifact per run; every existing run keeps its copy, so the category becomes non-uniform |
| Keep it and give it something the index does not have | E.g. the counts and the sign-off path. Turns duplication into provenance, at the cost of another thing to keep in sync |

`restore-repos.md` → Bundle Layout currently lists it, which matches what
the script writes.
