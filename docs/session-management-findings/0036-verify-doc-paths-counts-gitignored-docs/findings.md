# `verify-doc-paths.sh --all` counts `docs/`, so its OK baseline cannot hold

**Recorded:** 2026-09-01, while validating Revision 129.  
**Session:** `01KcZvrKMgfenhrT9DvxW9Jk`  
**Severity:** low, but it silently invalidates a number two session briefs quote.  
**Relates to:** [`0026`](../../cross-cutting-findings/0026-verify-doc-paths-counts-gitignored-docs/) — **supersedes it.** The original is retained at `docs/cross-cutting-findings/0026-verify-doc-paths-counts-gitignored-docs/`, still listed by the session that held it, its reading unchanged and its files brought onto the schema in Revision 203. Authority for this reading lives here.

**Status: CLOSED** by Revision 130, 2026-09-01, same session — option (i), with
(iii) adopted alongside it in `docs/sessions/session-responsibilities.md`. With
`docs/` pruned the total returns to 713, the figure recorded before any note was
parked. Kept for the reasoning.
**Reopened 2026-09-06.** Moved to `docs/session-management-findings/` and put
back in play: the exclusion this bundle installed rests on a reason that stopped
being true at Revision 162 — `docs/` is tracked and does reach a fresh clone — so
every link in every findings index and session manifest is unverified. Option
(iii) is still undecided.

## Finding status

This bundle predates the per-finding table and carried its status in prose. One
finding, recorded here so the bundle derives like every other.

| # | Finding | Status |
|---|---|---|
| F1 | `verify-doc-paths.sh --all` scans `docs/`, so its OK baseline cannot hold | `decided` |

## What is wrong

`bin/verify-doc-paths.sh` line 172 selects documents with:

```bash
find . -name .git -prune -o -name __pycache__ -prune \
     -o -path './.github/ai-templates/*' -prune \
     -o -type f -name '*.md' -print
```

`docs/` is not pruned, so every note parked under `docs/features/`,
`docs/*-findings/` and `docs/sessions/` is scanned as if it were governance
documentation — even though Revision 128 made those contents gitignored working
notes that never reach a fresh clone.

`APPLY-MANIFEST.md` *is* excluded, with a stated reason: it quotes paths as they
were at the time of a revision, so a reference that no longer resolves is the
record working correctly. Session handoffs have exactly that property.

## Why it matters

The `OK` count moves whenever any session parks a note. Observed today:

| Recorded | Source | OK |
|---|---|---|
| 2026-09-01 | `docs/sessions/run-index-design-20260901-000000/handoff-20260901-222913.md` §5 | 713 |
| 2026-09-01 | `docs/sessions/run-index-design-20260901-000000/prompt.md` baseline | 745 |
| 2026-09-01, after this session wrote 9 files under `docs/` | measured | 860 |

None of those differences is a regression, and no session caused one by editing a
tracked document. But a brief that says *"compare against 745 OK"* is asking the
next session to compare against a number that changed for reasons unrelated to
its work — and the honest response, "the count moved and I did not cause it", is
indistinguishable from not having looked.

`MISSING` and `ANCHOR BROKEN` are unaffected and stay meaningful. Both are 0.

## The cheaper half of the finding

Scanning `docs/` is not purely bad: it did verify that every repository path
cited in this session's nine new notes resolves. That is a real check, just not
one that belongs in the same total as the governance docs.

## Options

- **(i)** Prune `docs/` like `.github/ai-templates/`. Restores a stable baseline;
  loses the incidental checking of parked notes.
- **(ii)** Keep scanning but report `docs/` separately, so the governance total is
  stable and the notes are still checked. More code in a lint nobody asked to
  grow.
- **(iii)** Leave it, and stop quoting an `OK` baseline in session briefs — track
  only `MISSING` and `ANCHOR BROKEN`, which are the rows that mean anything.

**(iii) is nearly free and (i) is one line.** Not decided here; both are cheap,
and the choice belongs with whoever next touches the lint.

---

## What the reopening established, 2026-09-06

Recorded by `session-management-re-evaluation-20260906-110105`, which owns this
bundle. **The reading above is unchanged; this is the measurement it never had.**

### The exclusion is unconditional, and `--all` does not lift it

`bin/verify-doc-paths.sh:185` prunes `./docs/*` in the `find` that `--all`
selects from. **`--all` does not widen the exclusion — it widens the document
set**, from a hard-coded list of 98 files to every tracked Markdown file *except*
`docs/`, `.github/ai-templates/` and `APPLY-MANIFEST.md`. That is where 778 paths
and 1108 anchors come from, and **none of them is under `docs/`**.

Tested rather than read: a deliberately broken link was added to a findings
bundle and the checker run in both modes. **Neither reported it.**

This matters because the opposite has been written down. A session prompt
amendment of 2026-09-06 states *"with `--all` it reaches `docs/`: 778 paths, 1108
anchors"*, correcting a true statement into a false one, and two sessions
repeated it. The prompt was corrected the same day.

### What scanning `docs/` actually finds

Measured by removing the prune in a scratch copy and running `--all`:

| | Pruned (today) | Scanned |
|---|---:|---:|
| OK | 778 | 1662 |
| WARN | 121 | 283 |
| ANCHOR OK | 1108 | 1154 |
| **MISSING** | **0** | **10** |
| **ANCHOR BROKEN** | **0** | **2** |

**The ten MISSING are two different things, and the difference decides this
bundle.**

**Seven are paths that do not exist yet because a reading proposes them** — and
proposing is what a findings bundle is for:

| Path | Cited by |
|---|---|
| `bin/office-stability-checklist.sh` ×4 | `0013`, two ledgers, one architecture record |
| `bin/verify-index-tables.sh` ×2 | `0032` and `0041` — the lint was built as `verify-findings-structure.sh` instead |
| `.internal/palette.sh` | `0033` |

**Three are genuinely stale citations**, all in one file —
`docs/sessions/restore-apps-outstanding-20260903-000000/prompt.md`:

| Cited | Actually |
|---|---|
| `.github/copilot-prompts/` | `.github/ai-prompts/` |
| `.github/copilot-templates/` | `.github/ai-templates/` |
| `.internal/restore/record-restore-prereqs.sh` | `bin/record-restore-prereqs.sh`; `.internal/restore/` is empty, which is `0012` |

**Both broken anchors are self-references inside architecture records:**
`docs/architecture/restore-docker-teardown-and-test.md` points at
`[[#What to add to restore-docker.md]]` and
`docs/architecture/time-machine-run-index.md` at `[[#9. Open decisions]]`;
neither heading exists in its own file.

### The finding is two defects sharing one exclusion

They were conflated from the start and the conflation is why neither is settled.

- **The OK total is not a baseline.** True, and unchanged. Parking a note moves
  it. This is what Revision 130 fixed, by removing the notes from the total.
- **`docs/` links are unverified.** Revision 130 fixed the first by creating the
  second, on a stated reason — *"gitignored working notes … they never reach a
  fresh clone"* — that **has been false since Revision 162.** Every link in every
  findings index, session manifest and bundle has gone unchecked since.

The false-positive class the exclusion was really protecting against is neither
of those. It is the seven proposed paths: **a reading legitimately names a path
that does not exist yet.** No document said so, and it is what the options in
`decisions.md` now turn on.
