# Supersession moves authority and leaves every citation behind

**Recorded:** 2026-09-07, after a session relayed a citation to a superseded bundle into a live question.  
**Session:** `allocation-and-inquiry-design-20260906-233205` (`session_015FpYVBF7dDoDrHfKDkq8fn`)  
**Severity:** F1 is the instance and F2 is the mechanism. Neither corrupts a record; both send a reader to a bundle `docs/legend.md` says offers nothing readable.  
**Felt at:** twelve documents citing `0028`, among them `0039` `findings.md` and `decisions.md`, `0041`, `0043` and `docs/session-management-findings/INDEX.md`  
**Scope:** session management. The fix is a marker or a check, not an edit to any reading.  
**Relates to:** `0030` — renames break citations by making the path stop resolving. This is the opposite: the path resolves, the content is intact, and only the authority has moved  
**Relates to:** `0044` — its F2 is the same shape at section granularity, a citation that resolves to a section that no longer exists

**Read:**

- `docs/legend.md`, *What another session may do* and the supersession rules
- `.github/session-management-instructions.md` section 9
- every document citing `0028`, and `0028` itself

Recorded `unclaimed`. Not owned, and no session should open it until the owner
assigns it.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Twelve live documents cite `0028`, which is superseded and closed to every session | `un-started` |
| F2 | Nothing distinguishes a citation to a superseded bundle from a citation to a live one | `un-started` |

## F1 — twelve documents cite a bundle nothing may read

`0028` was superseded by `0038` on 2026-09-06. Its tag reads `STATUS-superseded`
and `docs/legend.md` puts it in the row where **nothing is readable**.

It is cited from twelve documents outside its own directory, including `0039`'s
`findings.md` and `decisions.md`, `0041`'s three files, `0043`'s `findings.md`,
`0040`'s `resolutions.md` and this tree's `INDEX.md`.

**The instance that produced this reading.** `0039` F8's text cites `0028` F4
and `0028` D4. On 2026-09-07 a session relayed both into a live question put to
the owner without checking whether the bundle was still authoritative. The owner
caught it. The answer was not wrong — `0038` carries the same reading forward —
but the session had no way of knowing that from the citation.

`0028` is one bundle of seven superseded that day. The other six have the same
shape and are not counted here, because counting them is the work this bundle
would do if it were assigned.

## F2 — the path resolves, so nothing looks broken

Section 9 is deliberate that **the superseded `findings.md` is not edited** —
not to add a pointer to its replacement, not to repair a citation inside it. A
reading is retained by being left alone. That rule is right and this finding does
not argue with it.

The consequence is that supersession is recorded in exactly two places: the old
bundle's `STATUS-` tag, and its index row, whose Status cell links to the
replacement. **A citation elsewhere carries neither.** `` `0028` `` in a sentence
looks identical whether the bundle is live, superseded or withdrawn, and
`verify-doc-paths.sh` sees a resolving path — where it looks at all, which under
`0036` is not inside `docs/`.

The citation is also **correct as written**. `0039` F8 was written 2026-09-04,
two days before the supersession. Under the standing rule that evidence is never
rewritten to match a later state, that sentence must not be edited. **So the fix
cannot be a repair.** What is missing is a marker a reader meets at the point of
citation, or a check that reports live citations to terminal bundles — and which
of those, or both, is the decision this bundle owes.
