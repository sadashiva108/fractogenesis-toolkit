# Decisions — the index and manifest tables have a shape nothing checks

**Bundle:** `0041-index-and-manifest-tables-have-a-shape-nothing-checks`  
**Session:** `assurance-coverage-20260908-204724`  
**Decided:** 2026-09-09, and 2026-09-10 for D7

**D1 is the coverage answer for this whole session.** `0041/F2` co-decides
`0044/F1` and `0042/F1` reads on it; it is stated once, here, and the other
bundles cite it rather than restating it.

| # | Decision | Findings | Decided | Outcome |
|---|---|---|---|---|
| D1 | **A check is responsible for the artifact as it will be read, not for a curated proxy of it.** Where it can only see a declared subset, the undeclared remainder must fail rather than inform | F2 | 2026-09-09 | `accepted` |
| D2 | F1 is overtaken. The column-count check was built at Revision 195 and the `Bundle:` value defect it later gained is clean in all ten files | F1 | 2026-09-09 | `accepted` |
| D3 | This bundle stays in `docs/session-management-findings/`. The subject decides the tree, not the fix | F3 | 2026-09-09 | `accepted` |
| D4 | F4's record half is closed by section 6. Its *"and every check passes"* half is D1 and is not separately decided | F4 | 2026-09-09 | `accepted` |
| D5 | A resolution names a **verifiable referent** — a file and a construct in it — never a section number | F5 | 2026-09-09 | `accepted` |
| D6 | A total is summed from the rows it describes, or it is not written. The count check gains the one assertion it has always been read as making | F6 | 2026-09-09 | `accepted` |
| D7 | `verify-findings-structure.sh` gains the two projected values nothing compares — a session manifest's `Standing` and a session's `State` in `docs/sessions/INDEX.md` — measured against the data each derives from | F8 | 2026-09-10 | `accepted` |

---

## D1 — what the assurance layer is responsible for seeing

F2 says *"the check that runs gives the wrong assurance"* about one script. It is
not a fact about that script. Three checks in this repository are built the same
way and all three are blind in the same place:

| Check | The declared set it reads | What it cannot see |
|---|---|---|
| `bin/verify-doc-paths.sh` | paths rooted at a `REPO_DIRS` component, plus bare `*.md\|sh\|py\|tmpl` filenames — `extract_references()`, line 283 | every relative markdown link |
| `bin/verify-doc-currency.sh` | asserted source-to-dependent edges in `doc-currency.json` | nothing; the edges are right. It has never been armed — see D1's second half |
| `plan_findings_work.py` `EDGE-TO-SUPERSEDED` | `metadata.json` `edges[]` | a bundle number cited in prose — `0046` F1 |

**Each covers a set somebody had to remember to add to, and every defect any of
them missed lives in what nobody added.**

**The proxy is not the defect. The free gap is.** `verify-doc-currency.sh
--coverage` reports `30 files watched, 19 not` and **returns 0**. The gap is
visible, costs nothing, and has therefore stayed. So the rule is not *stop using
declared sets* — an inferred edge is worse, and that script's own docstring
argues it correctly. The rule is:

> **A check over a declared subset must report the undeclared remainder, and the
> run must fail on it unless the remainder has been declared out deliberately.**

`docs/rules/rule-enforcement-avenues.md` §2 reaches the same place from the
enforcement side and states it better than this decision did: **`nowhere` is a
real answer and has to be written down as one**, because *"a rule with no
instrument is otherwise quoted as enforced."* That is this decision's sentence
about a free gap, generalised — an undeclared remainder is a region whose avenue
is `nowhere`, and the failure is that nothing says so.

**The second half, and it is the sharper one: a declared set is not a check until
it is armed.** Every one of the seven watches in `doc-currency.json` carries
`"sourceDigest": null`. `doc_currency.py:evaluate()` tests the null before it
compares, so a watch with no baseline returns `UNCONFIRMED` and **can never reach
`DRIFTED`**. The `state-schema` watch is `critical`, names
`docs/architecture/state-as-data.md` as its source and `docs/legend.md` among its
dependents, and was asserted at Revision 232 — the same revision that took the
decision the legend then contradicted for four revisions. **The edge was right,
the tier was right, and the instrument could not fire.**

### The check this implies, and the false positive it produces

For `verify-doc-paths.sh`: extract markdown inline-link targets and resolve them
against the citing document's directory.

**Measured on the tree at Revision 238, before proposing it.** A naive
implementation that does not respect code context raises **15**, of which **7 are
not links at all** — 4 elided examples (`0030-…/`), 2 schema placeholders
(`<new-bundle>/`), and one `` [text](path) `` inside an inline code span in
`.internal/ai-scripts/README.md`. That is a **47% first-run false-positive
rate**, which would have been the seventh in a row.

**Three suppressors were drafted for those seven and all three are wrong.** Every
one of the seven sits inside a fenced block or an inline code span. With code
context respected the naive run raises **8, all 8 real, 0 false positives, and no
suppressor is needed at all.** Reproduced independently by the owner over a
different scan scope — 198 files and 249 targets against 209 and 233 — with the
same eight.

**The requirement underneath the suppressors is the one to implement: the
extractor must respect code context.** That is `0015` — *portability lint cannot
see heredoc context* — in a second checker, and it is the third instance of the
same reading in this repository.

**Hold the implementation to 8 / 8 / 0.** If it does not reproduce that on this
tree, the check is wrong and the tree is not.

**One suppressor was nearly shipped on an instance that does not exist.** The
bare-word rule was drafted against `` [text](path) ``, which is inline code. A
rule admitted on a case that is not real is how a check later fails to see one
that is — the same shape as the dead exemption in `0050` F2, and it would have
been installed in the revision that exists because of it.

## D2 — F1 is overtaken

`.internal/ai-scripts/session-management/verify-findings-structure.sh`, lines
95–116, takes each table's column count from the header that opens it and reports
any data row that disagrees. Built at Revision 195, commit `92a4f79`. Run on this
tree: **59 OK / 0 FAIL.**

F1's later sub-claim — *"the `Bundle:` field is wrong in all ten `decisions.md`
and `resolutions.md` in this tree"* — was checked on 2026-09-09 by comparing each
file's `Bundle:` value against the directory it sits in. **All ten agree.**

**Not claimed: that the check covers what F1 asked for in full.** F1 also named
the tag-versus-rows comparison, and tag files were removed at Revision 222, so
that half is moot rather than done.

## D3 — the tree is decided by subject

F3 records that `docs/INDEX.md` routes by *the rules a session works under* and
section 4c's own test routes by *where the fix lands*, and that the two disagree
for this bundle.

**The subject wins.** The instruction set's test is *"would this finding still
exist in a project that did something else entirely?"* — and a rule that index
tables have a fixed shape, unenforced, travels to any project adopting this
structure. That the fix happens to land in `bin/` is a fact about this
repository's layout, not about the finding.

**Rejected: moving it to `docs/cross-cutting-findings/`.** It would put a finding
about the framework in the tree for the toolkit's shared machinery, and `0037`
F1's question — *where is a rule allowed to live* — would reach it immediately.

## D4 — F4 is closed on the record and open on the check

Section 6 now carries the whole of F4's operational content: the exit status says
nothing, the warning is not diagnostic, verification is a tree comparison and not
a checksum, and delete permission is requested before applying rather than after
it fails. `0049` D1 records that the same bullet also fixed the general case F4
was one member of.

What section 6 does not do is make any of it checkable, which is F4's *"and every
check passes"*. That is D1 and is not decided twice.

## D5 — a resolution names something `grep` can answer

F5 found three of twenty-five resolution claims false, in three different ways,
and **all three cite `§4c`, a section that no longer exists.** The honest middle
F5 proposes is adopted: `What was done` names a **file and a construct in it**,
so the claim has a referent that survives a rename of the thing that contained
it.

`Revision` and `Commit` stay mechanical and separate, and `Commit` may be `—`
where the commit does not exist yet — which is the state every resolution written
before its own apply is in, including the two in this session's `0044`.

**Not decided: a checker for it.** Whether a resolution's referent resolves is
D1's question again, and building it is a toolkit write.

## D6 — sum the column, or delete the sentence

F6 is D1 again at the smallest possible scale. `verify-session-findings.sh
counts` covers the per-bundle cells; the sentence beneath them is the undeclared
remainder, and it is free, so it drifts.

**The check: for every `N bundles · M findings` in a document, locate the table
whose header carries a `Findings` column, count its data rows and sum that
column, and fail on either mismatch.** It belongs in `counts`, which is the check
a reader already believes is making this assertion.

### The false positive, measured — and the measurement expired

Run over the tree at Revision 238: **two such totals existed and both were wrong.
Two raised, two real, zero false positives.**

**Run again over the tree at Revision 249: zero raised.** One was repaired by
this session; the other was carried along by Revision 248's transfer of `0039`,
which rewrote that manifest for an unrelated reason. So the check now has **no
positives at all to demonstrate itself on**, and its first run against the tree
it would ship into would be silent.

**That is worth stating rather than presenting as a clean result.** A check whose
whole population is two, both since corrected — one of them by accident — has a
first run that proves nothing in either direction. It is still worth building,
because the two instances were wrong for days across six instruments and a person
found both; but nobody should read a silent first run as evidence it works.

`docs/rules/rule-enforcement-avenues.md` §2 puts this rule's avenue at **check**,
not guard: the fact is in the data, but a wrong total costs a reader's time
rather than corrupting the tree, and §6's bar for a refusal is not met.

**The false positive it will produce later** is a total written as **evidence** —
a `final-summary.md` or a handoff saying what a session held at the moment it
stopped, which is true of that moment and must not be recounted. None exists in
the tree today. The suppressor already exists and should be reused rather than
invented: `<!-- historical-record -->`, `0046`'s marker, which
`bin/verify-doc-paths.sh` already honours for exactly this reason.

**Not repaired here:**
`docs/sessions/session-management-re-evaluation-20260906-110105/findings-manifest.md`
is another session's file. Section 6 is *one file, one owner* — flag rather than
edit anything on the other side. Its total is 3 short and the rows are correct.

## D7 — check the two tables that display a derived value and are compared to nothing

F8 measures §6.1's surface at **5 disagreements in 612 rows**, and **all five sit
in classes nothing compares.** Two of the three such classes are one comparison
each.

**The check:** `verify-findings-structure.sh` already derives every bundle's
standing and every session's state from the data. It gains two assertions —

- every `<session>/findings-manifest.md` row's **`Standing`** cell equals the
  derived standing of the bundle it names;
- every `docs/sessions/INDEX.md` row's **`State`** cell equals the derived state of
  the session it names.

**It belongs in `structure`** because that is the check a reader already believes
is making this assertion: its own header says it verifies *"every findings
bundle's DERIVED standing agrees with the bundle's INDEX.md row"*, and a session
manifest displays the same value from the same derivation.

### It is not interim, and that changed while this was being composed

**Drift raised the caution and it was the right one**: an interim checker over a
surface somebody later generates becomes a checker over generated output, and
that is worth saying in the decision rather than discovering.

**`0043` D3 answered it at Revision 303.** §6.1 is *"a map, not a plan … not a
commitment to build a generator"*, and §7 already weighed generation and declined
it: *"Today drift is possible and the checkers catch it. Under generation drift is
impossible — and a bug rewrites forty files at once, silently, which nothing
catches."* **A detectable failure beats an undetectable one.** So the checker is
**the mechanism, not a backstop**, and D7 is a permanent addition rather than a
stopgap. **Recorded because the caution was raised before the ruling existed**, and
a later reader finding Drift's warning should find its answer beside it.

### The false positive to expect, measured before proposing it

**Run against the tree at Revision 303 by hand: 49 rows, 3 raised, 3 real, 0 false
positives.** All three are in F8's table.

**But the naive form of this check raises 13 and is wrong 8 times**, and the reason
is the one `0041` D1 has now met four times: **a status cell may legally be a
link.** §9 step 5 *requires* `` [`superseded`](<new-bundle>/) `` — always a link,
never the bare word — so an extractor reading the cell as a bare token reports
seven conformant `superseded` rows as broken, and a header-index lookup against
`docs/sessions/INDEX.md` reports eight sessions as stateless.

**Hold the implementation to 3 / 3 / 0 on this tree.** If it does not reproduce
that, the check is wrong and the tree is not — which is D1's own instruction,
applied to the sweep that produced the finding.

### Rejected

**A third assertion over `findings.md` member statuses**, which is F8's remaining
two rows. Rejected here and not forever: `structure` reads index and manifest
tables, and a per-member status lives inside a bundle document, which is
`headers`' surface rather than this one. **Putting it in `structure` would make
that script's stated subject false**, and its subject is the reason a reader trusts
its number. It is a separate decision against a separate script.

**A generator for the two tables**, which would make the comparison unnecessary.
Rejected on `0043` D3, which is not this bundle's to overturn, and on §7's
argument that an undetectable failure is worse than a detectable one.

**Failing the run rather than warning.** Not rejected — **accepted implicitly**,
because `structure` already fails on the equivalent comparison for a tree index
and a session manifest is not a lesser record. **A row here is always clearable**:
the data is authoritative and the display is a copy, so unlike `0047` F9's class
there is no permanent failure to install.
