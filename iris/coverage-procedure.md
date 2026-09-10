# Coverage map — `.github/session-management-instructions.md` → `iris/procedure.md`

Built before writing. Verified after. 979 lines of source, every section
accounted for. `→ §n` is a section of `procedure.md`. `→ POINT` means the
content is now owned by another IRIS document and procedure.md cites it instead
of restating it. `→ PROV` means it lands in the Provenance table.

| Source | What is in it | Lands |
|---|---|---|
| Masthead (1–31) | role, authority, rank 3, project-agnostic, "read first", nothing restates a definition | procedure.md masthead; rank → POINT rules.md |
| §0.1 compose in scratch tree, never edit the checkout | RULE | §0 |
| §0.2 run every verification in the scratch tree | RULE | §0 |
| §0.3 produce the patch, `git add -N .` + `git diff` to PATCH_DIR | RULE | §0, §3 |
| §0.4 report a review, not a diff | RULE | §0 |
| §0.5 wait; declining is free; the asymmetry | RULE + rationale | §0 · PROV `0038` F4 |
| §0.6 apply only on *write it and provide a commit message* | RULE | §0 |
| §0.6 applying is a response, never an initiation; ambiguity → compose and ask; `do it` is not the ask | RULE | §0 · PROV `0049` F6, D7 |
| §0.6 assert checkout clean first; `--no-optional-locks`; index.lock on a mount | RULE | §0 · PROV `0038` F1 |
| §0.6 not empty means refuse; `git apply --check` does not decide it | RULE | §0 · PROV `0038` F1/F4, `0049` F6/D8 |
| §0.6 after applying assert the index is empty | RULE | §0 · PROV `0049` F5, D6 |
| §0.6 no `--index`/`--cached` | RULE | §0 |
| §0.7 the owner stages, commits, pushes | RULE | §0 |
| §0 the patch goes stale; three colliding files | RULE | §0, §7 · PROV `0038` F1 |
| §0 rebase in a fresh scratch copy, `git apply -3`; resolve to the checkout, never merge; recompute counts | RULE | §0, §7 |
| §0 re-take the revision number; correct every place it appears; re-measure quoted figures | RULE | §0, §4 |
| §0 measured twice at 264→268 | history | PROV |
| §0 steps 1 and 2 absolute; step 6 the only exception | RULE | §0 · PROV `0049` |
| §1 the two objects, how they meet | definitions | POINT vocabulary.md, schema.md |
| §1 neither directory name carries the other's identifier | RULE (naming) | §4 |
| §2 which tree this governs; the "another project entirely" test | RULE | §1 |
| §2 one sequence, four digits, never reused, never renumbered | RULE | §4 |
| §2 take the next free number immediately before writing + the `ls` | RULE | §4, §7 |
| §2 `docs/INDEX.md` owns the directory list | RULE (one home) | §1 |
| §3 dossier directory layout | schema | POINT schema.md, directory-reference.md |
| §3 a MIGRATED dossier carries `resolutions.md` and no `decisions.md` | RULE | §5a · PROV `0037` D2 / `0047` F4 |
| §3 the tag is a marker file, not a suffix; never rename on transition | RULE | §4 |
| §3 the index row is authoritative; a disagreeing row is a bug | RULE | §5a |
| §4 permission by member status | definitions | POINT vocabulary.md §3, §11 |
| §4 deciding is not the owner's privilege; closing it is | RULE | §2 |
| §4 a non-owner's decision goes in Contributions | RULE | §2, §5a |
| §4 status/standing/state disjoint | definition | POINT vocabulary.md §1 |
| §4 `progress` vs `standing`, both stamped never hand-written | derivation | POINT lifecycles.md §3 |
| §5 session directory layout | schema | POINT schema.md §4 |
| §5 `<title>-<stamp>`, America/New_York, never restamped, no number in the name, fixed at creation | RULE | §4 |
| §5 `metadata.md` authoritative; rows never edited once ownership ended | RULE | §8 |
| §5 every value resolved — no placeholder in a record | RULE | §8 |
| §5 environment is not decoration; `not recoverable` names the searches | RULE | §8 |
| §5 every `prompt.md` names the rules first; binds prompts from now; closed prompts not rewritten | RULE | §8 · PROV `0037` D1 |
| §5 legend owns how a session begins and what transfers | POINT | §8 → lifecycles.md, legend |
| §6 only this repository's work is recorded; the rule lives in the repo it governs | RULE | §2 · PROV `0039` D19, F19, F9 |
| §6 connection is availability, scope is subject; `prompt.md` states the subject | RULE | §2 |
| §6 four write categories | definitions | POINT vocabulary.md §10 |
| §6 meaning in the legend, gating here | RULE (split) | §2 · PROV `0039` D2, D13 |
| §6 a record write is never gated | RULE | §2 |
| §6 a toolkit write is gated on a `decided` member | RULE | §2 |
| §6 an evidence write is granted per run; a bad one may be unrecoverable | RULE | §2 |
| §6 `foreign` is not recorded | RULE | §2 |
| §6 compose in a copy; validate in the copy | RULE | §3 |
| §6 `git apply --check` before applying, and say so; it passes on an under-apply | RULE | §3 |
| §6 exit 0 on a mount that refuses unlink; modification too; verify by tree comparison | RULE | §3 |
| §6 the empty-file/rename trap, generalised | RULE | §3 |
| §6 `git add -N` is not optional and its absence is silent; Revision 231 measurement | RULE | §0, §3 · PROV |
| §6 read the patch's file list against your change set | RULE | §3 |
| §6 say which you did — *handed over* vs *applied at your direction* | RULE | §3 |
| §6 ask for delete permission before applying; per folder; dies on reconnect; `_to_delete/` | RULE | §3, §7 |
| §6 a scratch copy dies with the session; hand over at stopping points | RULE | §3 |
| §6 owner reviews and commits; never commit/push/rewrite; staging in your own copy is not a write | RULE | §0, §3 |
| §7 every change takes a revision, record writes included | RULE | §5 |
| §7 a revision covers a change, not a file | RULE | §5 |
| §7 take the number at apply time; the helper; why composing is a guess | RULE | §4, §5 |
| §7 entries are never retro-edited; a revert is a new entry | RULE | §5 |
| §7 commit message short, subject <70, body 1–2 paragraphs, points at the manifest | RULE | §5 |
| §7 the block is the message and nothing else — no `git commit`, no `-m`, no wrapper | RULE | §5 |
| §7 one fenced `text` block | RULE | §5 · PROV `0039` F23, D21 |
| §7 runnable things go beside the block | RULE | §5 |
| §7 end with the trailers | RULE | §5 |
| §8 what to read: legend, the two INDEXes, the dossier itself | RULE | §1 |
| §8 write findings rather than widening the task | RULE | §1 |
| §8 one file per item, named for the thing not the date; dossiers are the exception | RULE | §1, §4 |
| §8 a fact has one home; a copy only where generated or checked | RULE | §1 |
| §8 completeness is not conformance; verify generated content against source; never redirect into a file you are reading | RULE | §1 |
| §8 know what a check does not examine | RULE | §1 → POINT verifications.md |
| §9 supersession reaches any standing; never a single member | RULE | §8 |
| §9 a superseded dossier is readable by all, writable by none | POINT vocabulary.md §11 | §8 (as a prohibition) |
| §9 the session with the new reading performs it and does not take ownership | RULE | §8 |
| §9 three prohibitions — predecessor not edited, number never reused / directory never renamed, does not move between manifests | RULE | §8 |
| §9 the nine steps | procedure | POINT lifecycles.md §5.1 |
| §9 coverage and exclusivity gate the tag; *at least one*, not *exactly one* | RULE | §8 · POINT lifecycles.md §6 |
| §9 edge kinds and `new` derived from absence | vocabulary | POINT vocabulary.md §8 |
| §9 a `closed` originating session's `final-summary.md` is never edited | RULE | §8 |
| §9 `superseded` vs `withdrawn`: a replacement being opened decides it | RULE | §8 |
| §9a reopening — four things recorded, the fourth makes the rest checkable | procedure | POINT lifecycles.md §5.2 |
| §9a a reason is from the closed set; prose is not a reason | RULE | §8 |
| §9a the reason determines the exit | POINT vocabulary.md §9 | §8 |
| §9a `reopened.md` is generated, never hand-written, never a copy | RULE | §8 |
| §9a a `reopened` member persists until a material change | POINT lifecycles.md §1 | §8 |
| §9a withdrawing is per member; a `resolved` member is reopened first | RULE | §8 · POINT lifecycles.md §5.3 |
| §9b the three steps and their order | procedure | POINT lifecycles.md §5.4 |
| §9b step 1 is a toolkit write gated on `decided`; the revision is taken at apply time | RULE | §2, §8 |
| §9b a `decided` member carried out with no row is a defect | RULE | §8 · PROV `0037` F5, `0039` F17/D18 |
| §9b `resolutions.md` is not required | RULE | §5a |
| §10 the target session must already exist | RULE | §8 |
| §10 permitted standings, and the two-vocabulary disagreement | RULE | §8 · POINT lifecycles.md §5.5 |
| §10 the five steps | procedure | POINT lifecycles.md §5.5 |
| §10 the transfer ends on the first write as owner; a contribution does not clear it | RULE | §8 · PROV `0039` D24 |
| §10 transferring part of a dossier is not supported | RULE | §8 |
| §10a release vs transfer — choose by whether a taker exists | RULE | §8 |
| §10a the four steps, and there is no step for the status | procedure | POINT lifecycles.md §5.6 |
| §10a step 4 is not optional | RULE | §8 |
| §10a a session may not end holding a dossier | RULE | §8 · PROV `0039` F20, D20 |
| §11 the header block, field by field | document schema — not in schema.md, which owns `metadata.json` | §5a, compressed to the rule |
| §11 one field one line, two-space hard breaks, no wrapping | RULE | §5a |
| §11 expect the trailing-whitespace warning and do not act on it | RULE | §5a |
| §11 fence every example as `text`, never `markdown` | RULE | §5a |
| §11 `Session:` is its own field; `—` where none was recorded | RULE | §5a |
| §11 required vs optional fields; no other field appears; `Read:` bullets | RULE | §5a |
| §11 `Recorded:` is the date it was written down | RULE | §5a |
| §11 `Felt at:` vs `Scope:` | RULE | §5a |
| §11 `Relates to:` optional and repeatable | POINT vocabulary.md §12 | §5a (one clause) |
| §11 Contributions: omit when empty; ownership is not a contribution | RULE | §5a |
| §11 `Owner:` and `Status:` are retired and must not come back | RULE | §5a |
| §11 the Findings table is required, even for one member; `F1` not `1` | RULE | §5a |
| §11 `decisions.md` header; no `Status:` field here | RULE | §5a |
| §11 outcomes; no outcome value is also a status value | POINT vocabulary.md §7 | §5a |
| §11 any session may add a row or change an Outcome while `framing` | RULE | §2 |
| §11 a rejected or refined decision keeps its row and its section | RULE | §5a |
| §11 a decision always cites its members; `—` retired | RULE | §5a · PROV D15, Revision 230 |
| §11 `resolutions.md` shape; `Resolved by` is the decision; revision and commit are separate | RULE | §5a |
| §11 the three files must agree in both directions | RULE | §5a |
| §11 `findings-manifest.md` / `metadata.md` shapes | schema | POINT schema.md §4 |
| §11 the narrative files have no schema, only a required minimum | RULE | §8 |
| §11 reformatting is not a change, and a revision that reformats says so | RULE | §5a |
| `docs/legend.md` — The owner's override | RULE, both halves | §6 |
| `docs/legend.md` — Who may write to a findings dossier | RULE | §2 |

## Deliberately dropped

Restated definitions (vocabulary.md), restated lifecycles and step lists
(lifecycles.md), restated `metadata.json` field schemas (schema.md), the genus
model (shapes.md), the precedence ranking (rules.md), the instrument roster
(verifications.md), and every paragraph of history explaining why a rule changed
— compressed to one Provenance row each.

## Verification

Run against the finished `procedure.md`: **137 distinct rule probes, 0 missing**;
every internal and cross-document link and anchor resolves (0 broken); no
`[[wikilink]]`; the word *bundle* appears once, quoting `docs/legend.md`'s own
section title in a Provenance row. **702 lines** — over the 400–500 aim, and the
overshoot is section 5a, which carries the source's §11 document shapes because
`schema.md` owns `metadata.json` and nothing else in IRIS holds them.
