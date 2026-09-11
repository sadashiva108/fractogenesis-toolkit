# Status — what is built, what is not, and how to re-measure it

> **Role.** The standing answer to *how far along is IRIS*, so a session does not
> have to read the whole tree to find out.
>
> **Authoritative for** nothing. Every number here is a measurement of something
> else, and the query that produced it is printed beside it. Where this document
> and the tree disagree, **the tree is right and this document is stale** — which
> is the failure mode it is designed to make cheap to detect.
>
> **Measured at Revision 301**, 2026-09-10, on the owner's machine in a Linux VM
> under Bash 5.1.16 and Python 3.10.12 — not the macOS Bash 3.2 target.

## Contents

- [1. The one-sentence answer](#1-the-one-sentence-answer)
- [2. The record, measured](#2-the-record-measured)
- [3. The actionable half has never run](#3-the-actionable-half-has-never-run)
- [4. What the instruments do not model](#4-what-the-instruments-do-not-model)
- [5. Fields written and never read](#5-fields-written-and-never-read)
- [6. What nothing checks, and cannot](#6-what-nothing-checks-and-cannot)
- [7. Five numbers this document already corrects](#7-five-numbers-this-document-already-corrects)
- [8. How to re-measure everything above](#8-how-to-re-measure-everything-above)

---

## 1. The one-sentence answer

**The reasoning half is real and running; the actionable half is four words, a
schema and nothing else.**

Everything below is that sentence with its evidence attached.

[&#8593; Contents](#contents)

---

## 2. The record, measured

<!-- MEASURED:RECORD -->
**57 dossiers, 229 members, 79 edges.** Sessions are excluded — `docs/sessions/`
holds session records, not dossiers.

| Genus | Dossiers |
|---|---:|
| `findings` | **56** |
| `commission` | 1 |
| `charter` | 0 |
| `remedy` | 0 |

| Member status | Count |
|---|---:|
| `resolved` | 95 |
| `framing` | 57 |
| `un-started` | 48 |
| `decided` | 29 |
| `withdrawn` | 0 |

| Edge kind | Instances |
|---|---:|
| `relates-to` | 31 |
| `carried` | 29 |
| `blocks` | 7 |
| `constrains` | 5 |
| `co-decides` | 4 |
| `successor` | 2 |
| `evidences` | **1** |
| `contradicts` · `duplicates` · `generalises` · `serves` | **0 each** |

**The manifest itself is the largest thing in the repository.**
`APPLY-MANIFEST.md` is **1.25 MB, 18,142 lines, 479 entries**. Every session reads it
to take a revision number.

| Root | Dossiers |
|---|---:|
| `docs/session-management-findings/` | 21 |
| `docs/cross-cutting-findings/` | 17 |
| `docs/runbook-findings/restore-repos/` | 7 |
| `docs/instruction-set-findings/` | 3 |
| `docs/runbook-findings/backup-repos/` | 1 |
| `docs/runbook-findings/restore-apps/` | 1 |
| `docs/runbook-findings/restore-docker/` | 1 |
| `docs/runbook-findings/reimage-prep-checks/` | 1 |
| `docs/runbook-findings/restore-access/` | 1 |
| `docs/runbook-findings/restore-git/` | 1 |
| `docs/runbook-findings/stage-loose-secrets/` | 1 |
| `docs/runbook-findings/restore-runtime/` | 1 |
| `docs/runbook-findings/capture-office-stability/` | 1 |
<!-- /MEASURED:RECORD -->

[&#8593; Contents](#contents)

---

## 3. The actionable half has never run

**Every dossier in the tree is `findings`** — section 2 carries the count. No `commission`, `charter` or `remedy` has
ever been written. The two words for the actionable genera were chosen the day
[shapes.md](shapes.md) was written and nothing has used them since.

Five things are missing before one could be, and each is named in
[shapes.md](shapes.md) section 9:

| Missing | What it blocks |
|---|---|
| **`serves` is in no closed set** | the edge that joins doing to reason cannot be validated — and **there is no closed set of edge kinds at all**, so no edge kind can be |
| **No authorization field** | *authorized as a separate act* is a rule with nothing to record it. `progress: pending` is the named candidate and is not implemented |
| **No task ordering within a dossier** | edges run between dossiers; nothing orders members inside one, which is what a charter or remedy is made of |
| **No constraint reasons** | the reason vocabulary is about correctness; descoping under budget or time has no word |
| **Nothing validates a reason** | in any vocabulary. [vocabulary.md](vocabulary.md) section 13 |

**A working prototype exists and is not in this repository.** At Revision 301 a
throwaway two-dossier model was built in session scratch — one `findings` with a
decision, one `remedy` serving it by a `serves` edge, carrying an `authorization`
block and an `after` field for task ordering. It ran: shape derived from genus,
member prefix enforced, the `serves` edge resolved to an accepted decision, the
tasks ordered topologically, and the remedy **correctly blocked** on
`writeCategory: evidence` with authorization `pending`. **Eleven negative cases
were run and all eleven gates fired**, with the control tree clean. That is
evidence the four-genus model holds when exercised, and evidence for exactly
which four fields the schema lacks: `authorization`, `after`, a closed edge-kind
set, and a `serves` kind inside it.

**Trials have never run.** `contradicts` stands at zero, `evidences` at one, so
[shapes.md](shapes.md) section 7 describes machinery that has executed once.

[&#8593; Contents](#contents)

---

## 4. What the instruments do not model

**Prism** — [prism.md](prism.md) section 6: length, readiness, staleness,
severity, edge truth, the topological invariant, the assignment patch, and
anything below the bundle. The design record claims *"every proposed order is a
valid topological order of the `blocks` and `evidences` edges"*; **no such check
exists** in `plan_findings_work.py`.

**Lumen** — [lumen.md](lumen.md) section 6 scores thirteen designed elements. The
`readiness` filter has no field on any member in the tree. Precedent entailment,
lifting, propagation and the six question modes are prose only — **none of the
six mode strings appears in the code**. `ask` writes nothing at all.

**This matters more than the other gaps** because the interview is the premise.
[README.md](README.md) section 4 argues IRIS inverts the capture bottleneck
because an instrument can ask the questions a person would not stop to write
down. Today it filters 191 findings to 29 and stops.

[&#8593; Contents](#contents)

---

## 5. Fields written and never read

**Of 107 distinct field paths across the two record types,
`plan_findings_work.py` reads 31.** The other **76** are written and never
consulted. [schema.md](schema.md) sections 6 and 7.

<!-- MEASURED:NULLS -->
**5 fields are `null` on every record that carries them.** Populations differ
— 57 dossiers, 229 members, 165 decisions — so each is stated against its own:

| Field | Null on | In [schema.md](schema.md) §6's list |
|---|---|---|
| `members[].statusReason` | 229 of 229 | yes |
| `members[].reopened` | 229 of 229 | yes |
| `members[].withdrawn` | 229 of 229 | yes |
| `decisions[].voidedReason` | 165 of 165 | yes |
| `subKind` | 57 of 57 | yes |
<!-- /MEASURED:NULLS -->

`statusReason` is the sharpest: `0039` D7–D12 named four reason fields, and **the
token `reason` appears nowhere in `plan_findings_work.py`.** The transitions that
would fill them have never fired — [lifecycles.md](lifecycles.md) records eleven
transitions described in a document and performed by no code.

[&#8593; Contents](#contents)

---

## 6. What nothing checks, and cannot

<!-- MEASURED:OUTCOMES -->
**4 decision outcomes are outside the closed set and nothing catches them.**
`vocabulary.md` names seven legal outcomes; the tree contains `replaced → D13` ×1, `replaced → D2` ×1, `replaced → D5` ×2.
`superseded` is the legal word for what they mean. **There is no `OUTCOME` check.**
<!-- /MEASURED:OUTCOMES -->

**Session identity, and therefore every load-bearing permission.** A guard sees a
tool call and a path, never which session is writing. Only the owning session
opens a finding; from `decided` onward only the owner records; `resolved` is
frozen. **None of that is enforceable**, and a check written against *who may*
would pass vacuously. `rule-enforcement-avenues.md` section 5.1 is explicit that
this is an argument for knowing the permissions are conventions, not for building
an identity mechanism.

**Edge truth.** A wrong `blocks` or `serves` edge produces a confidently wrong
ordering and every check passes. The prototype in section 3 reports this in its
own output rather than leaving it to be discovered.

**The rendered page.** Every checker reads markdown as text. `0042` F3 decided
against the remedy: no markdown parser, no third-party package, the floor being
zero non-stdlib imports across the tree.

[&#8593; Contents](#contents)

---

## 7. Five numbers this document already corrects

Stated because the point of measuring is to find these.

| Claim | Where | Measured |
|---|---|---|
| *"`evidences` and `contradicts` both stand at zero"* | [README.md](README.md) §9, [shapes.md](shapes.md) §9 | `evidences` is **1** — `0039/F28 evidences 0047/F1`, asserted at Revision 287 |
| *"67 tests"* | [README.md](README.md) §9 | **69**, after Revision 295 rewrote 74 lines of the test file. It was 70 from Revision 287 to 294 |
| The always-null field list | [schema.md](schema.md) §6 | the **list** is incomplete: section 5 marks every field it omits, `members[].statusNote` among them |
| *"191 findings"* | [lumen.md](lumen.md) §6 | the member count in section 2 — the population grew, and `readiness` is still absent from all of it |
| Layout on disk matches the documents | — | it does not; [directory-reference.md](directory-reference.md) §5 says how far apart, and **seven changes are queued behind `0052` F2**, the unwritten migration-plan requirement |

[&#8593; Contents](#contents)

---

## 8. How to re-measure everything above

**Sections 2, 5 and 6 are generated.** They sit between `<!-- MEASURED:… -->`
markers and are rewritten by
`.internal/ai-scripts/session-management/measure-iris-status.py`, so no number in
them is ever hand-carried across a rebase. Run it as
`python3 .internal/ai-scripts/session-management/measure-iris-status.py .` The equivalent query, to run by hand from the
repository root — it reads only `metadata.json` and writes nothing:

```bash
python3 - <<'PY'
import json,glob,collections
D=[p for p in glob.glob('docs/**/metadata.json',recursive=True) if '/sessions/' not in p]
g=collections.Counter(); ek=collections.Counter(); ms=collections.Counter()
outc=collections.Counter(); nulls=collections.Counter(); n_m=n_dec=0
LEGAL={"accepted","rejected","superseded","voided","deferred","withdrawn","split"}
for p in D:
    d=json.load(open(p)); g[d.get('genus')]+=1
    for k,v in d.items():
        if v is None: nulls[k]+=1
    for m in d.get('members',[]):
        ms[m.get('status')]+=1; n_m+=1
        for k,v in m.items():
            if v is None: nulls['members[].'+k]+=1
    for e in d.get('edges',[]): ek[e.get('kind')]+=1
    for x in d.get('decisions',[]):
        n_dec+=1; outc[x.get('outcome')]+=1
        for k,v in x.items():
            if v is None: nulls['decisions[].'+k]+=1
print("dossiers",len(D),"members",n_m,"decisions",n_dec,"edges",sum(ek.values()))
print("genus",dict(g)); print("status",dict(ms)); print("edges",dict(ek.most_common()))
print("illegal outcomes",{k:v for k,v in outc.items() if k not in LEGAL})
# each field against ITS OWN population -- a members[] field is not null-on-all
# because it matches the dossier count.
pop=lambda k: n_m if k.startswith('members[]') else n_dec if k.startswith('decisions[]') else len(D)
print("always-null",{k:v for k,v in nulls.items() if v==pop(k)})
PY
```

The rest:

| Number | Command |
|---|---|
| tests | `./bin/test-session-management.sh` |
| conformance baselines | `./bin/verify-session-findings.sh all` |
| manifest coverage | `./bin/verify-manifest-coverage.sh` |
| next free revision | `./.share/check-manifest-revision.sh` |
| portability | `./bin/verify-script-portability.sh` |

**If this document is more than a few revisions old, run the block above before
believing it.** `0052` F1 records that nobody can currently answer *how far along
is this* without a session reading the whole tree; this document is the attempt,
and it is only worth what its last measurement is worth.

[&#8593; Contents](#contents)
