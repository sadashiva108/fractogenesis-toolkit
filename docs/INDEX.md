# docs/ — map

Parked work. **All of `docs/` is tracked** as of Revision 162 — these files reach
a fresh clone, so writing one is a repository change and takes an
`APPLY-MANIFEST.md` revision like any other (Revision 164). One revision covers
one change, not one file: notes parked in the same sitting share an entry.
Anything that must be *true* for the workflow to work belongs in the runbook it
concerns, not in a note.

| Directory | Holds | Index |
|---|---|---|
| `architecture/` | Design that outlives the session that wrote it. Read before building the thing it describes. | — |
| `rules/` | Records **about** the framework's own rules — the front door for someone arriving cold, and where a rule can be enforced. Not the rules themselves: those live in `docs/legend.md` and the instruction sets. | [`rules/README.md`](rules/README.md) |
| `ledgers/` | Dated statements of what exists, what is stale and what is owed. Re-derived and replaced wholesale, not fixed. | — |
| | `evidence-conformance.md` — the four-table survey · `capture-script-refactor-2026-09-02.md` — R135 · `script-conformance-2026-09-02.md` — R136/137 · `artifact-migration-2026-09-02.md` — **what cannot be regenerated** · `artifact-conversion-2026-09-02.md` — **what was done about it**, R138 · `allocation-evidence.md` — allocator runs, re-derived per run, R214 | |
| `sessions/` | Session prompts, the plans they execute, and the handoffs they leave. | [[docs/sessions/INDEX\|sessions/INDEX.md]] |
| `ideas/` | Things that do not exist yet: a new script or sub-command, a new runbook or reference, a new artifact pattern or layout. Not fixes, refactors, renames or prose corrections — those are findings. | — |
| `runbook-findings/` | Findings whose ramifications are functionally felt in one runbook, including the scripts and artifacts it owns. One directory per runbook stem, all indexed in one place. Bundles hold `findings.md`, then `decisions.md`, then `resolutions.md`. | [[docs/runbook-findings/INDEX\|runbook-findings/INDEX.md]] |
| `instruction-set-findings/` | Findings about the toolkit's own instruction set — the rules a session follows when working the reimaging workflow. The fix lands in `.github/toolkit-instructions.md`. Empty since 2026-09-06; kept for the subject, which has nowhere else to go. | [[docs/instruction-set-findings/INDEX\|instruction-set-findings/INDEX.md]] |
| `session-management-findings/` | Findings about how sessions and findings bundles themselves work — the statuses, the states, the rules binding them, and the checks that hold them. The fix lands in `.github/session-management-instructions.md` or `docs/legend.md`. | [[docs/session-management-findings/INDEX\|session-management-findings/INDEX.md]] |
| `cross-cutting-findings/` | Findings whose impact is broad and agnostic to any one runbook, and may affect more than one — not merely findings that touch a shared script. Same numbered shape; one sequence shared with `runbook-findings/`. | [[docs/cross-cutting-findings/INDEX\|cross-cutting-findings/INDEX.md]] |

All eight directories and everything in them are tracked. `docs/gaps/` was retired
in Revision 162: its 25 notes became findings bundles under the two directories
above.

**Four findings directories**, sharing one numbering sequence and one bundle
shape. `docs/session-management-findings/` was added on 2026-09-06 and drew in
six bundles — three from `docs/cross-cutting-findings/` and all three then under
`docs/instruction-set-findings/`.

The two instruction-set trees divide on **which instruction file a fix lands
in**: `toolkit-instructions.md` for the workflow's rules,
`session-management-instructions.md` for the rules about sessions and bundles.
That question has one answer, where the old boundary — *is this about the
instruction set* — was true of both and so split one subject across two trees.

Their status vocabulary lives in `docs/legend.md`; the indexes carry rows and
point there rather than restating it.

The two `architecture/` files that covered the same subject are now one.
`time-machine-run-index.md` is current and approved;
`time-machine-run-index-conversion.md` was retired 2026-09-02 after its option
analysis, rejections, scope and implementation notes were carried across, and the
two paragraphs unique to it went into a *History* section there.
`APPLY-MANIFEST.md` still cites the retired filename in Revisions 128 and 133 —
that is a change log quoting paths as they were, which is why it is excluded from
the doc lint.
