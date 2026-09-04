# Styling is copied into every script, and it lands in the evidence

**Recorded:** 2026-09-04, `restore-apps-outstanding-20260903-000000`
(`session_016EbjB7M527qEFqZFzpv2C9`), from the owner comparing this repository
against `indigo`, which solved the same problem for its own outputs.
**Relates to:** `0029` finding 2 — one rule written many times with nothing
keeping it in step. This is that defect in values rather than in prose, and the
copies have already drifted, which `0029`'s have not.
**Severity:** finding 5 is high and is the reason this was written down. The rest
is untidiness; finding 5 is escape codes inside dated evidence of a machine that
no longer exists in that state.
**Scope:** cross-cutting. The fix lands in `.internal/`, the authoring template,
and the two report producers — shared machinery, felt in every script's output.
**Also applies to `indigo`:** see *The principle already exists in the estate*.
The reading holds there; the decisions may not, and are not assumed here.

---

## Finding status

| # | Finding | Status |
|---|---|---|
| 1 | Seventeen scripts each define the palette; there is no shared source | `unresolved` |
| 2 | The authoring template prescribes the copy as policy | `unresolved` |
| 3 | The copies have already drifted, in three different directions | `unresolved` |
| 4 | Fourteen of seventeen emit colour regardless of where the output goes | `unresolved` |
| 5 | Forty-eight saved evidence artifacts carry raw ANSI escapes | `unresolved` |
| 6 | Nothing checks any of it | `unresolved` |

---

## 1 — seventeen palettes, no source

`RED='\033[0;31m'` appears **17 times** across `bin/` and `.internal/`. So do
`GRN`, `YEL`, `CYN`, `BLD`, `DIM` and `RST`, fifteen times each. Every one is a
literal escape sequence typed into the script that uses it.

There is no `.internal/palette.sh`, no fragment, nothing sourced. Changing what a
warning looks like means editing seventeen files, and getting it right in all
seventeen.

The comparison that makes this legible: `indigo/ui/src/theme/tokens.css` states
the alternative as a contract — *"Components reference these `var(--…)` names
ONLY — never a raw hex."* This repository has the raw hex and no names.

## 2 — the template prescribes the copy

`.github/ai-templates/script-templates/bash-entrypoint.sh.tmpl` carries the
palette inline as a commented block, and instructs:

> reuse the same palette and helpers as backup-home.sh / report-size-audit.sh
> so runs read consistently.

**Copy-paste is the documented policy**, and it is what produced the seventeen.
The instruction's goal is right — runs should read consistently — and the
mechanism guarantees the opposite over time, because consistency maintained by
hand is consistency until someone edits one file.

## 3 — they have already drifted

Three divergences, none of them decided anywhere:

| Script | Divergence |
|---|---|
| `.internal/apps/backup-docker-settings.sh` | six tokens, **no `CYN`** |
| `bin/assess-office-stability.sh` | `RED` only |
| `bin/reimage-checklist.sh` | `RED` only |

The two `RED`-only scripts each pair it with an empty `RED=''` for a no-colour
path, so they are not simply incomplete — they made a different choice about what
colour is for, in a file nobody would think to compare against fifteen others.

## 4 — colour is emitted regardless of destination

Of the seventeen, **three** check whether output is going to a terminal:
`.internal/home/scan-archive-contents.sh`, `bin/assess-office-stability.sh`,
`bin/reimage-checklist.sh`. The other **fourteen** emit escape sequences into
whatever is on the other end — a pipe, a file, a report.

The template names this and treats it as acceptable:

> capturing this colored output into a saved report (ANSI codes intact, viewed
> with `less -R`) is a per-workflow manifest/retention decision

That is a defensible position for a log a human reads once. Finding 5 is what it
turned into.

## 5 — forty-eight evidence artifacts carry escape codes

Measured against the artifact volume, read-only:

| | |
|---|---|
| Text artifacts scanned (`.txt`, `.md`, `.log`) | 12,838 |
| Containing raw ANSI escapes | **48** |
| `loose-secrets-reports/` | 15 |
| `size-audit-reports/` | 9 |
| `_pre-conversion-backup-20260902/` | 24 — copies of the above |

Two producers, `bin/report-loose-secrets.sh` and `bin/report-size-audit.sh`, both
unguarded. The first line of every one of those reports is:

    ^[[1m^[[0;36m▸ Loose plaintext secret check^[[0m

**These are pre-image evidence.** They record what was on a machine on a date,
and that machine has since been reimaged. An evidence write that turns out wrong
may be unrecoverable — `docs/legend.md` says exactly that about this category —
and these were written by a producer that did not know it was writing evidence
rather than talking to a terminal.

Nothing is lost: the text is intact and `less -R` or `sed` reads it. What is lost
is that the artifacts are no longer plain text. A grep for a filename in a
coloured line can miss it, a diff between two runs shows escape changes as
content changes, and anything that ingests these later has to know.

## 6 — nothing checks any of it

No validator compares one script's palette against another's, none flags a
producer that writes colour into a file, and none looks for escape codes in the
artifact root. All four validators pass today with every fact above true.

This is `0032`'s argument again, from a third angle: `0032` finding 2 is a check
that examines the wrong property, finding 4 is a check that exits 0 on a partial
apply, and this is a property with no check at all.

---

## The principle already exists in the estate

`indigo` — a sibling repository in the same workspace — has solved this shape for
both its interfaces. The reading is recorded here because it is the clearest
statement of what the fix looks like, not because this bundle decides anything
for that repository.

**For its documents.** The Markdown carries content plus style-free semantic
markers — `<span class="todo|tentative|confirmed">`, `<span class="code">`,
`<div class="note">` — and a named style supplies the look at render time.
Styles are data, `engagements/shared/styles/<name>.json`; adding one is dropping
in a file, with no code change. The authoring prompt states the prohibition
directly: *"Never put colors, hex codes, or `style="…"` attributes in the"*
markdown.

**For its UI.** `ui/src/theme/tokens.css` is a token contract; `skins.css` varies
colour on `data-skin`; `layout.css` varies density on `data-density`; the two
axes are independent and mix freely, and `SkinProvider.tsx` sets two attributes
on `<html>` and does nothing else. Five skins, and the markup never changes.

**Its contract leaks too, and that is worth recording rather than glossing.**
`ui/src/styles.css` uses `var(--…)` 154 times and still carries raw hex: `#fff`
eleven times, and `#4f46e5` three times — the literal value of `--indigo`, copied
out of the token file. Under the `midnight` or `gaig` skin those three stay
indigo while everything around them changes. The rule is stated in the file it is
broken in.

So the principle is proven in practice and its enforcement is not, in both
repositories. That is one observation, not two, and it argues that whatever is
decided here should come with the check from the start rather than as a later
finding.

---

## What this bundle does not cover

The visual conventions in the Markdown itself — the callout legend, the status
backticks, the `✓` and `—` in index cells. Those are a document styling question
and may well be the same finding one level up, but they were not read here and
are not claimed.

Nor does it cover whether the artifact volume's forty-eight files should be
rewritten. That is an evidence write against dated records, it needs the owner's
word for that run, and it is a decision rather than a reading.
