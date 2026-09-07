# The framework's own state lives in documents rather than in data

**Recorded:** 2026-09-07, from the owner's proposal that a JSON config become the single source of truth for statuses, states and counts.  
**Session:** `session-management-re-evaluation-20260906-110105` (`session_01FhFbEgG4wmrtJqUCcryNVQ`)  
**Severity:** F1 and F3 are high — both have recorded incidents, and F3's are bugs in the checks the framework is trusted by. The rest are structural and cost attention rather than correctness.  
**Felt at:** every `STATUS-` and `STATE-` tag, all five `INDEX.md` files, every `findings-manifest.md` and `metadata.md`, and `bin/verify-findings-counts.sh`, `-structure.sh`, `-headers.sh`  
**Scope:** session management. The fix lands in the bundle and session file shapes, and in the checkers that read them  
**Relates to:** `0041` — its F1 (a required shape nothing enforces) and F4 (a tag rename is a delete plus a create) are two symptoms of F1 and F2 here  
**Relates to:** `0037` — its D4 answered the same question with *display it, and add a check that catches drift*. This bundle asks whether the answer should have been *compute it, and there is nothing to drift*  
**Relates to:** `0036` — its whole subject is a displayed total that moves for reasons unrelated to the change it is quoted against  

**Read:**

- `docs/legend.md`, the ladder and the three vocabularies
- `.github/session-management-instructions.md` sections 3, 5 and 11
- all five `INDEX.md` files and all six `findings-manifest.md`
- `bin/verify-findings-counts.sh`, `bin/verify-findings-structure.sh`, `bin/verify-findings-headers.sh`
- the owner's two draft config files, 2026-09-07

**This bundle is deliberately open.** It is `analyzing` with every finding
`framing`, which the legend opens to any session, because a second architecture
is being designed in parallel and these files bear on it. **Another session
should record here rather than open a near-duplicate beside it.**

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | A bundle's status is carried in a filename, so every transition is a delete plus a create | `framing` |
| F2 | 88 count and status cells are typed by hand, and a checker exists only to catch them drifting | `framing` |
| F3 | The framework's own data is parsed back out of rendered markdown, and that parser has been wrong twice | `framing` |
| F4 | Structured fields and free-form prose share a file with nothing marking the boundary | `framing` |
| F5 | Authority is assigned to documents, so every consumer must parse prose to read a fact | `framing` |

## F1 — the status is in the filename

`STATUS-<status>` and `STATE-<state>` are empty files whose **name** carries a
mutable value. Changing one is therefore an unlink plus a create, never a write.

That is not a theoretical cost. `0041` finding 4 records four instances of a
bundle left carrying two tags at once, because the connected folder refuses
`unlink` and `git apply` downgrades the failure to a warning and exits 0. This
session met it again on 2026-09-06 and had to request delete permission before
seven tag transitions could be applied at all.

**The contrast that shows the shape.** The artifact volume holds
`office-stability/watcher-history/bundle-watch-start.marker` — also zero bytes,
and correct. It is written once and never renamed; its datum is that it exists
and when. **A zero-byte file is a good record of an event and a bad record of a
state**, and the framework uses the same construct for both.

## F2 — 88 hand-typed cells

Counted 2026-09-07:

| Where | Rows carrying a typed count or status |
|---|---:|
| `docs/sessions/INDEX.md` | 6 |
| the four findings `INDEX.md` | 42 |
| the six `findings-manifest.md` | 30 |
| `docs/runbook-findings/INDEX.md` rollup | 10 |

Every one is derived from something else — a finding table, a manifest, a tag
file — and every one is entered by hand. `bin/verify-findings-counts.sh` exists
for no other purpose than to notice when one of them stops agreeing with its
source, and `0037` D5 records the sharper failure it cannot catch: a column
headed `Findings` that held a count of *bundles*. A wrong number gets noticed;
a wrong unit gets believed.

## F3 — the data is parsed back out of the rendering

All three session-management checkers read the framework's state by parsing
markdown tables with `awk`, `sed` and `grep` — 22, 23 and 43 lines of it
respectively. Markdown is a display format, and parsing a display format to
recover the data behind it is where the failures have been:

- a greedy match ran past a closing backtick and returned a URL where it meant a
  status, so 34 bundles read as unindexed;
- an escaped pipe inside `[[path\|Label]]` was counted as a cell separator, so a
  legitimate row read as malformed.

Both are recorded in `0041`'s `resolutions.md`, and both were in the half of the
script that reads the tree rather than the half that judges it. **The first run
of that lint reported 36 failures against a tree every other validator passed.**

`0042` finding 4 has the same shape one layer out: a rendering audit whose first
run reported 131 failures, of which 128 were bugs in the audit.

## F4 — no boundary between what is authored and what is derived

A `findings.md` holds a reading, which is prose and must never be generated, and
a Findings table, which is entirely structured. A `metadata.md` holds an Owners
table and two paragraphs of environment reasoning. Nothing in either file marks
which is which.

The consequence today is that a status sweep across Revisions 198–203 reached
into a Finding column and changed **what a reading claims** — `0037` F5's row
read `reopened` against its own heading and against `0027`, and the damage was
indistinguishable from an intended edit. The consequence tomorrow is that
nothing can safely regenerate a region of a document it did not write.

## F5 — authority sits on documents, not on data

The rules name documents: `findings-manifest.md` is authoritative for ownership,
the `INDEX.md` row is authoritative for status, `metadata.md` is authoritative
for who and what. Every one of those facts is structured, and every consumer —
a checker, a session, a person — has to parse a document to reach it.

`metadata.md` is the clearest case and it cuts both ways. Its content is
entirely structured bar two paragraphs, which is why it reads as redundant. But
it is **cited by thirteen documents**, including the instruction set,
`docs/legend.md`, the architecture record and two session prompts, so removing
the file is a rename in `0030`'s sense. What can move is the authority, not the
path.

## What it costs to leave

F1 costs a permission prompt and an unlink failure on every status change, and
has produced four recorded instances of a bundle in two states at once. F3 costs
trust in the checks: a lint that reports 36 failures on its first run against a
clean tree teaches a session to discount it. F2, F4 and F5 cost attention —
every count re-typed, every sweep re-read, every fact re-parsed.

None of them is a mistake anybody made. They are one structural choice seen five
ways: **the framework's state is stored in the format it is displayed in.**

## What a fix looks like, sketched rather than decided

The owner's proposal, 2026-09-07: one `metadata.json` per session bundle and one
per findings bundle, holding the structured fields and the table rows; the
markdown becomes a projection generated from it, with the prose regions marked
and never touched.

Four things that proposal has to settle, recorded here so they are argued rather
than assumed:

- **JSON, not YAML.** The portability floor is macOS stock Bash 3.2 with no
  declared dependency. `json` is Python stdlib; `yaml` is not, and adding it
  would be this repository's first runtime dependency.
- **One fact, one file.** A draft of the session config copied `subject`, `kind`
  and finding counts from each bundle it owns — and had already drifted in the
  draft, carrying a stray tab and digit into one subject. A session should hold
  the bundle number and what it owes that bundle, and nothing the bundle owns.
- **The ladder is not bypassed.** Three bundle statuses are *declared* —
  `unclaimed`, `transferred`, `superseded` — and the rest are derived from the
  finding rows. The schema needs a declared field that is normally null, or the
  generator will assert a status the ladder disagrees with.
- **The generator becomes the new single point of failure.** Drift becomes
  impossible; a bug that rewrites forty files at once becomes possible, and
  nothing catches it. A `--check` mode that regenerates into a scratch tree and
  diffs against what is committed is the only honest answer, and it is the same
  verification this session has used on every patch today.

**The full schema belongs in `docs/architecture/`, not here.** A findings bundle
is a reading; the design is a design.
