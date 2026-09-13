# Final summary — `entity-model-and-vocabulary-20260909-053548`

**Closed:** 2026-09-13, declared, at Revision 316  
**Owned:** 5 bundles, 62 members. **One answered, four released to `unclaimed`**  
**Revisions:** 269, 271, 273, 274, 275, 279, 285, 287, 290, 293, 296, 301, 303, 314, 315

The session was given the entity model: **what a session, a dossier and a member
are, and what a record of one may say.** It ends having settled the vocabulary and
most of the shape, and having answered one of its five bundles.

## The answer, if only one thing is carried forward

**Nothing derivable is stored, and the corollary is the expensive half: if it is
derived, something must derive it, and that something must run.**

The tree kept producing the same defect in different costumes, and every one was
a value that *had* a derivation nobody executed:

- **A standing derived from members**, restated as a rule in **six live
  documents** and executed in one function. The documents drift; the function
  cannot.
- **`stamp` has no automated caller anywhere in the tree.** Every derived value in
  the record is as current as the last time a person thought to run it.
- **`state-as-data` §6.1 is a complete derivation graph — eleven outputs, one row
  per source — and nothing executes it.** Zero generated regions exist.
- **A session closed by *crossing*** — every owned dossier terminal, no latch, no
  declaration — **and stayed in the assignment pool reading `closed`**, because
  the filter tested two of the five inputs the derivation uses.

**The last one is the shape of all of them.** A value changed because something
else did, nothing announced it, and the only reader that would have noticed was
sampling the wrong fields.

## Disposal, bundle by bundle

| | | |
|---|---|---|
| `0037` | `answered`, 9 members | **Retained.** Closed at Revision 301; F8 and F9 resolved and `stamp` derived the standing. Its F8 wording is what `0039` D23 carries |
| `0039` | **released**, 31 members, 20 open | The keystone and the most worked. F7, F12, F14, F15, F16, F19, F26, F27 decided or resolved. **D23 is decided and deliberately not carried out** — the provenance extraction across three rule documents, parked until the entity model settles |
| `0043` | **released**, 14 members, 11 open | The data-model reading. F14 resolved at Revision 303, where D3 ruled §6.1 *a map, not a plan*. **§11.3 — who may assert an edge — is unresolved and gates the edge work** |
| `0045` | **released**, 5 members, 5 open | **Never opened.** Its own session is F1's second live instance: created before the session, deriving `active` on day zero |
| `0048` | **released**, 3 members, 3 open | **Never taken up.** Arrived by transfer 2026-09-09; `progress` never left `untouched`, so the transfer never cleared |

**Released 2026-09-13 to `unclaimed`, no successor named**, on the owner's
instruction that a bundle this session had not answered goes back to the queue
rather than waiting on a session that is closing. §10a's four steps carried out
for each: manifest row removed, index row to `—` and `` `unclaimed` ``, session
counts decremented, and the disposal recorded here and in `findings-manifest.md`.

## What this session got wrong

Recorded because a summary listing only what worked is not a summary.

- **It claimed `.claude/hooks/` contained no enforcement**, in a review whose
  whole value was that every claim was measured. There is a PreToolUse hook that
  **denies**, and two PostToolUse hooks that report. The corrected reading is
  sharper than the wrong one — the machinery is bound to *a file was written*
  rather than *a status moved* — but the first pass asserted an absence it had
  not checked.
- **It called `iris/vocabulary.md` the documentation hub at in-degree 11**, having
  measured only `iris/`. With `docs/legend.md` and `.github/` in scope the hub is
  `legend.md` at 16.
- **It nearly overwrote a correct measurement of another session's.** Drift's
  field census put `SESSION.transcript` at 11/12; this session counted files, got
  1, and was about to replace the row. **The field holds a URL, not a file.**
  Checked before writing, and the row now records both facts.
- **It rewrote a session `metadata.json` and converted an escaped em dash to a
  literal one** — Revision 313's own recorded defect, committed in the session
  that had just read the record of it. Caught by comparing escape counts before
  and after, and redone.
- **It reported verified baselines against a stale patch, twice.** A write to the
  patch directory silently did not land, so the figures measured belonged to the
  previous composition. Caught by checksum both times.

**The pattern in the errors is one thing: a measurement taken over the wrong
population, then trusted because it was a measurement.** *The population is never
what you think* is on the page this session wrote, and it applied four times to
the session writing it.

## What it hands on

- **`0039` F6 and F21 are the live ones this session kept demonstrating and never
  decided.** F6 — *state names and state requirements live in different files* —
  was carried out at Revision 315 under the owner's override, which does not
  answer it. **F21 — *nothing checks that a vocabulary change reached the prose* —
  is now demonstrated six times**, the sixth by the revision that fixed the fifth.
- **The commission this session's last work exists to start.**
  `docs/ideas/big-picture.md` carries an architecture review of nine layers, a
  census of all 493 tracked files in four divisions, a provenance design, and a
  five-tier design order. **Its first tier is the two directory structures**, on
  the owner's decision that IRIS becomes its own versioned project.
- **`0056`**, `unclaimed` — a commission for a session state report, created at
  Revision 303 and never assigned. It is the only commission in the tree and has
  never been worked.
- **The disposition triple `{value, by, on}`** is designed and unbuilt. §6's
  migration gate fires over **358 records**, and the verifications are written
  before the retrofit, not after.
- **Two records name bundles this session released and are not this session's to
  edit.** `session-management-re-evaluation-20260906-110105` still lists `0043` in
  `ownedBundles` though its own manifest records the transfer away;
  `drift-and-the-write-boundary-20260909-053548` and
  `typed-bundles-architecture-20260908-204724` both still list `0048`.

## The measurement worth keeping

**Nine layers, and two of them have nothing behind them.** The Act layer —
*a transition happens and something knows* — has **zero code branches on
`crossing` or `declaration` and zero records carrying `by`**, and it is the single
absence behind four separately-recorded symptoms. Permission has one real gate,
bound to a file path, for one assistant.

**And the split that explains the rest: every derivation in the system runs off 53
`metadata.json` files, while the 94 markdown record files feed none.** Half the
record is reasoning only a reader can use — which is the correct design for
rationale and the wrong one for anything a check must see.
