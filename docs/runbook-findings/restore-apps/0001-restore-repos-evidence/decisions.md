# Decisions — Phase 11B evidence review

**Bundle:** `0001` · **Status when opened:** `in progress`, 2026-09-03.
Decisions are recorded per finding as they are made. A finding with no entry here
has not been decided.

---

## Finding 1 — the official run reports `repo-secrets` as blocked

### The evidence that settles it

The DMG was attached and every file it holds for the six hydrated repositories
was compared against the clone. **22 of 22 present.**

| Repository | Files in `repos-gitignored/<repo>/` | In the clone |
|---|---:|---|
| `indigo` | 1 | all |
| `reference-vault` | 5 | all |
| `enterprise-search` | 5 | all |
| `ese-policy-listener` | 6 | all |
| `ingestion` | 3 | all |
| `ingestion-listener-http` | 2 | all |

Run on the Mac by the owner, 2026-09-03, deriving the file list from the image
rather than assuming a shape — the first attempt at this check looked for `.env`
files and would have reported `ingestion` missing, because its secrets are
`ci/credentials.yml` and two `application-ncube-client.yml`.

**Decision 1.1 — the work succeeded and nothing is owed.** Finding 1 is a
reporting defect, not lost work. Step 6 did what it claims; the run that says
otherwise is `post-image-restore-20260903-004412`, and it is wrong about the
past rather than about the machine.

### How the fix was chosen

Four options were on the table, and the screenshot of the image's contents ruled
out the two that had looked strongest.

| Option | Rejected because |
|---|---|
| **A — procedural.** Pin the hydrate run official, or make it the last run | `pin` would make a run official whose status report is stale on every other count, and Step 9 still instructs the next operator to do the thing that caused this |
| **B — carry outcomes forward in `hydrated.md`**, as `.internal/sign-offs.sh` does for human answers | Destroys the one property that makes the file worth having: that it says what *a single run* did. A stage that genuinely re-blocked would read clean |
| **C — a cumulative phase-state file** beside `repo-restore-index.md` | Not wrong, and more machinery than the problem needs once E is available. May still have something to offer finding 3; not needed for this one |

**Decision 1.2 — verify, do not remember (option E).** A stage's outcome is
re-derivable from its source and its destination, and this holds for every stage
the phase runs:

| Stage | Source | Re-derivable |
|---|---|---|
| `clone` | the remote | already — the `Present` column does exactly this |
| `ignored-files` | `staged-ignored-files/live/<repo>/` | whenever the artifact volume is mounted |
| `project-metadata` | `app-settings-backup/intellij/project-metadata/…` | same |
| `repo-secrets` | the attached image | whenever it is attached |

So the phase does not need memory, it needs a comparison — which is the idiom
this workflow already prefers: `compare-restored-state.sh`, the state walk and
the before/after delta are all derived rather than remembered, and they compare
by `sha256` rather than by presence, which catches the case a presence check
misses — a file that exists but differs.

The rerun at Step 9 then stops destroying the record, because there is no
remembered record to destroy. The answer is re-derived, correctly, every time.

**Decision 1.3 — `unknown` when the source is unreachable (option D).** A run
that cannot reach the image reports *not evaluated*, not *evaluated and
unavailable*. It stops the record asserting something false in the one situation
where it cannot know.

### Decision 1.4 — the outcome vocabulary

`applied` becomes **`hydrated`**, and `would-apply` becomes **`would-hydrate`**
for symmetry. The flag is `--hydrate`, the helper is
`.internal/git/repo-hydrate.sh`, the file is `hydrated.md`; `applied` was the one
word in the family that did not match.

The full set after this finding is resolved:

| Outcome | Meaning |
|---|---|
| `hydrated` | the source's files are in the destination |
| `would-hydrate` | `--dry-run`; this is what would be done |
| `missing` | the source has files the destination does not — **new**, and only expressible under decision 1.2 |
| `unknown` | the source is unreachable, so nothing can be said — **new**, decision 1.3 |
| `pending` | the repository is not cloned, so there is nowhere to merge |
| `skipped` | there is no source for this key, which is normal |

`blocked` is retired: under a verify model there is no acting to be blocked, and
its only case — the image not attached — is exactly `unknown`.

**Existing artifacts keep the old words.** Every run on the volume that says
`applied` or `blocked` is dated evidence and is not retro-edited, the same rule
the workflow applies to every rename. Revision numbers in the manifest are what
lets a reader date the vocabulary.

### Decision 1.5 — an unreachable source is recorded, not refused

`--hydrate` runs the stage and records `unknown` rather than refusing. Owner,
2026-09-03. Refusing would make an unattached image an error for a phase that has
several other stages to get on with, and the run would then have nothing to say
about the stage at all — which is the failure this finding is about.

### Decision 1.6 — how strict the comparison is depends on the gap

Owner, 2026-09-03: **`sha256` when the stages ran close together in time,
presence when they did not.** A clone and a hydrate minutes apart should be
byte-identical to their source and any difference is a real defect; a clone from
two weeks ago whose secrets are being hydrated now sits in a working tree that
has had a fortnight to drift legitimately, and byte-comparing it would alarm on
every run for a file that is correct.

Rendered without an arbitrary time window, because a threshold in hours ages
badly and would have to be tuned:

> Compare by `sha256`. On a mismatch, read the destination file's modification
> time. If it has not been modified since the run that put it there, the mismatch
> is real — record `differs`. If it has, the drift is expected — record
> `hydrated`, and note the modification time in the detail.

That is per file rather than per run, which is finer than the rule as stated and
faithful to it: the strictness follows the file's own history rather than a
guess about the phase's. It also preserves the case the owner cares about — the
run immediately after hydrating, where nothing should have drifted and a
truncated copy is caught.

**Implementation note for `resolving`:** `stat` differs between BSD and GNU, and
the target is BSD. The modification time has to be read portably or the
portability lint will catch it — which is the sort of thing
`docs/cross-cutting-findings/0015-portability-lint-cannot-see-heredoc-context/`
exists to warn about.

**Finding 1 is now fully decided.** Six decisions, 1.1 through 1.6. It is not
`resolving` and no toolkit file will be touched for it until every other finding
in this bundle is decided too.

### Immediate action, independent of the fix

The image is attached now, so `--hydrate --stage repo-secrets` would record the
truth today under the current vocabulary. With 22 of 22 already verified present
it is a no-op that corrects the official run — worth doing, or worth skipping in
favour of the first run after the fix lands. Not decided.
