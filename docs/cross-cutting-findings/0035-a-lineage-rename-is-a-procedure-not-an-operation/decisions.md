# Decisions — a lineage rename is a procedure, not an operation

**Bundle:** `0035-a-lineage-rename-is-a-procedure-not-an-operation` · **Status:** `in progress`
**Decided:** 2026-09-04, session `session_01PcgHu9kz9Hm5RatLQuFR8H`, owner present.
**Read against:** the library itself, and a scratch category exercised through a
full rename. Nothing on the artifact volume was touched.

## D1 — `artifact_run_rename_lineage` is built, because the sequence turns out to be composable

The finding said no operation performs a rename. It also assumed the operation
would need designing. It does not: **every step already exists, and the order was
established by test rather than by argument.**

    1. artifact_run_record_rename   record the former name FIRST
    2. mv runs/<former>-STAMP -> runs/<surviving>-STAMP
    3. append a `run` row per moved run, keeping its original completion time
    4. artifact_run_retire_lineage on the FORMER context
    5. artifact_runs_rebuild

Run in a scratch category on a two-run first-wins lineage, this leaves exactly one
pointer, aimed at the right run, with the former name recoverable and no error.

**Step 4 is the one nobody did, and it is why the office-stability history was
lost.** Without it the former context keeps its `run` rows, so `artifact_runs_rebuild`
keeps looping over it, reports *computed official run is not on disk* forever, and
**leaves its stale pointer file in place** — the rebuild `continue`s past the error
without removing it. Measured, not inferred. `artifact_run_retire_lineage` has
existed since Revision 136 and does precisely the right thing here: it appends a
retire row, removes the pointer, and rebuild then skips the context while its runs
stay indexed.

**Rejected — document the sequence and leave it manual.** Five ordered steps, one
of which is invisible in its effect until a rebuild days later, is what produced
the defect. Writing it down is what §4c already does for other conventions and is
not what failed; nobody performed step 4 because nothing performed it.

**Rejected — hand the build to the session doing the next conversion**, the way
`0030` D6 handed finding 3 to `run-index`. That was right when the design needed a
concrete case to settle it. It no longer does: the sequence is proven, the failure
mode is reproduced, and the three retroactive rows `0030` D7 queued are waiting on
an operation rather than on a decision.

**Rejected — have the operation move the directories itself and skip the new `run`
rows**, treating the manifest as regenerable by `reindex`. That is exactly the
path that lost the former name: `reindex` derives the context from the directory
name (`context="${id%-$stamp}"`), so a regenerated manifest describes the new world
and nothing else.

## D2 — Finding 2 is corrected: rebuild is loud, `reindex` is the silent one

Finding 2 says a half-done rename is *silently completed in the wrong direction*.
Half of that is wrong and the correction matters, because it changes which command
is dangerous.

- **`artifact_runs_rebuild` is loud.** It verifies the computed run exists —
  `if [ ! -d "$category_root/runs/$official" ]` — and refuses with a stated error.
  It will not point at a directory that is not there.
- **`bin/reindex-artifact-runs.sh` is the silent one.** It walks `runs/*`, takes
  the context from each directory name, and appends rows. Run it after moving
  directories and the manifest is rebuilt describing the new name, with the old
  rows still present and no record that a rename happened.

So the hazard is narrower and sharper than the finding claimed: **not "recovery
runs one way" in general, but `reindex` specifically, and only when it is used to
repair a manifest after a rename instead of before one.** The one-way derivation
in the finding stands; the silence attaches to one command.

The stale-pointer behaviour above is the third case, and it is neither loud nor
silent: rebuild says the run is missing every time it runs, and leaves the pointer
where it was. A reader who does not read stderr sees a pointer that resolves to
nothing.

## D3 — No per-run identity marker

Finding 3 proposes what `PINNED-OFFICIAL.txt` already demonstrates: a file inside
the run naming its lineage, so identity survives a directory rename and
`artifact_runs_rebuild` can recover it. The precedent is real and implemented —
rebuild reads those markers back and re-indexes a pin the manifest lost.

**Decided: not built.** D1 removes the need. A marker on every run would guard
against renaming by hand *instead of* using the operation, which is a second
mechanism defending against not using the first. It would also be written by every
future run and absent from all 162 existing ones, so the case it protects — an old
run renamed by hand — is the one case it cannot cover.

**Rejected — write the marker at `artifact_run_finalize` anyway**, on the grounds
that a run carrying its own identity is simply better. It is, and the cost is a
file in every run directory forever plus a second place for `reindex` to disagree
with. If D1's operation turns out to be bypassed in practice, this is the answer,
and it should be reopened on that evidence rather than adopted against the
possibility.

**Kept as a note for whoever reopens it:** `PINNED-OFFICIAL.txt` carries
`context:` and `run:` lines and rebuild parses both, so the format and the reader
already exist.

---

## What this authorises

One toolkit write: `artifact_run_rename_lineage` in `.internal/artifact-runs.sh`.
Every finding carries a decision, so `resolving` may begin. **Nothing on the
artifact volume** — performing a rename with it is an evidence write and needs the
owner per category, as do `0030` D7's three retroactive rows.
