# `office-stability/checklists/` does not hold checklists

**Found:** 2026-09-01, session `01KcZvrKMgfenhrT9DvxW9Jk`, item 2.
**Confirmed by the owner 2026-09-02:** these artifacts are not checklists and
need a different name.
**Script side CLOSED** by Revision 137: `office-stability-checklist.sh` →
`bin/assess-office-stability.sh`, contexts
`<phase>-office-stability-assessment` and `<phase>-office-stability-evidence`.
**The directory move is still owed** — the existing bundle sits under
`office-stability/checklists/`; see exception E5 in
`docs/ledgers/artifact-migration-2026-09-02.md`.
**Severity:** low on its own. It matters because the name is the only thing
making this category look like a special case.

## What is actually in there

`office-stability/checklists/pre-image-office-stability-checklist-20260817-175050/`:

```text
README.md                                   # "open these first"
pre-image-office-stability-checklist.md     # the rendered report
system/     office-bundle-status.txt, install-log-office-events-tail.txt,
            autoupdate-office-events-tail.txt, office-crash-reports-after-marker.txt
processes/  outlook-onenote-processes.txt, outlook-onenote-process-transitions.txt,
            installer-update-management-processes.txt
watcher/    marker-and-current-time.txt, latest-watcher-log-path.txt,
            latest-watcher-tail-800.txt, watcher-installer-office-signals.txt,
            watcher-running-processes.txt
logs/       commands.log, errors.log
```

That is evidence gathered around a marker to characterise a symptom: system
state, process transitions, watcher output, and the command log that produced
them. The `.md` at the top is a **view** of the bundle, not the artifact. Calling
the directory `checklists/` names the view and hides the evidence.

## What it actually is

The same shape as two categories already in the tree:

| Bundle | Contents |
|---|---|
| `time-machine/pre-image-time-machine-status-<stamp>/` | evidence + a rendered status |
| `performance-audit/pre-image-performance-audit-<workload>-<stamp>/` | evidence + a summary |
| `office-stability/checklists/pre-image-office-stability-checklist-<stamp>/` | evidence + a rendered report |

They are **runs**. The first two are already named as such and are queued for
conversion; only this one is filed under a name that implies something else.

## Why the name matters beyond tidiness

`docs/architecture/sign-off-consolidation.md` D6 makes `checklists/` mean
something specific: the capstone list at the end of a whole pre-image or
post-image half, run-indexed, one per half. `office-stability/checklists/` is
neither a capstone nor one-per-half — it is one capture's bundle — so under D6
the name is now actively wrong rather than merely vague.

## What to do

**Do not rename to an interim name.** The destination is already known: this
category joins the run index in item 4, at which point the bundles become
`office-stability/runs/pre-image-office-stability-<stamp>/` with contexts
`pre-image-office-stability` and `post-image-office-stability`. A rename to
`bundles/` first would move the same directories twice and break the same readers
twice.

So the disposition is: **fold into item 4's conversion of `office-stability/`**,
and let the conversion supply the correct name. This file exists so that the
conversion does not preserve `checklists/` out of habit.

Two things to carry into that work:

- `office-stability/checklists/latest-pre-image-office-stability-checklist.txt`
  is a legacy pointer file and is replaced by `official/`.
- `bin/office-stability-checklist.sh` emits its manual items as
  `record_check WARN "…" "Manual: …"` rows inside the automated table (lines
  655–665). They are answered rows wearing an automated verdict, so they return
  as WARN on every run however often they are answered. That is a separate defect
  from the naming, it is tracked in `sign-off-consolidation.md` §4, and it should
  be fixed in the same pass — the script is being edited either way.
- The script's own name follows the directory. If the bundles are runs, the
  producer is a `capture-` script by the repo's own verb-first taxonomy, not a
  `-checklist` one. `capture-office-stability.sh` already exists and writes the
  same category, so the two may want merging rather than renaming. Decide that in
  item 4, not here.
