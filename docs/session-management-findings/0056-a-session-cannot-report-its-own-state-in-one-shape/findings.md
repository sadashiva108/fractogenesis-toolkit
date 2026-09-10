# A session cannot report its own state in one shape

**Recorded:** 2026-09-10, after the owner asked why every session's state report looks different and proposed a table.  
**Session:** `entity-model-and-vocabulary-20260909-053548` (`session_01LSgzo7EtPPVJ1gG8s4NVNW`)  
**Severity:** Q1 is load-bearing — without a shape, a printed report and a chat answer cannot be checked against each other, which is the whole point of asking for one.  
**Felt at:** every session hand-off in this tree; `iris/status.md`; `.internal/ai-scripts/session-management/measure-iris-status.py`  
**Scope:** session management. **This is a `commission`: its deliverable is a blueprint under `docs/architecture/`, not a script.**  
**Relates to:** `0043` — its F14 ruled that the projections are hand-maintained and a checker is the mechanism; a state report is another reader of the same map  
**Relates to:** `0050` — an instrument that is correct and reached by nothing is the failure this deliverable must not become  

**Read:**

- `docs/architecture/state-as-data.md` §6.1, the projection map
- `iris/status.md` and its generator, as the one worked example of a generated report in the tree
- `docs/sessions/*/findings-manifest.md`, as the shape a session state report overlaps

Recorded `unclaimed` and **deliberately not assigned.** The owner asked for the
commission to exist before anyone works it.

**This is the first `commission` in the tree.** Every dossier before it is
`findings`. That is stated because a capability with no instance is a claim, and
because writing this one surfaced what it costs — see Q3.

## Findings

| # | Finding | Status |
|---:|---|---|
| Q1 | What is the shape of a session state report — what does a dossier row carry, what does a member row carry, and what makes a member *recently changed* | `framing` |
| Q2 | Is the printed report and the chat-response schema one artifact or two, and if one, what makes a chat answer checkable against it | `framing` |
| Q3 | A commission's members are questions, and every checker requires them under a table headed **Findings** | `framing` |

## Q1 — what is the shape

The owner's sketch, which is the starting point and not the answer:

```text
Revision <N>

<Shape>

Number | Genus | Kind | Standing
0050   | findings | session-management | analyzing

  id  | statement | status
  F10 | Clearing a MISSING requires creating a permanent ORPHANED … | framing
```

**Three things it does not yet settle.** What *recently changed* means — a
revision window, a timestamp, or the session's own last write. Whether a dossier
with no recently-changed member appears at all. And whether the member statement
is quoted whole or truncated, given that statements run to two hundred characters
and a terminal is eighty wide.

**What it should read, and what it must not.** Every field in the sketch is
already in `metadata.json`. **The report must read the data, never the
projections** — reading `findings-manifest.md` would make the report a projection
of a projection, and `0043` F14 measured 2 of 31 manifest rows already drifted.

## Q2 — one artifact or two

The owner asked for something that can *either* be printed by a command *or*
serve as a schema a session answers in. **Those are the same shape and different
artifacts**, and the commission has to say so explicitly, because the failure
mode is building the printer and leaving the chat form to drift.

`iris/status.md` is the worked example: prose written once, measured blocks
regenerated between markers. **A session state report has no prose**, so the same
technique may or may not carry.

## Q3 — a commission's members are questions, and the checkers said Findings

Measured while creating this bundle, in a throwaway tree: `check` accepted its
`Q` members, and `verify-findings-headers.sh` reported **`no Findings table`**
while `verify-findings-counts.sh` reported the three questions as **one
finding**. Two checkers matched the letter `F`; the schema has said `Q` for a
commission since Revision 271.

**That half is fixed and is not this commission's** — `0039` F31 and D29, in the
same revision, because it is a toolkit write and `0039` owns the subject. The
checkers now match `[FQT]`, the range `MEMBER_PREFIX` defines.

**What is left is the vocabulary question, and it is this commission's.** The
table is still headed `## Findings` with a column reading `Finding`, over three
rows that are questions. The checkers no longer care. **A reader does.**

So: does a dossier's table take the vocabulary of its genus — `Questions` for a
commission, `Tasks` for a charter or remedy — or does one word cover all four
because the shape is what matters and the genus is already in the prefix? **The
state report this commission designs has the same choice**, one level up: whether
it labels a member column by genus or uniformly. Deciding it here decides it
there, which is why it is a question and not a note.
