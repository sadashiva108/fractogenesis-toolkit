# Apply Manifest

**Revision 74** — supersedes earlier manifests. `restore-repos` can close out on a partial restore, because a partial restore is what this phase actually does.

**Revision 73** — supersedes Revision 72 and earlier. The zsh expansion-order trap becomes an authoring rule instead of a lesson relearned per incident.

**Revision 72** — supersedes Revision 71 and earlier. `restore-access.md` Step 3 inventories every restored key, and an unmatched glob turns out to be a third way zsh breaks a pasted block.

**Revision 71** — supersedes Revision 70 and earlier. `restore-repos.md` gains Step 0, and its prerequisite recorder reads the audit rather than trusting it.

**Revision 70** — supersedes Revision 69 and earlier. Cloning belongs to `restore-repos.md`, so `restore-git.md` stops describing it.

**Revision 69** — supersedes Revision 68 and earlier. The identity spot-checks stop leaving the repository root, because leaving it is what broke them.

**Revision 68** — supersedes Revision 67 and earlier. Steps 3 and 5 verify their own output instead of leaving it for Step 7 to discover.

**Revision 67** — supersedes Revision 66 and earlier. `restore-git.md` stops sending work traffic to the wrong server, stops deleting Phase 10B's CA bundle path, and stops handing zsh comments it cannot read.

**Revision 66** — supersedes Revision 65 and earlier. The last phase ordinals leave the generated artifacts, and `PHASE` stops being a variable.

**Revision 65** — supersedes Revision 64 and earlier. `restore-git.md` gains its closing steps, and generated artifacts name runbooks rather than phase ordinals.

**Revision 64** — supersedes Revision 63 and earlier. `restore-git.md` gains Step 0, with the prerequisite rows and target set that make it real rather than ceremonial.

**Revision 63** — supersedes Revision 62 and earlier. The phase delta becomes `--point delta`, its own run, instead of a file emitted as a side effect of `--point after`.

**Revision 62** — supersedes Revision 61 and earlier. Two regressions I introduced: the state walker lost `observe()`, and the comparison dispatched on a runbook name against phase-ordinal arms. Both fixed; the per-phase internals are runbook-named now.

**Revision 61** — supersedes Revision 60 and earlier. The state plane gains its pre-image side: `bin/capture-system-state.sh`, a shared target list and walker, and a cross-erase delta beside the inventory diff.

**Revision 60** — supersedes Revision 59 and earlier. The phase delta moves out of the comparison tool and into the after-capture that produces its inputs; `compare-restored-state.sh` has one baseline again.

**Revision 59** — supersedes Revision 58 and earlier. The four boundary and state scripts are invoked by runbook name: `--phase 10B` becomes `--runbook restore-access`.

**Revision 58** — supersedes Revision 57 and earlier. The redundant `post-image-` prefix is gone from every lineage under `reimaged-system/`; 19 runs migrated.

**Revision 57** — supersedes Revision 56 and earlier. A diff and a delta are different questions and now have different lineages; the three existing runs are migrated.

**Revision 56** — supersedes Revision 55 and earlier. The comparison's legend explains only the verdicts the run produced, because a static list of every possible verdict reads as findings.

**Revision 55** — supersedes Revision 54 and earlier. The `sslverify` legend overstated its blast radius, named the wrong phase as the next risk, and Step 8 contradicted Step 3 about where `~/.gitconfig` comes from.

**Revision 54** — supersedes Revision 53 and earlier. A row a later runbook owns no longer counts as this phase's gap, and an inverted row stops printing `MISSING` beside a pass.

**Revision 53** — supersedes Revision 52 and earlier. Boundary and state documents are titled by runbook rather than by phase ordinal, because ordinals renumber and dated artifacts are never regenerated.

**Revision 52** — supersedes Revision 51 and earlier. The comparison becomes its own step, mirroring `restore-runtime` Step 10, and the closing step is what is left.

**Revision 51** — supersedes Revision 50 and earlier. `compare-restored-state.sh` reads any pre-image capture rather than only the system inventory, gains a Phase 10B probe set including byte-exact `jssecacerts` verification, and `--against before` is implemented.

**Revision 50** — supersedes Revision 49 and earlier. `bin/` gains a legibility section instead of a reorganisation — and the anchor checker turned out to be skipping the repository's most common link.

**Revision 49** — supersedes Revision 48 and earlier. Item 0 decided: the three restore recorders graduate to `bin/` and the carve-out is deleted. `restore-access.md` gains the closing step it never had — after-state and exit checklist.

**Revision 48** — supersedes Revision 47 and earlier. A later-phase dependency is now named in the prose above the block instead of in the block's output, and the rule is recorded.

**Revision 47** — supersedes Revision 46 and earlier. Two long troubleshooting blocks moved out of their steps into the Troubleshooting section and linked in the specified callout form; the leaf-versus-root advice there no longer contradicts Step 5.

**Revision 46** — supersedes Revision 45 and earlier. The zsh comment rule was recorded too narrowly: a whole-line `#` comment breaks a pasted block too, and an apostrophe in one silently eats the commands below it.

**Revision 45** — supersedes Revision 44 and earlier. The CA bundle is system roots plus the corporate root, because every consumer replaces its trust store rather than adding to it; the smoke tests now force the bundle they claim to test; and `bin/restore-access.sh` exists.

**Revision 44** — supersedes Revision 43 and earlier. Step 7's smoke tests report why a tool failed, Step 8 stops calling an editor that Phase 12 has not installed yet, and Step 9 says what to do with what it found.

**Revision 43** — supersedes Revision 42 and earlier. `verify-doc-paths.sh` now checks wikilink anchors and gained `--all`; three broken anchors and four stale path references fixed.

**Revision 42** — supersedes Revision 41 and earlier. Step 7 identifies the root certificate by testing it rather than by recall, stages the CA bundle so a failed export cannot truncate the file five tools depend on, names the bundle path once instead of eight times, the hand-restore table says which categories a later phase owns, and conditional DMG categories are no longer described as nonexistent.

**Revision 41** — supersedes Revision 40 and earlier. Bare `<placeholder>` redirections removed from command blocks, and Step 6's TLS host chosen by issuer.

**Revision 40** — supersedes Revision 39 and earlier. Comparison freshness is now
computed rather than assumed, Step 6 gained a real validation and Step 7 the
variable it always depended on, and trailing `#` comments are out of command
blocks because interactive zsh does not treat them as comments.

**Revision 39** — supersedes Revision 38 and earlier. Runbook revision-archaeology removed, and the rule against it recorded.

**Revision 38** — supersedes Revision 37 and earlier. `restore-access.md` Step 6
rewritten around the image's real per-JDK layout, the JDK version un-hardcoded
everywhere it executes, and the Step 6 trust-store choice surfaced in
*Confirm Your Intent*.

**Revision 37** — supersedes Revision 36 and earlier. `restore-access.md` Steps 4 and
5 rewritten around what enrolment already installed and around the root-versus-
intermediate distinction, the matching exit-checklist row corrected, and
`reimage-checklist.sh --phase post` repointed at the run index (slice 3b).

**Revision 36** — supersedes Revision 35 and earlier. The Phase 9 first-boot bundles
move off the `reimaged-system/` root into a `restarts/` category on the run
index, their producer is converted to write there, `check_10A` stops reading a
retired pointer, and three defects in `restore-access.md` Steps 3-4 are fixed —
one of which was blocking a live Phase 10B run.

**Revision 35** — supersedes Revision 34 and earlier. One new file,
`bin/record-restore-state.sh`, plus two dangling doc references repointed. It unblocks the Phase 10B before-state capture, which expires the
moment Step 3 writes `~/.ssh`.

**Revision 34** — supersedes Revision 33 and earlier. Revisions 33 and 34 were applied
directly to the working tree rather than staged for copying, so the tables below
describe Revision 32's file set; 33 and 34 list their own files in their
sections. Revision 33 adds `bin/verify-script-portability.sh` and its two
suppression sites. Revision 34 clears the findings batch across
`.internal/artifact-runs.sh`, both boundary recorders,
`.internal/restore/compare-restored-state.sh`,
`.internal/git/stage-ignored-files.sh`, and four documents.
`bin/compare-runtime-versions.sh` is now deleted, completing the move Revision
32 described but did not carry out.

**Revision 32** — six files and one deletion: the Phase 10B blocker batch in
`restore-access.md`, and slices 1–3a of the post-image artifact restructure —
`.internal/artifact-runs.sh` (new), both boundary recorders on it, and
`bin/compare-runtime-versions.sh` generalised into
`.internal/restore/compare-restored-state.sh`.

Cumulative since Revision 1: the `$FRACTOGENESIS_HOME` substitution round · the
Phase 8 Step 3 component-list rewrite and Step 5 update-reboot removal · a
`grep -E` fix in Step 4 · four new raw captures in `record-enrollment.sh`
(managed-app expectations, Keychain identities, package receipts, launchd
components, system extensions) with the expectation source corrected to the
company-scoped inventory · the workspace-fragment gap closed across Phases 6A,
8, and 9 · Phase 16 — Post-Image Time Machine · the toolkit-environment
reference · safety guards equalised across the four Phase 11B/12 plan-note
emitters · `bin/compare-runtime-versions.sh` replacing Phase 10A Step 9's manual
pass · Obsidian moved to Phase 10A Step 5 · and Homebrew's install hardened
against the silent-failure piped form.

**35 files: 4 created, 31 modified.** Revisions 28 and 29 change two of them,
`restore-access.md` and `.internal/restore/record-restore-prereqs.sh`;
everything else is unchanged from Revision 27.

Every file changed or created in this session, with its destination in
`fractogenesis-toolkit`.

> **Working Phase 10B right now?** Two files: `restore-access.md` (Revision 28)
> and `.internal/restore/record-restore-prereqs.sh` (Revision 29). Both are safe
> to apply on their own and depend on no other change. Note the recorder's
> destination is `.internal/restore/`, not `bin/` — it is a helper, invoked with
> `bash`, so it needs no executable bit.

> **Working Phase 10A right now?** Four files:
> `restore-runtime.md`, `bin/compare-runtime-versions.sh`,
> `bin/init-shell-env.sh`, and
> `.internal/restore/record-restore-prereqs.sh` — note the last one goes under
> `.internal/restore/`, a new subdirectory, not `bin/`. The rest can be applied as you reach their phases,
> which also spreads the verification out.

Replace wholesale rather than hand-merging — most files carry changes from
several separate rounds of work, and splicing them by hand is how the duplicate
`### Step 3` heading got introduced earlier.

---

## Created

| File | Destination |
|---|---|
| `toolkit-environment-reference.md` | `references/toolkit-environment-reference.md` |
| `init-shell-env.sh` | `bin/init-shell-env.sh` |
| `compare-runtime-versions.sh` | `bin/compare-runtime-versions.sh` |
| `record-restore-prereqs.sh` | `.internal/restore/record-restore-prereqs.sh` |
| `record-restore-exit.sh` | `.internal/restore/record-restore-exit.sh` |

`init-shell-env.sh` needs no `chmod +x` if it reaches a Mac through
`bootstrap.sh`, which chmods `bin/` on extract. Commit it with mode 100755 so
`git archive` carries the bit onto the jump drive.

---

## Modified — repo root

| File | Destination |
|---|---|
| `reimaging-guide.md` | `reimaging-guide.md` |
| `reimaging-scripts-guide.md` | `reimaging-scripts-guide.md` |
| `restore-strategy-guide.md` | `restore-strategy-guide.md` |
| `prepare-artifact-root.md` | `prepare-artifact-root.md` |
| `reimage-guide-access.md` | `reimage-guide-access.md` |
| `run-time-machine.md` | `run-time-machine.md` |
| `enroll-and-stabilize.md` | `enroll-and-stabilize.md` |
| `verify-reimaged-system.md` | `verify-reimaged-system.md` |
| `restore-runtime.md` | `restore-runtime.md` |
| `restore-access.md` | `restore-access.md` |
| `restore-repos.md` | `restore-repos.md` |
| `restore-apps.md` | `restore-apps.md` |
| `restore-home.md` | `restore-home.md` |
| `reimaged-system-checks.md` | `reimaged-system-checks.md` |

## Modified — `references/`

| File | Destination |
|---|---|
| `master-directory-reference.md` | `references/master-directory-reference.md` |
| `restore-file-reference.md` | `references/restore-file-reference.md` |
| `reimaged-system-evidence.md` | `references/reimaged-system-evidence.md` |

## Modified — `bin/`

| File | Destination |
|---|---|
| `record-enrollment.sh` | `bin/record-enrollment.sh` |
| `restore-apps.sh` | `bin/restore-apps.sh` |
| `restore-docker.sh` | `bin/restore-docker.sh` |
| `restore-intellij.sh` | `bin/restore-intellij.sh` |
| `record-reimaged-system.sh` | `bin/record-reimaged-system.sh` |
| `reimage-checklist.sh` | `bin/reimage-checklist.sh` |

---

## Revision 74 — a phase with no fixed finish line

`record-restore-exit.sh` gains `check_restore_repos`, and the shape of it is the
point. Every other phase in this workflow finishes: the certificates are trusted
or they are not, the identity is written or it is not. Phase 11B does not. The
operator restores the repositories they need today and comes back for the rest,
which makes "every repository present" the wrong exit question — on this machine
the honest answer is 9 of 27 and that is a correct state, not an incomplete one.

So the automated rows check what *is* there rather than counting what is not:

- **Clone roots present.** The generated clone script creates them, so an absent
  root means no clone from this phase has ever run.
- **Repositories on disk.** Reported, not graded. The right count is a decision
  this recorder cannot make.
- **Each repository sits under the root matching its remote.** This is the row
  that earns the function. A repository's root decides its identity through
  `includeIf`, so a work repository cloned under the personal root commits with
  the personal address and offers the personal key to a host that will reject it
  — and nothing else in the workflow looks. It compares each clone's `origin`
  host against the host expected for the root it sits in.

Three manual rows carry what cannot be automated: repositories left unrestored
are a decision rather than an oversight, carry-forward is reconciled for what was
actually restored, and repositories the audit recorded with **no remote** are
resolved — recovered from a backup or deliberately let go, since nothing can
clone them.

The unrestored-repositories row is worded to permit returning later. Coming back
for more is the expected workflow; leaving without deciding is the failure it
prevents.

Verified by building a four-repository fixture with one deliberate mistake — a
corporate-hosted repository under the personal root — and confirming the
placement row names it and passes the other three.

---

## Revision 73 — the rule the two incidents were both instances of

`runbook-prompt.md` already forbade `#` comments in pasted blocks and bare
`<placeholder>` redirections. Both are consequences of the same fact, which the
prompt never stated: **zsh evaluates expansion before it evaluates anything the
line is trying to do.** Two failures this session were the same trap wearing
different clothes.

The comment `… (the secure default).` failed with `no matches found` — glob
expansion, raised before `#` handling was ever reached, which means removing the
`#` alone would not have saved that line. The key-inventory loop opened with the
Bash idiom for an empty directory, `[ -e "$f" ] || continue`, which zsh never
executes because it raises the error during expansion and never enters the loop.
Both were diagnosed from first principles at the time, twice, because the prompt
recorded the symptoms and not the cause.

The prompt now carries the cause as its own rule, with the `find | while read`
form as the portable replacement, and the validation checklist gained an item
covering all three symptoms together — comments, bare placeholders, and unquoted
glob metacharacters — since one check catches what three separate readings kept
missing.

A note on why this is worth a rule rather than a fix. A guard placed *inside* the
construct is not merely ineffective in zsh, it is misleading: `[ -e "$f" ] ||
continue` reads as though the empty case is handled by someone who has thought
about it. The next author has no reason to look closer. That is the failure mode
a prompt exists to prevent, and it is why the entry names the evaluation order
rather than listing two more forbidden characters.

---

## Revision 72 — what came back is not what is still used

`restore-access.md` Step 3 restores SSH material from the image and then tested
reachability. Nothing between those two points asked what had actually been
restored. Nothing deletes a rotated-out key, so the image returns every key the
machine has ever had, and the operator has no way to tell the live ones from the
sediment — on this machine, four keys came back and the config referenced two.

Step 3 now inventories them between listing the config's hosts and testing an
alias, reporting the three facts that separate a live key from a dead one: the
fingerprint (what you compare against each account), whether `~/.ssh/config`
names it (the best evidence of what the previous machine used), and whether it
carries a passphrase.

The ownership split with Phase 11A is stated rather than implied.
`restore-git.md` Step 2 fingerprints the two keys `reimage.env` names; this is
the wider inventory that tells you which two those should be. Different
questions, so not a duplicate — and the runbook says which is which so the next
edit does not collapse them.

The step also refuses to conflate two claims that look alike: a key that is
unreferenced *locally* has not been shown to be unregistered *remotely*, and only
the second makes it safe to delete.

**A third zsh failure mode, found by running the block.** The first draft opened
with the Bash idiom for a possibly-empty directory:

```bash
for pub in "$HOME"/.ssh/*.pub; do
  [ -e "$pub" ] || continue
```

In Bash an unmatched glob passes through as the literal pattern and the guard
catches it. In **zsh** an unmatched glob is an *error* — `no matches found` —
raised during expansion, so the loop never starts and the guard never executes.
The block is pasted into interactive zsh, which makes the idiom not merely
useless but actively misleading: it looks like the empty case is handled.

This is the same NOMATCH behaviour recorded in Revision 67, where a parenthesis
inside a comment aborted a line before it reached comment handling. Two
sightings, two different triggers, one cause — worth naming as a class rather
than as two incidents: **zsh evaluates globbing before it evaluates anything the
line is trying to do**, so a Bash-derived guard placed *inside* the construct is
already too late.

The block iterates `find` output instead. Verified under OpenSSH 9.6 against a
key set shaped like this machine's — encrypted and unencrypted, referenced and
orphaned — and against an empty directory, where it prints nothing and exits 0
rather than erroring.

---

## Revision 71 — Step 0 for Phase 11B, and three rows about the audit

`restore-repos.md` opens with **Step 0 — Record Prerequisites and the
Before-State**, matching the shape `restore-git` now has. Four of its rows come
straight from *Prerequisites*, derived so the two cannot drift: toolkit root,
`restore-git` closed out, clone roots set and distinct, and the audit pointer
resolving to a run that is on disk.

The other three exist because `bin/restore-repos.sh` is read-only and always
produces a status bundle. A run against an empty or damaged audit does not
error — it reports nothing to do, which reads as success. That is the silent
failure the prompt describes, and it earns the step outright.

- **Audit has repository rows.** An empty `repos.tsv` yields an empty clone
  script and zero counts everywhere downstream.
- **Audit remote URLs are URLs.** `capture-repo-audit.sh` builds that column from
  `git remote -v`, whose output is itself tab-separated, and writes it into a TSV
  unsquashed — so the URL lands in a later column and the remote *name* is left
  where the URL belongs. `restore-repos.sh` hands that field to
  `rewrite_remote_for_host`, so the damage surfaces as malformed clone commands
  rather than as an error. On this machine's audit the row FAILs at 25 of 27.
- **Every repository has a remote** and **No repository spans both hosts** are
  WARNs, because they name decisions rather than defects. Two repositories here
  have no remote at all and cannot be cloned by anything; two have remotes on
  both the corporate and the public host, where the host is what decides the root
  everywhere else.

The state targets are `shallow`, not `tree`. This phase restores 27 checkouts,
and a recursive walk would hash every file in all of them to answer a question
that is one row per repository. At depth 1 the before-state is two empty roots
and the delta against the after-state is literally the list of what was restored.

**A defect caught by running it against real data.** The audit-pointer row
resolved `latest-run.txt` as `$audit_root/runs/$(cat …)`, but the pointer already
stores its path relative to `repo-audit-reports/` and carries the leading `runs/`
segment — so the row FAILed on a perfectly good audit by looking for
`runs/runs/pre-image-…`. `bin/restore-repos.sh` strips that segment before
joining; this row now does the same, with the reason recorded at the strip. A
gate that disagrees with the script it gates is worse than no gate.

Verified against the real pre-image audit rather than a fixture: all eight rows
fire, and the counts they report — 27 repositories, 25 damaged URL cells, 2 with
no remote, 2 spanning both hosts — match what the same facts produce when read
out of `repo-audit-summary.txt` by hand.

Still open, and deliberately not in this revision: the cloning **decision index**,
the closing after/exit capture step, and the pass over `.github` prompts and
templates. A decision index is not a section the runbook template defines, so
that gap is worth amending at the source rather than improvising here.

---

## Revision 70 — one runbook owns cloning

`restore-git.md` Step 8 handed out `git clone` templates. `restore-repos.md`
already had **Step 2 — Review the Emitted Clone Commands**, **Step 3 — Execute
the Clone Commands**, and a troubleshooting entry for a personal repo whose
remote points at the default host. The same job, described twice, in two
runbooks — and the second description was the better one: it explains *why* a
remote goes unrewritten (the pre-image inventory recorded an HTTPS URL) rather
than only how to fix it.

So this is a deletion, not a move. Step 8 is gone; Steps 9 and 10 become 8 and 9,
with the table of contents and the "continue to" navigation following them. The
troubleshooting section Step 8 was the only link into went with it, since
`restore-repos.md` carries the better copy.

What did *not* exist anywhere is a pattern for cloning **one** repository by
hand, which is what an operator wants when proving the plumbing works or picking
up a single repo before the batch is ready. That is now in `restore-repos.md`
Step 3, written to name the destination rather than `cd` into the root — the same
lesson as Revision 69, applied on the way past: a block that changes directory
loses a directory-scoped environment and everything after it.

**The rule it now states was learned from the data.** Which root a repository
belongs in is decided by its remote host, not by where it lived pre-image. This
machine's audit makes the case: `reference-vault` and `indigo` both sat in the
old `Development/documentation` root and both are hosted on the corporate
Enterprise server. That directory was named for its contents, not for an
identity, so it collected both kinds. Cloning either under the personal root
would have `includeIf` author commits with a personal address and
`core.sshCommand` offer the personal key to a host that rejects it — a failure
that looks like a key problem and is a placement problem.

`restore-git.md` now ends where its scope statement always said it did: identity
plumbing, validated, handed off. It no longer describes work it does not do.

---

## Revision 69 — `cd ~` was the bug

The three throwaway-repo checks in Steps 5 and 7 all ended the same way: `cd ~`,
then a guarded `rm -rf` of the scratch directory. On a machine using `direnv` —
this one does — that sequence cannot work, and the reason is worth writing down
because nothing about it is visible in the block.

`direnv` scopes `reimage.env` to the toolkit directory. `cd ~` unloads it. By the
time the next line runs, `$GIT_PERSONAL_REPO_ROOT` is empty, the `[ -n ... ]`
guard added in Revision 67 correctly declines to run `rm -rf "/test-repo"`, and
the scratch repository is left on disk. Silently, every time. Three had
accumulated — `orah/test`, `shiva/test`, `shiva/test-repo` — and the giveaway had
been sitting in the operator's terminal for several runs: `git init` reporting
**Reinitialized existing** repository where a first run should say *Initialized*.

The same unload produced a worse outcome once. Running the block from `$HOME`
rather than the repository root meant `source ./reimage.env` failed, the root was
empty, `mkdir` and `cd` both failed against `/test` — and `git init`, with nothing
to stop it, ran in the home directory. `~/.git` makes every directory under
`$HOME` part of a repository.

**All three checks now run the `cd` in a subshell and never leave the root.**

```bash
if [ -z "${GIT_PERSONAL_REPO_ROOT:-}" ]; then
  echo "GIT_PERSONAL_REPO_ROOT is not set — run this from the repository root"
else
  mkdir -p "$GIT_PERSONAL_REPO_ROOT/test-repo"
  ( cd "$GIT_PERSONAL_REPO_ROOT/test-repo" && git init && git config --show-origin user.email )
  rm -rf "$GIT_PERSONAL_REPO_ROOT/test-repo"
fi
```

Three failures close at once. The parent shell stays put, so a directory-scoped
loader keeps the environment and the cleanup actually runs. The operator ends
where they started rather than in `$HOME`. And an unset root can no longer reach
`git init` at all — the branch reports the real problem, which is that the block
was run from the wrong directory.

**Step 7 now says to confirm the cleanup.** A leftover scratch repo in a clone
root is not cosmetic: `backup-repos.md` discovers repositories with `find <root>
-type d -name .git`, so an abandoned `test/` is counted as a real repository by
the Phase 11B audit and by every comparison derived from it.

A note on the guard that did not survive. Revision 67 put `[ -n "$VAR" ]` on the
`rm -rf` because an empty root expands the path to `/test-repo`. That reasoning
was right and the guard did its job — it is visible in the operator's transcript
refusing to fire. But guarding the destructive line treats the symptom. The
variable was empty because the shell had moved, and once it has moved, every line
after it is wrong: the guard prevents the bad delete and thereby guarantees the
leak. Not leaving is the fix; the empty-variable branch is now a diagnostic
rather than a bandage.

Verified in the container by running the new block both ways: from a repo root
with the root set, it printed the personal origin, returned the shell to where it
started, and left nothing behind; with the variable unset it printed the message
and created no `.git` in `$HOME`. `verify-doc-paths.sh --all` clean.

---

## Revision 68 — a step that writes a file should read it back

Two failures this session had the same shape: a step wrote a file, said nothing,
and the mistake surfaced two steps later wearing someone else's symptom.

`~/.ssh/config` was populated by pasting the Step 3 template as *text* rather
than running it, so every `${GIT_*_GITHUB_HOST}` stayed literal. The file looked
plausible to read. `~/workspace/shiva/.gitconfig` was never written at all
because only Step 5's validation block got run, and Git ignores a missing include
file silently — the first sign was a work email appearing in a personal repo,
which reads as an `includeIf` pattern bug rather than a missing file.

Neither is a Step 0 case: nothing here is a *prerequisite* that fails quietly,
it is the step's own output going unchecked. So the checks go where the writing
happens.

**Step 3 now ends with `ssh -G`.** Reading the file back with `cat` would not
have caught this — the literal `${GIT_WORK_GITHUB_HOST}` looks like the runbook.
`ssh -G` prints the configuration *after* parsing, which is the only view that
distinguishes a hostname from a string that resembles one. Verified in the
container against both a correct config and a deliberately unexpanded one; the
grep matches, and the broken case reports `hostname ${git_work_github_host}` —
**SSH lowercases the value**, so it does not appear in the file's own spelling.
That detail is in the runbook, because a check the reader cannot match to its
output is a check they will not trust.

**Step 5 now ends with `cat`**, adopting the operator's own form of the block.
The `cat` distinguishes three outcomes that were previously one: file written
correctly, file not written, and — the one nobody looks for — file written with
the identity blank because `reimage.env` never loaded. Git includes a blank
`[user]` block as happily as a correct one.

**`--show-origin` on all three identity checks**, in Steps 5 and 7. `git config
user.email` answers the wrong question. The question is which file won, and
without the origin a missing override file and a non-matching `gitdir:` pattern
produce identical output. The two Step 7 spot-checks now also state what a
*wrong* origin means in each direction: the personal-root file winning inside the
work root means the pattern is too broad, which nothing previously checked.

**One request declined.** The operator's block opened with `cd
~/fractogenesis-toolkit`. It is not in the runbook: repo-root is stated once in
`reimaging-guide.md` → Core Assumptions and again in each runbook's
Prerequisites, and `copilot-instructions.md` says command blocks start at the
command. The path is also about to move under `~/workspace/shiva/`, so hardcoding
it would bake in a rename. The `cat` covers the same risk without the constant —
run from the wrong directory, the identity comes back blank and visible.

Verified in the container: `verify-doc-paths.sh --all` clean, no shell-level `#`
left in any command block in this runbook, and the `ssh -G` check exercised both
ways under OpenSSH 9.6. The `git config --show-origin` behaviour is unchanged
from the run the operator already did on the Mac, which returned
`file:/Users/dkittrell/workspace/shiva/.gitconfig`.

---

## Revision 67 — three defects the operator found by running it

All three were caught mid-phase, by the person following the runbook. Each is
recorded here with the symptom, because the symptom is what made it visible.

**`HostName` was hardcoded to `github.com`.** Step 3 wrote both host blocks as
`Host ${GIT_*_GITHUB_HOST}` / `HostName github.com`, which is coherent only under
the model the glossary described: one GitHub, two identities, told apart by
invented aliases like `github-personal`. That model cannot express two *servers*.
With work on a GitHub Enterprise instance, `git@github.gaig.com` opened a
connection to public github.com and offered it an Enterprise key — and the
resulting `Permission denied (publickey)` points at the key, which is exactly
where this runbook's troubleshooting section sends the reader. Both blocks now
derive `HostName` from the same variable as `Host`, so the value has to be a real
resolvable host. The alias mechanism is gone rather than kept alongside: nothing
in this workflow uses it, and a second way to express the same thing is a second
place for it to be wrong. If two identities ever share one server, that is the
point to add an explicit hostname key, not before.

The supporting text taught the same wrong model and moved with it — the glossary
row, the two env descriptions that called these values "SSH host alias
(typically `github-personal` or similar)", and the example values, which now show
an Enterprise host beside `github.com` instead of two spellings of one server.

**Step 4 deleted `http.sslCAInfo`.** `cat > ~/.gitconfig` truncates, and
`restore-access.md` Step 7 writes the corporate CA bundle path into that file.
The handoff was even documented — `restore-access.md` line 201 reads
`~/.gitconfig # NOT written here — Phase 11A restores it; Step 7 may add
http.sslCAInfo` — so restore-access knew about the exception and restore-git did
not. Step 4 now reads the value before the rewrite and puts it back after, which
keeps `restore-access` the only owner of the bundle path; nothing here needs to
know where the bundle lives.

Worth recording because of where it would have led. The exit checklist FAILs with
*"`git ls-remote` failed — check `git config --get http.sslCAInfo`; see Step 7"*,
sending the reader back to the previous phase. The nearest fix to hand is then
`GIT_INTERNAL_TLS_SKIP_HOST` — disabling TLS verification to compensate for a CA
path this runbook had just deleted. `compare-restored-state.sh` already warns
against exactly that inversion.

**Comments in command blocks, demonstrated rather than theorised.** Pasting Step
4 into interactive zsh produced:

```
zsh: command not found: #
zsh: command not found: #
zsh: no matches found: (the secure default).
```

The first two are the documented `#` failure. The third is a sharper edge and had
not been recorded: `(the secure default).` never reached comment handling at all —
zsh read the parentheses as a glob, matched nothing, and aborted the line during
expansion. Parentheses in a command-block comment fail earlier and louder than a
bare `#`. Nine shell-level comment lines removed across Steps 4, 5, 6 and 7, each
one's content moved into prose above its block, where the reason belongs anyway.
Comments *inside* heredocs were left alone: that text is file content, not shell
input, and the `config.local` header comments are correct where they are.

**Two `rm -rf` calls guarded while in there.** The throwaway-repo checks in Steps
5 and 7 end with `rm -rf "$GIT_*_REPO_ROOT/test"`, which expands to `/test` if the
variable is unset. A `${VAR:?}` guard would be the reflex and would not work: in
an interactive shell it prints its error and lets the following lines run. The
guard is on the `rm` itself.

Verified in the container: `verify-doc-paths.sh --doc restore-git.md` clean at 34
anchors, a re-scan finds no shell-level `#` left in any command block, and the
Step 4 preserve-and-restore was exercised both ways — with a prior `sslCAInfo`
(returned intact) and without one (stays empty). The operator's own run confirms
the same on the Mac.

---

## Revision 66 — the ordinal is not a fact worth recording

Revision 65 argued that one phase number was safe to keep: *"(Phase 11A at the
time of this run)"*, on the `Pairs with` line, records what was true when the run
happened rather than asserting something that can go stale. The argument holds
and the line still had to go. A reader of a boundary artifact does not need to
know which ordinal the phase carried that week — the runbook name identifies it
and keeps identifying it — and leaving one ordinal in the output meant the answer
to "do these artifacts use phase numbers" was *mostly not*, which is the answer
that costs the most to act on. The line is now:

```
Pairs with [[restore-git|restore-git.md]].
```

**`PHASE` is gone as a variable.** With the last emitted use removed, the
`PHASE="11A"` assignment in each of the four resolve tables was dead weight that
still had to be maintained on every renumber. The tables now map runbook to
runbook:

```
restore-git)    PHASE_RUNBOOK="restore-git.md" ;;
```

**Five strings the Revision 65 sweep missed**, all of them artifact-facing rather
than comments, which is why a grep for `Phase [0-9]` did not distinguish them:

- `PHASE_NEXT` in `record-restore-exit.sh` carried the ordinal in parentheses, so
  every exit checklist ended *"Resolve before starting restore-access.md (Phase
  10B)."* Both arms now name the runbook alone; the `restore-git` arm added in
  Revision 65 was already correct, which is what made the older two visible.
- `probe_later` in `compare-restored-state.sh` deferred Docker to `Phase 12
  (restore-docker)` — the runbook name was already in the string, behind the
  ordinal.
- The two sign-off labels in `record-restore-prereqs.sh` read `Phase 8 enrollment
  record` and `Phase 9 first-boot bundle`. They are `enroll-and-stabilize` and
  `verify-reimaged-system`.
- One remediation hint still said *"at the end of Phase 10B"* where the row above
  it already said `` `restore-access` ``.

**The supported-runbook list in `record-restore-state.sh` is single-source.** Its
error text named `restore-access` only, three revisions after `restore-git` was
added — a hardcoded list beside a `case` whose arms are the real answer will
drift, and had. The `case` now tests membership in `$SUPPORTED_RUNBOOKS` and
derives `PHASE_RUNBOOK` as `$RUNBOOK.md`, because the runbook name *is* the
artifact name and a second table only exists to disagree with the first.

Verified on Linux, which is enough for what changed: `bash -n` and
`verify-script-portability.sh` clean on all four scripts, `verify-doc-paths.sh
--all` at 0 MISSING and 0 broken anchors over 1074 anchors, and all four
recorders dry-run for `restore-runtime`, `restore-access` and `restore-git` with
no unbound-variable errors and no ordinal in any emitted line. Nothing here
touches the macOS-only paths, so no Mac run is outstanding for this revision.

---

## Revision 65 — closing out Phase 11A, and ordinals out of the artifacts

`restore-git.md` gains **Step 9 — Compare Restored State Against Captured
Inventories** (capture the after-state, compare against the captures, join the
two recordings) and **Step 10 — Close Out the Exit Criteria**. Two more script
tables learned the runbook, each with content rather than a row:

- `collect_restore_git()` in `compare-restored-state.sh` — six probes against
  `08-git.txt`, the pre-image record of the erased machine's Git configuration.
- `check_restore_git()` in `record-restore-exit.sh` — global config written,
  dual-identity routing present, TLS verification left on, credential helper,
  SSH host aliases, and one `TODO` for the identity validation only a person can
  close.

**The `http.sslverify` row becomes real here**, and the runbook says so. Under
`restore-access` it reported `correctly dropped` for a weak reason: `~/.gitconfig`
did not exist, so nothing had been reviewed and left out. This is the phase that
writes that file, so a `**CARRIED FORWARD**` verdict now means the pre-image
`sslverify = false` genuinely came back and every Git HTTPS remote is
unverified. The exit checklist carries the matching `FAIL` row.

**One probe deliberately weakened.** `Git user.email` started as a value
comparison and reported the *personal* address as the work identity, because
`08-git.txt` holds two `user.email` lines — this is a dual-identity setup — and
the anchor matched the first. A value comparison there would report a confident
mismatch on a correctly configured machine, so it is a presence row now, with the
reason recorded beside it. Which identity applies where is Step 7's job.

**Phase ordinals are out of the generated artifacts.** Twelve emitted strings
across four scripts named a phase where they meant a runbook — "Phase 10B has not
run", "Phase 10A installs it", "Phase 4B writes it before the erase" — and an
ordinal in a dated artifact is wrong from the next renumber onward with nothing
to catch it. They now name `restore-access`, `restore-runtime`,
`capture-system-inventory`. Six conditionals that selected vocabulary by
`$PHASE == "10B"` now test `$RUNBOOK != "restore-runtime"`, which is what they
actually meant — the distinction is versions versus trust and identity — and
generalises to `restore-git` without another arm.

The one place a phase number survives is the line sourced from the invocation:
*"(Phase 11A at the time of this run)"*. It records what was true when the run
happened rather than asserting something that can go stale, which is what makes
it safe to keep.

**The sweep introduced a bug of its own, caught by running it.** Replacing
`Phase 10B` with `` `restore-access` `` put *unescaped* backticks into
double-quoted shell strings, where bash reads them as command substitution — so
`record PASS "`restore-access` closed out"` tried to execute `restore-access`
and reported `command not found` before the row could be written. The existing
convention escapes them (`\``) precisely because these strings carry Markdown
into an artifact; the mechanical replacement did not know that. Twelve lines
across three scripts corrected, and all six runbook/script combinations re-run
to confirm zero command-substitution errors.

A textual sweep across shell strings has to respect the quoting of the thing it
is editing. This is the second time this session that a blanket replacement was
right about the intent and wrong about the syntax — the first renamed a `case`
subject without its arms.

---

## Revision 64 — Step 0 for Phase 11A

`runbook-prompt.md` says a Step 0 is earned by a prerequisite that fails
**silently**, and warns against adding one for symmetry. Phase 11A earns it
outright, and the row that earns it is the SSH identity keys.

`ssh` does not error on a key it cannot use. An unset `$GIT_WORK_SSH_KEY`, a key
Phase 10B did not restore, or a key at the wrong mode all produce the same
behaviour: `ssh` skips it and authenticates as whichever identity in `~/.ssh`
answers next. The phase completes, `ssh -T` in Step 7 reports success, and the
first real symptom is a commit pushed under the personal account to a work
repository — noticed by someone else, later. That is the shape the prompt
describes.

**Three scripts learned the runbook**, and each needed real content rather than a
table row:

- `check_restore_git()` in `record-restore-prereqs.sh` — six rows derived one
  for one from *Prerequisites*, so the two cannot drift: toolkit root, Phase 10B
  actually **closed out** (read from the boundary index, because an entry with no
  exit is a phase walked and abandoned), the two identity keys with mode, the
  four identity values, Git itself, and a WARN for the GitHub fingerprints.
- `targets_restore_git()` in `record-restore-state.sh` — four paths, every one
  this phase writes. `~/.ssh/config` is in the set because Step 3 rewrites it
  wholesale rather than appending, so the before-state is the only record of what
  it held.
- Both resolve tables gained `restore-git`.

`record-restore-exit.sh` deliberately did **not**. Its table entry without a
`check_restore_git` would resolve to nothing through the dynamic dispatch and
record an empty checklist that reads as a clean close-out. Exit criteria are the
close-out step, which was not part of this request.

**The GitHub-fingerprints row is a WARN, not a PASS.** The entry recorder has no
MANUAL tier — that vocabulary belongs to the exit checklist — and recording PASS
for something nobody verified is precisely the failure this step exists to
prevent.

Two defects caught by running it. The check function was inserted above
`RUN_CONTEXT=` but the dynamic dispatch `"check_${RUNBOOK//-/_}"` sits eighty
lines earlier, so it resolved to `command not found` and produced a checklist
with a header and no rows — the third instance this session of a definition
placed after its use, and the same shape as the `emit_delta` and `VERDICTS_SEEN`
ordering errors already recorded here. And the key check recorded one row per
key, so two unset variables produced two identical rows and counted twice in the
summary; collapsed to one row that names which key is at fault.

---

## Revision 63 — a delta is a point, not a side effect

Revision 60 moved the delta into `record-restore-state.sh` and emitted it as
`delta.md` inside the after-run. That satisfied "created in addition to
`--point after`" and missed the better half of the same instruction: make it an
option. It is now `--point delta`.

Three things that fixes:

- **A run directory holds one kind of thing.** An after-run held `state.tsv`,
  `state.md` and — only sometimes — `delta.md`, which made "what is in a state
  run" un-answerable without opening it. A delta run holds `delta.md`.
- **It is re-runnable.** The delta is derived from two official pointers, and
  both move: `after` is latest-wins, and `before` can be re-pinned with a caveat
  — this artifact root's before-run is pinned exactly that way. A side effect of
  a capture cannot be rebuilt without re-capturing; a point can.
- **It reads the officials rather than the run in hand.** `emit_delta` now
  resolves both `-before` and `-after` through `artifact_run_official`, so the
  delta describes the runs the index considers current, not whichever directory
  happened to be open.

`delta` was already in `ARTIFACT_RUNS_KNOWN_POINTS` from Revision 57, so the run
grammar needed nothing. `--point after` now prints the command instead of the
file, and says so only on a real capture — a dry run records nothing to join.

Two ordering defects, both the same shape as ones already recorded here, both
caught by running it. `emit_delta` was defined 180 lines below the branch that
calls it, and a bash function does not exist until its definition executes.
`OUTPUT_ROOT` was resolved further down still, in the capture path the delta
branch skips — so `artifact_run_official` was handed an empty category root and
reported no official runs for a phase that has three. Both lifted above the
branch, with the reason recorded at the lift.

**A guard hardened by bad data.** The join key is an absolute path, and rows from
a corrupted `state.tsv` — the Linux-written test runs from Revision 61, before
`stat_field` was fixed — have no path at all. They joined against nothing and
rendered as phantom removals. The guard now requires a leading `/` rather than
merely a non-empty field. The corrupt run was moved to `state/_to_delete/`, its
manifest row dropped and the pointers rebuilt; the two captures taken on the Mac
are untouched and remain official.

Verified against those real captures: 29 unchanged, 14 added, 6 content changed,
with `System.keychain` correctly reading `content changed` across Step 5.

---

## Revision 62 — two regressions, both mine, both caught by running it

**The walker lost `observe()`.** Revision 61 hardened `stat_field`, a one-line
function. The replacement ran from `stat_field() {` to the next `\n}` — which
was not `stat_field`'s brace but the closing brace of `observe()`, forty lines
below. The function that does every observation was deleted.

The failure was legible and the output was not: `observe: command not found` on
stderr, and a capture reading `19 targets, 7 rows: 0 present, 7 absent` on a
machine where most of those paths exist. Only the paths that never reached
`observe` produced rows at all. An operator running the new pre-image capture
saw it first.

Restored verbatim. Both callers verified: 21 rows and 8 present on a sparse
fixture, and `record-restore-state.sh`, which shares the walker, reports zero
`command not found`.

The lesson is narrow and worth keeping: a text replacement bounded by "the next
closing brace" is unsafe against a one-line function, because its brace is on
the same line and the search runs past it into the next definition.

**The comparison produced an empty table.** Revision 59 rewrote
`case "$PHASE" in` to `case "$RUNBOOK" in` everywhere it appeared — including
`collect()`, whose arms were `10A)` and `10B)`. Neither can match a runbook name,
so `collect` returned nothing, `RESULTS` was empty, and the Detail table rendered
as a header with no rows beneath it. Every `compare-restored-state.sh` run since
that revision reported nothing while exiting 0.

A blanket rename of the *subject* of a `case` without checking its *arms* is the
whole defect. The arms were phase ordinals in a script whose flag had stopped
being one.

**The per-phase internals are now runbook-named**, which is what the operator
asked for and what fixes the above properly rather than patching the arms:

| Was | Now |
|---|---|
| `check_10A` / `check_10B` | `check_restore_runtime` / `check_restore_access` |
| `collect_10A` / `collect_10B` | `collect_restore_runtime` / `collect_restore_access` |
| `targets_10B` | `targets_restore_access` |
| `"check_$PHASE"` | `"check_${RUNBOOK//-/_}"` |

Dynamic dispatch by name is why this had to move together: the function name is
built from a variable, so renaming the variable without renaming the functions
silently resolves to nothing. Verified end to end — all four scripts produce rows
for `restore-access`, and `restore-runtime` still resolves on both scripts that
support it.

**Already in place, contrary to a report:** the phase delta is wired into
`record-restore-state.sh` (`emit_delta`, fired on `--point after`) and read by
`restore-access.md` Step 11. Both survived the walker extraction; no change
needed.

---

## Revision 61 — the plane that had one side

Asked whether a pre-image-to-post-image *delta* existed, the answer was no, and
it could not: nothing walked those paths before the erase. The pre-image
captures are command output as text; the state plane — path, mode, SHA-256 —
had a post-image side only. So the cross-erase question was answered by version
strings, and `java` reporting 21.0.11 on both sides is satisfied equally by a
correct restore and by a fresh install.

**Locations, as the operator settled them.** Captures go to `system-state/`, its
own top-level category exactly like `system-inventory/`, because it holds both
sides of the erase — not under `reimaged-system/`, which is post-image by
construction and whose lineages dropped that prefix in Revision 58 for precisely
that reason. The comparison goes to
`reimaged-system/comparisons/runs/system-state-delta-<stamp>/`, beside the
inventory diff, because it is a comparison and that is where comparisons are
indexed.

**Built:** `.internal/restore-state-targets.conf.sh` (the 19 targets, one
definition), `.internal/state-walk.sh` (the observation), and
`bin/capture-system-state.sh --phase pre-image|post-image`, which on a
post-image run also builds the delta. `capture-` rather than `record-` follows
`script-types-and-locations.md` literally: a paired pre/post inventory of system
state, re-run after the reimage so the two can be compared.
`record-restore-state.sh` keeps its name — it walks the same paths *within one
phase*, and its output belongs to the phase, not the machine.

The extraction is the load-bearing part. A delta joins two walks row for row, so
any difference in how a path is observed becomes a change the machine never
made. Two copies of that table would drift and the first symptom would be a
comparison lying confidently rather than failing.

`record-restore-state.sh` is in active use mid-restore, so the refactor had to be
provably inert: its output was captured before and diffed after, and is
byte-identical modulo the generation timestamp and a live free-inode count.

**Three defects, all found by running it.**

The first draft used `set -Eeuo pipefail` with an ERR trap and aborted on the
first absent path. Every observation in a state walk is *allowed* to fail — an
absent path, an unreadable keychain, an unsupported `stat` format each have to
produce a row saying so, because that is the entire output. Same footing as the
validators: `set -uo pipefail`, with the omission explained.

`stat_field` returned `stat` output unsquashed. BSD `stat -f` yields one field;
GNU `stat -f` means `--file-system` and prints a multi-line block, which embedded
newlines and tabs in TSV columns and silently corrupted every row after them.
The delta then reported *inverted* verdicts — a file created after the reimage
read as "lost in the reimage" — with complete confidence. macOS is the only
supported platform, so this was unreachable in practice, but a row that reads
wrong is worse than one that reads empty, because the file still parses. Now
squashed on the way out.

Adding a step to `capture-system-inventory.md` renumbered its *Verify Outputs*
from 3 to 4, and the fix for the resulting broken anchor was applied across
every runbook rather than the one that renumbered — breaking three that
legitimately have their own Step 3. Reverted, and fixed only where the heading
actually moved. `verify-doc-paths.sh` caught both the original break and the
overcorrection, which is the first time the anchor check added in Revision 50
has paid for itself on someone else's edit.

**Not verified here:** the walk itself needs BSD `stat`, which this session does
not have. Run `./bin/capture-system-state.sh --phase pre-image --dry-run` on the
Mac once. The verdict logic was verified against fixtures for all six outcomes.

**Not recoverable for this reimage.** No pre-image walk was taken and the machine
is gone. `--phase post-image` will capture and report that it has nothing to
compare against.

---

## Revision 60 — two tools wearing one name

An operator asked how the phase delta differed from the two state captures it
was built from. It did not. Measured:

- `--against inventory` runs live probes and greps pre-image capture files.
  Twenty-nine references to the probe machinery.
- `--against before` joined two `state.tsv` files. **Zero** references to any of
  it — no probes, no capture files, no `INVENTORY_DIR`.

They shared a CLI, a report renderer, and nothing else. One answered "is this the
machine that was erased" by probing what is running now; the other answered "what
did this phase change" by joining two recordings that `record-restore-state.sh`
had already written. The second needed no input the after-capture did not already
hold, so making the operator invoke a second tool to derive it was ceremony.

**The delta now lives where its inputs do.** `record-restore-state.sh --point
after` joins this run's `state.tsv` against the official before-run's and writes
`delta.md` into the after-run directory, beside `state.tsv` and `state.md`. It
cannot go stale, because a delta exists only inside the capture it was computed
from. With no before-run recorded it says so and writes nothing rather than
emitting a comparison with an empty side.

**`compare-restored-state.sh` has one baseline again.** `--against` is gone
along with `collect_state_diff`, the `state` verdict arm, the before-baseline
summary branch, and `PHASE_DEFAULT_AGAINST`. The `phase-delta` lineage created in
Revision 57 is retired — its two runs, its pointer and its manifest rows moved to
`comparisons/_to_delete/`. That lineage lasted three revisions, which is the cost
of splitting a name before asking whether the thing needed to be there at all.

Verified: the join produces `added`, `unchanged`, `content changed` and
`**removed**` correctly against fixtures sharing a path namespace; the
after-capture emits `delta.md`; `--against` is rejected as an unknown option.

Two defects found by running it. The delta is written while the run directory is
still staged as `.<id>.incomplete`, so the header cited a path that ceases to
exist a moment later — it now prints the final run id. And a blank line in either
`state.tsv` produced a row with an empty path; skipped explicitly.

---

## Revision 59 — the flag was still the ordinal

Revision 53 titled the documents by runbook because ordinals renumber. It left
the invocation alone, so the operator still typed the number the documents no
longer used:

    ./bin/record-restore-prereqs.sh --phase 10B      ->  # restore-access — Prerequisite Check

Half a convention. `--phase` is now `--runbook`, taking the runbook stem and
accepting the `.md` suffix:

    ./bin/record-restore-prereqs.sh   --runbook restore-access
    ./bin/record-restore-state.sh     --runbook restore-access --point before
    ./bin/compare-restored-state.sh   --runbook restore-access --against inventory
    ./bin/record-restore-exit.sh      --runbook restore-access

The lookup tables inverted cleanly because each phase already mapped to exactly
one runbook; `resolve_phase` became `resolve_runbook`, and `PHASE` is now derived
rather than supplied — it survives only as the *"(Phase 10B at the time of this
run)"* context line, which records what was true when the run happened.

No alias. `--phase` is rejected with `unknown option`, per the repository's rule
against retaining a compatibility path nobody asked for. Twenty-seven call sites
updated across `restore-runtime.md`, `restore-access.md`,
`bin/restore-access.sh` and `reimaging-scripts-guide.md`.

**Not touched, deliberately:** `capture-office-stability.sh`,
`capture-performance-audit.sh` and `reimage-checklist.sh` also take `--phase`,
and there it means something else entirely — `pre-image` versus `post-image`,
which side of the erase a capture belongs to. Same flag name, unrelated concept.
Renaming those would have been the mechanical change that looks consistent and
is wrong.

**Every recording block now shows a `--dry-run` line above the real one.** The
phase delta was the one an operator noticed — step 2 previewed the inventory
comparison and step 3 went straight to a recorded write — but four more had the
same gap: both Step 0 recordings, the after-state, and the exit checklist.

The preview matters unevenly, and the runbook now says where it matters most.
**0b is first-wins**: the first before-state recorded is the one that stays
official, so a capture taken after Step 1 mounts the image cannot be replaced,
only annotated with a pin explaining why it is wrong. That is not hypothetical —
this artifact root's pinned before-run carries exactly that caveat, because it
was taken after Steps 1–3 had already run. Reading the target list before
recording is the whole defence, and it cost nothing.

All five previews were verified to run and to write nothing: run-directory counts
under `reimaged-system/` were identical before and after each.

Two defects the first pass introduced, both caught by running it rather than
reading it: the required-argument guards still tested `$PHASE` after the variable
was renamed, which under `set -u` aborted with `PHASE: unbound variable` before
any check ran; and `compare-restored-state.sh` still called `resolve_phase "$PHASE"`
by its old name. Both fixed, and all four verified against the real artifact root
— plus a missing-argument case and an unknown-runbook case, which now report
`supported runbooks: restore-runtime, restore-access` rather than a list of
ordinals.

---

## Revision 58 — a directory that already says it

Everything under `reimaged-system/` is post-image by construction, so
`post-image-restore-access-entry` said it twice.
`boundaries/runs/post-image-restore-access-exit-20260824-131741` cannot be
anything else, and the prefix pushed the part that identifies the run eleven
characters to the right in every listing.

Dropped across all four categories — `boundaries/`, `comparisons/`, `state/`,
`restarts/`. Contexts are now `restore-access-entry`,
`restore-access-inventory-diff`, `verify-reimaged-system-pre-restart`.

**It does not generalise, and the scoping mattered more than the rename.**
`repo-audit-reports/` and `performance-audit/` hold pre-image *and* post-image
runs side by side, where the prefix is the only thing separating them.
`restore-repos.md` alone names `post-image-restore-*` a dozen times and is
correct to. The test recorded in `artifact-runs.sh`: drop the prefix only when
the containing directory already answers it.

**Migration:** 19 run directories renamed, four `MANIFEST.md` files rewritten,
11 pointers regenerated. Seven context-construction sites across six scripts,
plus the lookups `reimage-checklist.sh`, `record-restore-prereqs.sh` and
`record-restore-exit.sh` use to find runs by name.

**The pins nearly survived the migration in the wrong shape.** Renaming the
directories and rewriting the manifests was not enough: each pinned run carries a
`PINNED-OFFICIAL.txt` marker naming its own context, and `artifact_runs_rebuild`
reads those markers to recover pins. Both still said `post-image-…`, so the
rebuild dutifully appended two *new* pin rows under the old contexts and wrote
two pointers to match — resurrecting the prefix from inside the runs it had just
been removed from.

The first verification pass reported this clean, because it checked `run` rows
and skipped `pin` rows. A check that inspects only the rows it expects to be
wrong is not a check. Widened to both, plus a marker sweep, and re-run: 23 rows
across four categories, zero problems, no marker naming an old context.

Both pins still resolve to the runs they were pinned to — `restore-access-before`
to the 08:44:27 capture with its caveat, and `verify-reimaged-system-pre-restart`
to `012631`, the last pre-restart run rather than the first-wins default. Losing
either would have silently changed which evidence the workflow treats as
official.

Superseded pointer files are under each category's `_to_delete/`; this session
cannot remove them.

**The rename exposed an older omission.** *Artifact and Script Locations* listed
`boundaries/` and `state/` and never listed `comparisons/` at all — so neither
the inventory diff nor the phase delta appeared anywhere in the runbook's own
inventory of what the phase produces, and the delta had been invisible there
since Revision 51 created it. Both categories are listed now, with the pointer
files and the step that writes each.

The script list was equally behind: it named four entrypoints and omitted
`compare-restored-state.sh`, which Step 11 runs twice, and
`bin/restore-access.sh`, which drives the phase. Both added, and every comment
repointed at the renumbered steps — the close-out references still said
"Step 11" from before Revision 52 split it into 11 and 12.

Comment columns in both blocks were re-aligned; the prefix removal had left them
ragged, which is cosmetic until it makes a reader skip the column that says which
step writes what.

---

## Revision 57 — a diff and a delta are not the same question

Both `--against` baselines wrote into one lineage, `post-image-<runbook>-diff`.
Officialness for `diff` is latest-wins, so the pointer named whichever ran last
regardless of which question it answered — and `--reprobe` and the exit
checklist read that pointer without knowing which they got.

The distinction is not cosmetic, and the operator named it before the code did:

- **diff** — the machine against a capture taken before the erase. Divergence
  from a recorded baseline, with a live side that can go stale.
- **delta** — one phase's own before- and after-state recordings joined. What
  that phase changed. Both sides are recordings; nothing about it can go stale.

`--against inventory` is unchanged, which was the operator's instruction: it does
compare against inventories, and the earlier proposal to rename it was solving a
problem that was not there. What needed separating was the *output*.

| Baseline | Lineage |
|---|---|
| `--against inventory` | `post-image-<runbook>-inventory-diff-<stamp>` |
| `--against before` | `post-image-<runbook>-phase-delta-<stamp>` |

`delta` joins `ARTIFACT_RUNS_KNOWN_POINTS`, with the diff-versus-delta reasoning
recorded beside it. Point extraction needed nothing new — it reads the last
dash-segment, and `inventory-diff` ends in `diff` while `phase-delta` ends in
`delta`.

`--reprobe` is repointed at the inventory lineage explicitly. It re-runs live
probes against a recorded comparison, and a phase delta has no live side to
re-probe; leaving it on the shared context meant it could have re-probed a
recording-to-recording join and reported freshness of something that cannot
become stale.

**Migration, on the operator's real drive.** All three existing runs predate
`--against before` being usable and are inventory-baseline, so they migrate
without ambiguity: directories renamed, MANIFEST contexts and run ids rewritten,
pointers regenerated by `artifact_runs_rebuild`. Verified by a parse-back
assertion — every run named in the manifest exists on disk, and every run id
starts with its own context — which is the check that caught the `${run%-*}`
error during the Phase 9 migration. The two superseded pointer files were moved
to `comparisons/_to_delete/` rather than removed, since this session cannot
delete.

`record-restore-prereqs.sh` and `record-restore-exit.sh` both look up
`post-image-restore-runtime-diff` by name for their `Runtime comparison
recorded` rows; both repointed.

---

## Revision 56 — a legend is not a findings list

An operator removed `http.sslverify`, re-ran the comparison, and reported still
seeing *"Remove it: `git config --global --unset http.sslverify`."* Their row
said `correctly dropped`. The sentence they were reading was the
`**CARRIED FORWARD**` entry in *How to read this* — an explanation of a verdict
they did not get.

That is the third consecutive misread of this script's output, all the same
shape: it presented the possibility space as though it described the machine.
Three reports in a row is not a reader problem.

The legend is now gated. `verdicts_seen` collects the distinct verdicts this run
actually produced, and every legend entry is wrapped in `if saw '<verdict>'`.
A run whose rows are `**MISSING**`, `expected later`, `correctly dropped` and
`differs` prints four explanations and nothing else — no `**CARRIED FORWARD**`,
no `identical`, no `no baseline`.

Gating exposed a gap it was worth having: `differs`, `same` and `present` all
occur in 10B tables and had explanations only in the 10A branch, so a 10B reader
met three verdicts the document never defined. Added, phrased for value rows
rather than versions — `differs` on a login shell is a decision someone made,
not the expected churn of a rebuild.

One ordering defect caught before it shipped: `VERDICTS_SEEN` was first computed
beside `RESULTS`, 150 lines above the definition of `verdicts_seen`. A function
definition takes effect when the definition executes, so that call would have
failed at runtime on every invocation. Moved below the helpers.

The `**Corporate root trusted**` entry stays ungated: it explains a row that is
always present in the 10B set rather than a verdict that may or may not occur.

---

## Revision 55 — checking a claim instead of repeating it

Asked whether the `sslverify` legend was correct, three of its claims were not.

**"undoes Step 7" overstated the blast radius.** Step 7 configures five
consumers: `npm config set cafile`, `pip3 config set global.cert`,
`git config --global http.sslCAInfo`, and the four environment variables.
`http.sslverify = false` defeats **only the Git half**. `npm`, `pip`, `curl` and
Node read their own settings and keep verifying. That asymmetry is not a
footnote — it is precisely why the setting survives unnoticed, because nothing
else looks broken. The legend now says which half.

**It named the wrong phase as the next risk.** "re-check after Phase 11A"
skipped the nearer one: Step 8 of this same runbook lists `.gitconfig` among its
selective restores, so the value can come back one step later, not one phase
later. The legend now names both points.

**Step 8 contradicted Step 3 about where `~/.gitconfig` comes from.** Its list
carried `.gitconfig  # already restored in Step 3`, while Step 3 says plainly
that `~/.gitconfig` is *not* in the image — not a credential, no `git/` category
— and that Phase 11A owns it. The stale note pointed the reader at a restore
that does not happen. Replaced, and Step 8 gained a Pitfall naming the
`[http] sslverify` block, what to take from the file instead, and the
`git config --global --get http.sslverify` confirmation.

**One correction in the other direction.** Both the legend and the Step 8
Pitfall now say to check whether a per-host exemption is still needed before
reaching for one: Step 7 puts the corporate root in the CA bundle, so an
internal host that failed to verify pre-image may verify now. Recommending
`GIT_INTERNAL_TLS_SKIP_HOST` without that check teaches the operator to disable
verification for a problem the phase just fixed.

What did hold up: the value is in `08-git.txt` and in the dotfiles backup at
line 3, it is global rather than per-host, `--unset` is the right removal, and
`GIT_INTERNAL_TLS_SKIP_HOST` does scope the exemption to a single host — in two
forms, global and `~/.config/git/config.local`.

---

## Revision 54 — two rows that told the operator the wrong thing

An operator removed `http.sslverify`, re-ran the comparison, and reported that
the row read the same. It did, and correctly: `credential.helper` and
`init.defaultBranch` both read `**MISSING**` in the same table, which means there
is no global `~/.gitconfig` on the rebuilt machine at all. The value was never
there to remove. The `Captured pre-image` column cannot change either — it is a
fact about a machine that no longer exists.

So the verdict was right and the presentation was not. Two fixes.

**An inverted row printed `MISSING` next to a pass.** `MISSING` is the sentinel
`live_first_line` emits for a command that produced nothing, and on
`probe_absent` that is the PASS. Printing it beside `correctly dropped` reads as
a contradiction, which is enough to make a reader distrust the column.

The first attempt rewrote `live` inside the probe — and broke it: the verdict
reads the same variable, so the row flipped to `**CARRIED FORWARD**` on a machine
where the value was absent. A false alarm, in the worst direction, on the one row
whose whole purpose is catching a security regression. The substitution now
happens in `render_rows`, which knows the kind and is presentation only; the data
keeps the sentinel the verdict depends on.

**A row a later runbook owns counted as this phase's gap.** `credential.helper`
and `init.defaultBranch` are set by `restore-git.md` (Phase 11A), which has not
run. Counting them as `**MISSING**` produced *"2 check(s) recorded pre-image are
missing now — resolve these before closing out Phase 10B"*, which cannot be
followed: the phase that sets them comes later.

`probe_value` now takes an optional fifth argument naming the owning runbook.
When the value is absent and an owner is named, the row reads `not set yet`,
`recorded osxkeychain — restore-git.md owns it`, verdict `expected later`, and
counts as not-comparable rather than as a gap. The existing `probe_later` kind
could not serve: it takes no capture and would have dropped the recorded value,
which is the useful half of the row.

The legend gained both, including the caveat that `correctly dropped` currently
passes because `~/.gitconfig` is absent entirely rather than because the value
was reviewed and left out — so it needs re-checking after Phase 11A, which is
when it could come back.

Caught in the same pass: the owner message wrapped the recorded value in
backticks, and `render_rows` already wraps every cell in backticks. Nested
backticks break the cell.

---

## Revision 53 — a phase ordinal is not a name

`# Phase 10B Prerequisite Check` was the title on every prereq run. The run
*directory* had it right — `post-image-restore-access-entry-<stamp>`, keyed on
the runbook stem — but the document inside named the ordinal.

Ordinals renumber. This workflow has done it once already. A dated artifact is
never regenerated, so every checklist naming the old number is wrong from that
moment with nothing to catch it: no validator can know that "Phase 10B" used to
mean this runbook. The runbook stem does not have that failure mode, is what the
file is actually called, and is what an operator remembers three weeks later.

Applied to all four producers, not only the prereq check, because leaving them
inconsistent is worse than either convention:

| Document | Was | Now |
|---|---|---|
| Prerequisite check | `# Phase 10B Prerequisite Check` | `# restore-access — Prerequisite Check` |
| Exit criteria | `# Phase 10B Exit Criteria` | `# restore-access — Exit Criteria` |
| Restored-state comparison | `# Phase 10B Restored-State Comparison` | `# restore-access — Restored-State Comparison` |
| State capture | `# Phase 10B before-State` | `# restore-access — before-State` |

Console lines follow: `Checking restore-access prerequisites (Phase 10B)...`.

The phase is not deleted — it moves to the `Pairs with` line as *"(Phase 10B at
the time of this run)"*. Sourced from the invocation, it records what was true
when the run happened rather than asserting something that can go stale, which
is the distinction that makes it safe to keep.

The rule is recorded in `.internal/artifact-runs.sh`, beside the lineage-naming
contract it extends: a context's `what` is the runbook stem, never the ordinal,
and the same holds inside the documents a run contains.

Also fixed here: `bin/record-restore-prereqs.sh` was mode 600 after Revision
49's move, so the phase Step 0 command would have failed with
`permission denied` exactly as `compare-restored-state.sh` did on the operator's
Mac. `chmod +x bin/*.sh` on the Mac is the authoritative fix — the mount this
session writes through normalises modes.

---

## Revision 52 — the comparison earns its own step

Revision 51 put the comparison inside the closing step, which buried a distinct
piece of work inside a checklist run. `restore-runtime.md` already had the right
shape — its Step 10, *Compare Versions Against Captured Inventories*, is its own
step — and Phase 10B now matches it.

`restore-access.md` Step 11 is **Compare Restored State Against Captured
Inventories**: capture the after-state, compare against the captured
inventories, then diff the phase itself. "Restored State" rather than "Versions"
because what this phase rebuilds is trust and identity; the title also matches
the script name, which `restore-runtime`'s does not.

Step 12 is what remains of the close-out: the exit checklist and confirming both
boundary records landed. `bin/restore-access.sh` runs all three in its `finish`
subcommand, and its dry run now shows five actions rather than three.

The step carries a verdict table, because none of 10B's rows are the version
comparison a reader arrives expecting — `identical`, `no baseline`,
`correctly dropped`, `**CARRIED FORWARD**`, `**MISSING**`, each with what it
means on this phase specifically.

**A caveat the first real run exposed.** An operator's comparison reported
`Git credential.helper` and `Git init.defaultBranch` as `**MISSING**` and
`Git http.sslverify` as `correctly dropped`. All three are the same fact:
`restore-git.md` (Phase 11A) owns the global Git configuration and has not run,
so there is no `~/.gitconfig` to hold any of them. The `correctly dropped`
verdict is therefore true but not yet meaningful — it passes because the file is
absent, not because the value was reviewed and left out. Phase 11A is when
`http.sslverify` could come back. The step says so in a note, because a pass
that will need re-checking and a pass that is settled look identical in the
table.

**Exec bits lost in Revision 49's move.** `bin/record-restore-prereqs.sh` came
out of `.internal/restore/` at mode 600 and
`bin/compare-restored-state.sh` failed with `zsh: permission denied` on the
operator's Mac. Restored here, but the mount this session writes through
normalises modes, so the authoritative fix is `chmod +x` on the Mac. Worth
remembering for any future move: the graduation is not complete until the file
is executable, and the runbooks tell readers to run these directly.

---

## Revision 51 — the comparison was not limited by design, only by table

`compare-restored-state.sh` read one capture — `system-inventory/pre-image-*/` —
and had a guard that refused any phase but 10A. The axis for more was already
there: `resolve_phase` sets `PHASE_DEFAULT_AGAINST`, `inventory` for 10A and
`before` for 10B. What was missing was a probe set for 10B and a way for a probe
to name a capture other than the system inventory.

**Capture sources.** A probe now names its source as `root:glob` — `inventory:`,
`managed:`, `secrets:` — with a bare filename still meaning the system
inventory, so every 10A probe is untouched. Resolution is by glob and takes the
newest match, so a spec survives the timestamp in a capture directory name.

**Three new probe kinds**, because what Phase 10B rebuilds is trust and identity,
and almost none of it is a version string:

- `probe_hash` — SHA-256 of a live file against a hash recorded in a capture.
  The `jssecacerts` manifest beside the encrypted image records one per JDK, so
  Step 6 can be verified byte-for-byte rather than assumed from a successful
  `cp`. It walks the JDKs installed *now*: one added since the capture has no
  recorded hash, and reporting `no baseline` is the finding — that JVM has no
  corporate trust unless someone put it there.
- `probe_value` — exact-string comparison. `probe_version` compares version
  numbers because each side writes them differently; a config value is the
  opposite, and `osxkeychain` either is what was recorded or is not.
- `probe_absent` — **inverted on purpose**. Some pre-image state must not come
  back. `http.sslverify = false` is recorded in `08-git.txt`, is in the dotfiles
  backup Step 8 restores from, and carrying it forward disables TLS verification
  for every Git HTTPS remote — undoing Step 7 and matching the anti-pattern its
  own Pitfall names. A same/differs verdict would mark the *correct* outcome as
  a difference, which is how a comparison teaches its reader to ignore it. The
  verdicts are `correctly dropped` and `**CARRIED FORWARD**`.

**The 10B probe set** covers `jssecacerts` per JDK, Git `credential.helper` and
`init.defaultBranch`, the `http.sslverify` inversion, the login shell, and
whether the corporate root is *trusted* — read from the trust store, not the
keychain file list, because `16-certs.txt` records only which keychains exist.

**`--against before` implemented.** It exited 2 with a stale reason: *"the
recorder that writes one does not exist yet"*. `record-restore-state.sh` exists,
and Revision 49 added the `after` capture at Step 11, so both halves are on
disk. It now joins the two `state.tsv` recordings on their path column and
reports `added`, `content changed`, `mode changed`, `removed`, `unchanged`. Both
sides are recordings rather than probes, which is the point — it answers what
the phase changed, and by the time anyone asks, the before-state is gone.

Three defects found by running it against a real artifact root rather than by
reading it:

- `artifact_run_official` returns a path **relative** to the category root
  (`runs/<name>`). Treating it as absolute failed every `-f` test and reported
  "no before-state run" for a run that was on disk. The two failures — no run
  recorded, versus a run with no `state.tsv` — are now reported apart.
- `record-restore-state.sh` writes an `absent` *row* for a path it walked and
  did not find, which is not the same as no row at all. Conflating them reported
  `~/.certs/` going absent → present as "mode changed" — the corporate CA
  bundle being created, described as a permissions tweak.
- `count_verdicts` bucketed by 10A's vocabulary with a catch-all default, so 29
  `unchanged` rows counted as changes and the summary read "Added or changed 50,
  Unchanged 0" over a table showing 29 unchanged. Every verdict the script can
  emit is now bucketed explicitly.

Verified against the operator's real drive: 1 removed, 20 added or changed, 29
unchanged, and the summary agrees with the table. `--phase 10A --against
inventory` is byte-identical to before. The `jssecacerts` anchor was tightened
to match at row start, so it cannot pick up the manifest's
`existing-secrets-encrypted-*` rows for the same JDK name.

Step 11 now runs the diff between capturing the after-state and running the exit
checklist. Before this, nothing read the after-state at all.

---

## Revision 50 — legibility, not relocation; and a check that could not fail

**The question.** `bin/` holds 39 scripts against 26 runbooks, and the instinct
was to move anything "used by a runbook but not exclusively" back under
`.internal/`. Measured, that criterion moves **22 of 39** — including
`backup-home.sh`, which is called by three runbooks and is still
`backup-home.md`'s own name-paired entrypoint. A rule that relocates the guide's
flagship example of the pairing convention is not describing the exceptions; it
is wrong. And `.internal/` means sourced-only and not run directly, which is
false for every script in question — the same contradiction that made the
prerequisite-recorder carve-out fail.

The real signal underneath was legibility: 39 flat files with no way to tell a
phase command from a shared utility by looking, and a name-pairing convention
that reads like the norm while covering only eight of them.

**`Reading bin/` added to `script-types-and-locations.md`.** Three populations,
told apart by how many runbooks call the script — owned (15), shared (22),
cross-cutting utility (2) — with the verb prefix named as the at-a-glance
grouping that makes a flat directory scannable. It states plainly that shared is
the majority and that being called by a second runbook is ordinary rather than a
signal to move.

It deliberately does **not** paste an inventory. A frozen list of 39 drifts the
first time a script is added, and a stale list is worse than none because it is
believed — the lesson Step 10's exit-criteria table taught in Revision 49. The
section carries a command that computes the current classification instead.

**And then the anchor checker demonstrated its own defect.** The new section
ended with a `[[#Table of Contents|⬆ Back to Table of Contents]]` back-link, in a
guide that has no Table of Contents. `verify-doc-paths.sh` passed it clean.

`Table of Contents` was in `ANCHOR_PLACEHOLDERS`, the list of names treated as
syntax examples rather than links. It is a **real heading in 40 documents** and
the target of the single most common link in the repository, so roughly 39
back-links — one per document, and the one every reader uses — were being
skipped rather than verified. Revision 45 recorded that "a test that cannot fail
when the thing it names is broken is not a test"; this is the second one built
since. The entry existed because `runbook-prompt.md` documents the syntax, and
the fence-aware extractor added in Revision 43 had already made it unnecessary.

Removed, and the count went from 1,027 verified anchors to 1,069. The
deliberately-broken-heading regression now fires on `restore-access.md`, which it
would not have before.

**One more shape the extractor did not know about.** With the placeholder gone,
two real breaks surfaced in `runbook-prompt.md` — both inline code spans
documenting the link format in prose, not links. The first fix blanked every
code span and broke 25 genuine anchors, because headings here routinely contain
inline code of their own: `` `ssh -T` fails after the keys are restored `` is a
real heading and its anchor carries the backticks. Narrowed to spans that *open*
with `[[`, which is the shape of a documented example and never the shape of a
heading. Verified against a fixture holding both.

`--all` is clean again: 51 documents, 0 missing paths, 1,069 anchors, 0 broken.

---

## Revision 49 — Item 0, option C; and a phase that never closed

**The carve-out is deleted.** `record-restore-prereqs.sh`,
`record-restore-exit.sh` and `compare-restored-state.sh` move from
`.internal/restore/` to `bin/`, beside `record-restore-state.sh`, which
graduated earlier. The graduation rule — a helper becomes an entrypoint when a
runbook tells the reader to run it directly — now applies unamended, because the
exception that held them back rested on two claims that failed measurement: no
`bin/restore-*.sh` referenced the prereq recorder at all, and two of eleven
post-image runbooks invoked it, not "every restore phase".

The guide records the general lesson rather than only the outcome: an exception
to a rule states facts, and facts can be checked — before writing one, and again
when it is cited.

**The move's known hazard, handled.** A comment in `compare-restored-state.sh`
documents that `record-restore-exit.sh` was broken once before by moving between
`bin/` and `.internal/restore/` with `REPO_ROOT="$SCRIPT_DIR/../.."` left intact.
All three were changed to `..` as part of the move and verified by running
`--help` and `--dry-run` from the new location and confirming none reports
`shared config loader not found`. The comments explaining the climb were
rewritten to describe the current depth rather than the old one.

Thirty-five references updated across eight files. `.internal/restore/` is now
empty — an empty directory a document promised is worse than none, per this
guide's own rule, and it needs removing by hand.

`script-types-and-locations.md` also records that the extraction trigger it set
has fired: four scripts now share `usage`, `require_option_value` and
`absolute_path` byte-for-byte, and `resolve_java_home` and `squash_ws` have
drifted. Until the extraction lands, a fix to any of those belongs in all four
copies. That is option D, agreed and pending.

**`restore-access.md` had no closing step.** Step 0 recorded two things — may
this phase start, and what the machine looked like first — and neither had a
counterpart. `record-restore-state.sh --point after` existed and was invoked
nowhere, so the before-state had nothing to compare against; and the runbook's
own script list said of the exit recorder, in as many words, *"the closing step
that runs it is NOT YET WRITTEN"*.

New **Step 11 — Close Out the Exit Criteria**: capture the after-state, run
`bin/record-restore-exit.sh --phase 10B`, then confirm `boundaries/MANIFEST.md`
holds both an entry row and an exit row for the phase. An entry with no exit is
the signature of a phase walked but never closed.

It runs *after* Step 10 because the exit checklist tests that the secrets DMG is
detached. **`bin/restore-access.sh` had exactly that ordering wrong** — its
`finish` step ran the checklist and then ejected, so the `Secrets DMG detached`
row would have failed on every run. A checklist that reports a failure it caused
itself teaches the reader to discount it. Reordered to eject, capture the
after-state, then check.

**Step 10's exit-criteria table is gone.** Nine hand-ticked rows duplicating what
the exit recorder already checks, and drifting from it: the table still said
"Internal root **and issuing CAs** are marked Always Trust", while the recorder's
row reads "Internal root trusted; intermediates left on system defaults". That is
the third place this same contradiction was found and the last one to be
corrected — Revision 47 fixed it in Troubleshooting, Revision 42 in Step 5. The
checklist is the table now; keeping a second copy is how the two came apart.

---

## Revision 48 — telling the operator one step too late

Step 9's `gh` block printed

    gh is not installed yet — Phase 12 installs it; defer this row.

*after* it was run. The fact was correct, the guard worked, and the operator
still had to execute a command to be told that executing it was pointless — and
a message that arrives as output reads as a failure they caused rather than an
expected state.

This is the third instance of one pattern. Revision 42 found the `raycast/` row
telling the operator to import into an application Phase 12 has not installed.
Revision 44 found Step 8 opening the dotfile comparison with `code`, which is
also Phase 12. Both were fixed where they sat; the shape they share was never
written down, so it kept recurring.

**The rule, now in `runbook-prompt.md`.** Name a later-phase dependency in the
prose introducing the block, not in the block's output — and say whether
deferring is the expected result or a problem, so the reader knows whether to
stop. Where an alternative exists on the base system, prefer it outright rather
than reaching for the later-phase tool: Step 8's comparison uses
`git diff --no-index` for exactly this reason.

**Applied.** Step 9 now opens with *"Expect to defer this one"*, says `gh`
arrives with Phase 12, says the block will report rather than fail, and says
nothing later in the phase depends on it — so a deferral is a note for the exit
checklist, not a blocker. Step 7's smoke tests gained the same treatment:
`SKIP node` and `SKIP npm` are the expected first-pass result because both
arrive with Phase 12, while `curl`, `git` and `python3` are on the base system
or came with Phase 10A. The trailing "re-run after Phase 12" line was rewritten
as a follow-up instruction rather than a restatement, since the expectation is
now set before the block.

Checked mechanically: all six `command -v` guards in `restore-access.md` are now
preceded by prose naming the dependency. Two more of this shape exist outside
this runbook — one in `restore-runtime.md`, one in `restore-apps.md` — and go on
the slice 4 list rather than being changed from here.

---

## Revision 47 — troubleshooting that had outgrown its step

`runbook-prompt.md` sets the test: a step-local problem with a short fix stays
inline as a `> [!bug] Troubleshooting` callout; it is promoted to the top-level
**Troubleshooting** section when it spans steps, is common enough that readers
scan for the heading, or *its fix is long enough to break the step's flow*. Two
blocks had failed that last test and stayed inline anyway.

**Step 3's 85-line Pitfall** — over a third of the step — is now
`### \`ssh -T\` fails after the keys are restored`. It stayed whole rather than
being split into three: its entire value is discriminating between an absent
key, a host with no `IdentityFile`, and a network that cannot carry the
protocol, and separating those puts the reader back where they started, holding
one message that matches three causes. Step 3 is 2,300 characters instead of
5,700.

**Step 7's 36-line Troubleshooting callout** is now
`### One smoke test fails while the others pass`. Retitled off `npm`: npm is the
usual symptom, not the subject, and a reader whose `git` test fails would not
look under an npm heading.

Both steps keep a two-line `> [!bug] Troubleshooting` callout that names the
symptom and links in with `see [[#Section|Section]]` — the specified form, not a
bare `jump to` sentence. Each new section carries a single
`⮕ Continue to <step>` link and no other, per the rule that a promoted section's
Continue link is its only link. Verified mechanically: five sections, five
Continue links, zero other links, and the `## Troubleshooting` back-link still
sits under the intro above the first `###`.

Two 17-line blocks were considered and **kept inline**. Step 6's `jssecacerts`
block is a Pitfall — a mistake you are likely to make — not a symptom you arrive
with, and the callout legend distinguishes those deliberately. Step 7's
intermediate-CA block is a `[!note]`: a condition to check before acting, not a
failure to recover from. Length alone does not promote; the reader arriving with
an error message is what does.

**A contradiction the move exposed.** The existing
`\`curl\` still fails against internal endpoints after Step 5` section said
"Only root **and issuing CAs** earn Always Trust". Step 5 says the opposite, and
correctly: only the root is trusted explicitly, and an issuing CA chains to it
on "Use System Defaults". This environment has two issuing CAs under one root —
trusting whichever one happened to be imported would not have covered the other,
which is the case that makes the rule matter rather than a stylistic
preference. Rewritten, with the `openssl x509 -noout -subject -issuer` check
that tells a root from an intermediate.

**Stale content corrected in the moved block.** The npm section still argued
that a one-certificate bundle is correct under interception — true before
Revision 45 combined the system roots in. It now reads
`grep -c 'BEGIN CERTIFICATE' "$CA_BUNDLE"` as the first diagnostic, treats a
count of `1` as the finding, and gives the rebuild. The intermediate-CA note's
"expect the count to go from 1 to 2" became "expect the count to rise by exactly
one", which survives the bundle no longer starting at one.

The moved blocks were re-checked against Revision 46's corrected paste rule: no
`#` comments and no bare placeholders in any Troubleshooting command block.

---

## Revision 46 — the comment rule covered half the defect

Revision 40 recorded that interactive zsh does not treat `#` as a comment, and
scoped the rule to **trailing** comments. That was the half that had been
observed. Pasting Revision 45's smoke-test block produced:

    function quote>

and then `zsh: unmatched '`. The block's only problem was three whole-line
comments — one of which read `# ... the first lines of the tool's own error`.
The apostrophe in `tool's` opens a quote that stays open until the next `'`
anywhere in the block, so it did not merely fail: it consumed the commands
below it, and the error named nothing that appears in the block.

Reproduced directly rather than reasoned about — `zsh +o interactivecomments -i`
gives `quote> quote> zsh: unmatched '`, `setopt interactivecomments` fixes it,
and non-interactive `zsh script.zsh` never had the problem. That last part is
why it survived every check: the blocks are correct as scripts and wrong only as
paste.

**The corrected rule.** No `#` comments in a command block at all, trailing or
whole-line. `reimaging-guide.md` → Core Assumptions and `runbook-prompt.md` both
carried the narrow version and now carry this one, with the apostrophe case and
the `quote>` symptom named so the next person can recognise it, and `Ctrl-C` as
the way out. The rule is explicitly scoped to blocks meant to be pasted:
comments in `bin/` and `.internal/` scripts are run by `bash`, never by an
interactive zsh, and stay.

Step 7's smoke block is stripped of its comments and the explanation moved to
the prose above it, which is where the rule says it belongs.

**Scope, measured with the corrected definition:** 186 hits across 16 documents
— 133 whole-line and 53 trailing — against the 53 previously recorded. Two carry
apostrophes and are therefore of the swallowing kind: one in
`reimaging-scripts-guide.md`, one in `restore-git.md`. Both are fixed here by
rewording, because that variant fails in a way that does not point at itself.
The remaining 184 are slice 4b.

**Why it recurred.** The rule was written down twice and enforced zero times.
`verify-script-portability.sh` lints shell files and has no notion of a fenced
block inside a document — and its pre-pass blanks whole-line comments before
matching, which is exactly inverted for this case, where the comment *is* the
defect. Slice 4b now builds that mode first and sweeps with the linter as ground
truth rather than sweeping by hand and hoping. A convention with no check is how
the same defect gets recorded twice and shipped three times.

---

## Revision 45 — the bundle was wrong, and four of five tests hid it

An operator's Step 7 run reported

    PASS  curl / PASS  node 200 / FAIL  npm / PASS  git / PASS  python

`npm` was right and the other four were not measuring anything.

**The bundle was wrong.** `npm config get cafile` was set correctly, which is
what made it fail: `cafile` **replaces** the trust store rather than adding to
it, and the bundle held only the corporate root. The decisive fact:

    $ openssl s_client -connect registry.npmjs.org:443 ... | openssl x509 -noout -issuer
    issuer=C=US, O=Google Trust Services, CN=WE1

Public traffic on this network is **not** intercepted — only internal hosts are.
Revision 42 built Step 7 on the opposite assumption, that a corporate-root-only
bundle is sufficient because everything is re-signed. On a network that
intercepts selectively, that bundle rejects most of the internet, which is
exactly what `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` was reporting.

The bundle is now the system roots **plus** the corporate root, built
unconditionally: it costs nothing where everything is intercepted and is the
difference between working and not where it is not. The step keeps the
`s_client` issuer check as the way to tell the two networks apart, and warns
when the system-root export yields nothing rather than shipping a one-
certificate bundle silently. Confirmed by the operator: 160 certificates,
`npm notice PONG 222ms`. Verified here against fixtures for both branches —
system roots present (corporate root appended last) and export failing.

**Four of the five tests were measuring the keychain, not the bundle.** macOS
`curl` and `git` consult the system keychain regardless of `CURL_CA_BUNDLE` and
`http.sslCAInfo`, and the python check used `urllib.request`, which reads
`ssl.get_default_verify_paths()` and never looks at `REQUESTS_CA_BUNDLE` at all.
So three tests passed on trust the bundle had nothing to do with, and `node`
passed because `NODE_EXTRA_CA_CERTS` **adds** rather than replaces. `npm` was
the only one of the five honouring its own setting unprompted, and the only one
to report the misconfiguration.

Each test now forces the bundle: `curl --cacert`, `git -c http.sslCAInfo=`, and
a python context built with `ssl.create_default_context(cafile=...)` reading the
path from the environment rather than interpolating it into the `-c` source. A
test that cannot fail when the thing it names is broken is not a test, and four
of these could not.

**`bin/restore-access.sh` (new, 909 lines).** Phase 10B had no entrypoint and
244 lines of inline shell — the largest such gap in the post-image set, and the
one Item 0 named first.

Its shape follows from what the phase actually is. `capture-managed-inventory.sh`
is one read-only pass; this phase has gates only a person can pass — the DMG
passphrase, an admin password for system trust, the judgment in the dotfile
merge. So the default walks Steps 0–10 in order, does the work at each, and
stops at a gate naming what it needs; every step is also a subcommand
(`restore-access.sh ssh`, `--from java`) so one can be re-run after a fix
without repeating the phase. `--dry-run` prints WOULD lines and changes nothing.

Privileged work is performed rather than printed, per instruction, with the
verification that makes that safe: `security add-trusted-cert` runs only on a
certificate proven self-signed, and only after checking whether enrolment
already trusted it; every `jssecacerts` it replaces is copied to
`.pre-reimage-<stamp>` first, because that file **replaces** `cacerts` in the
JVM and is not recoverable from the JDK install.

Step 8 is deliberately read-only. A script that copied the shell files would
remove the deliberation the phase depends on — `.zprofile` carries Phase 10A's
Homebrew and `nvm` bootstrap and Step 7's `REIMAGE-CA-BUNDLE` block, neither of
which exists in the pre-image backup.

Fixture-verified on this session's Linux VM: certificate classification against
a generated root, a CA-signed leaf and a non-certificate; SSH restore producing
600 on private keys, 644 on `.pub` and 700 on `~/.ssh` from deliberately wrong
source modes, keyed on file content rather than filename; the credential probe's
PRESENT/ABSENT rows; the dotfile report's four states; both bundle branches;
argument handling and exit codes (2 for an unknown step, an unknown `--from`,
and a valueless `--only`). `verify-script-portability.sh` passes, so nothing in
it needs a shell newer than Bash 3.2 or a GNU userland.

One defect caught in its own review: the smoke block first used
`command -v npm && smoke_one ... || skip`, where the `||` sees `smoke_one`'s
status rather than `command -v`'s — the same chain corrected in the runbook in
Revision 44, reintroduced while porting it. Rewritten as `if`/`else`.

**Not yet done:** the runbook still carries the inline blocks and does not
reference the script. Moving them under *Supplemental Reference* — the
`capture-managed-inventory.md` shape — is the remaining half, held back
deliberately rather than half-applied while the phase is being worked.

---

## Revision 44 — three failures the runbook could not explain

**A bare `FAIL` is not a finding.** Step 7's smoke tests printed `PASS` or
`FAIL` per tool and sent every error to `/dev/null`. An operator got

    PASS  curl / PASS  node 200 / FAIL  npm / PASS  git / PASS  python

which says something is wrong with npm and nothing whatever about what. The five
tools fail for unrelated reasons — trust, registry URL, proxy, auth, a dead
endpoint — so the one line that distinguishes them was the line being discarded.

The tests now run through a `smoke` helper that captures combined output and, on
failure, prints its first four lines indented under the `FAIL`. Verified against
four fixtures: success, failure writing to stderr, a missing binary (127), and a
command that reports its error on stdout — all four report correctly.

A troubleshooting entry covers the shape actually seen, which is *not* a trust
failure: four tools passing proves the bundle is good, and npm is the only one of
the five with its own registry, proxy and auth configuration. It also records the
asymmetry that produces it — `NODE_EXTRA_CA_CERTS` **adds** to the system store
while `cafile` and `CURL_CA_BUNDLE` **replace** it, so a one-certificate bundle
is sufficient for an intercepted connection and insufficient for one that
reaches the real internet untouched — with the `openssl s_client` check that
tells the two apart.

**Step 8 called an editor that does not exist yet.** It opened the dotfile
comparison with `code "$DOTFILES_BACKUP" "$HOME"`. VS Code is installed by
`restore-apps` (Phase 12) Step 6 — two phases after this one — so the command
fails with `command not found` for every operator who follows the runbook in
order. The same phase-ordering error as the `raycast/` row in Revision 42, and
worth stating as a pattern: a Phase 10B step may only use what Phases 8–10A have
installed.

Replaced with the base system and the Command Line Tools that Phase 10A does
install. A named walk over the candidate files reports `SAME` / `DIFFERS` /
`NO BACKUP` / `BACKUP ONLY` per file, then `git diff --no-index` reviews one at a
time through `$F`. Comparing `$HOME` as a tree was never an option — it would
recurse through everything the user owns. `vimdiff` is offered as the editor
form, and `code --diff` is noted as available later for anyone who prefers to
wait. Verified against a fixture exercising all four states.

The `.zprofile` warning gained the reason that did not exist when it was
written: as of Revision 42 that file also carries Step 7's `REIMAGE-CA-BUNDLE`
block, so overwriting it now loses the CA configuration as well as the Homebrew
and `nvm` bootstrap — and the symptom does not surface until an `npm install`
two phases later. The step says to re-run Step 7's block, which is idempotent,
if the file does get overwritten.

Also corrected there: the list of common selective restores mixes flat shell
files with directory entries — `.config/`, `.kube/`, `.cf/`, `.azure/` — that
`restore-home` (Phase 15) restores per-subtree. The step now says which half it
owns.

**Step 9 probed and then said nothing about the result.** Revision 42 replaced
"typical sources" with a `PRESENT` / `ABSENT` probe, which is an improvement that
stops one line short: an operator whose probe reports
`PRESENT cli-credentials 1 file(s)` still has no instruction. That single file is
almost always `gh/hosts.yml`, the GitHub CLI's stored OAuth token. The step now
says to prefer `gh auth login` over restoring it — a copied `hosts.yml` may name
an account, host or scope set that no longer applies, and re-authentication
re-issues against the account actually in use — with a guard for `gh` not being
installed until Phase 12, and the destination and mode for the case where
re-authentication is unavailable.

---

## Revision 43 — anchors were never checked, and two of them were mine

`verify-doc-paths.sh` verified that documented *paths* resolve. It never looked
at `[[doc#Heading]]` links, so retitling a heading broke every link into it
silently — the links still render and still click; they just land at the top of
the document instead of the section. Nothing failed, so nothing was noticed.

Two of the three genuine breaks were introduced in this session:
`restore-access.md`'s table of contents still pointed at
`#Step 0 — Record Prerequisites` and
`#Step 5 — Trust Imported Root and Issuing CA Certificates`, both retitled in
Revisions 37–42. The third is older: `restore-repos.md` cited
`restore-runtime#Step 5 — Install direnv and Restore the Repo Environment Hook`,
which is Step **6** — `restore-runtime` was renumbered and the cross-reference
did not follow. Its visible label said "Phase 10A Step 5" too, so a reader
following it would have gone to the wrong step by number as well as by link.

**What the check does.** Every `[[target#Heading|label]]` and `[[#Heading|label]]`
is resolved: the target document must exist, and it must carry a heading whose
text matches the anchor exactly, which is what Obsidian matches on. Results are
`ANCHOR OK` / `ANCHOR BROKEN` and broken ones share the `MISSING` exit status.
1,027 anchors across 51 documents now verify.

Three things the implementation had to get right, each found by a failing test
rather than by reading:

- **Escaped pipes.** Inside a table an anchor is written `[[#Heading\|label]]`.
  The backslash belongs to the table syntax, not the heading. Five links looked
  broken until the extractor stripped it.
- **`read` eats a leading tab.** The extractor emits `target<TAB>anchor`, and
  `IFS=$'\t' read -r a b` strips a *leading* tab as IFS whitespace — so a
  same-document link (`<TAB>Heading`) put the anchor in the target variable and
  left the anchor empty, and the loop skipped it. Every `[[#Heading]]` in the
  repository was being ignored: 3 anchors checked in `restore-access.md` instead
  of 29. Now split with `${row%%$'\t'*}` / `${row#*$'\t'}` after `IFS= read`.
- **Fenced examples are not links.** `runbook-prompt.md` shows authors what a
  cross-reference looks like, inside a fence. The extractor is a single awk pass
  that tracks fence state — including fences opened inside a blockquote — rather
  than `grep -o` piped to `sed`, which also removes a BSD-`sed` portability
  problem: no `\?` and no `\t` expansion in a replacement.

**`--all`.** The default document set is the seven governance docs, which
contain no wikilinks at all — so the check would never have run in practice.
`--all` scans every Markdown file except `APPLY-MANIFEST.md`, which is excluded
on purpose: it is a change log quoting paths as they were at the time of a
revision, so a reference that no longer resolves is the record working
correctly. `.github/ai-templates/` stays excluded for the reason already
documented.

`--all` is **not** the default, and that is a deliberate hold rather than an
omission. It reports 83 WARNs, and they are structural: runbooks name artifact
outputs — `time-machine-status.md`, `checklist.md`, `clone-commands.sh` — which
live on the artifact drive and are correctly absent from the repository. A
default run that always prints 83 warnings teaches people to skip the output.
Promoting `--all` to the default needs a way to tell an artifact-root output
from a repo file first; that is not solved here.

**Four stale paths, surfaced by running `--all` for the first time.**

- `references/artifact-config-reference.md` named
  `.internal/scan-archive-contents.sh` four times; the helper is at
  `.internal/home/scan-archive-contents.sh`.
- `prepare-artifact-root.md` named `bin/backup-home-files-backup.sh` twice. No
  such script has ever existed — the entrypoint is `bin/backup-home.sh`.
- `restore-home.md` argued, correctly, that this phase has no entrypoint, but
  wrote the hypothetical as `bin/restore-home.sh` — a live-looking path to a
  file that is deliberately absent. Reworded so the name is still readable while
  the absence is stated as the design.
- Six `[[references/toolkit-environment-reference|...]]` links were reported
  MISSING. That one was the validator's fault: a wikilink names its target
  without the extension, which is correct Obsidian syntax. An extensionless
  token now resolves against `<token>.md`. Only extensionless tokens qualify, so
  an absent `bin/foo.sh` still fails — verified with a fixture carrying one of
  each.

`--all` is now clean: 51 documents, 0 MISSING, 1,027 anchors, 0 broken.
`verify-script-portability.sh` still reports 65 CLEAN / 0 WARN / 0 FAIL.

---

## Revision 42 — a placeholder the operator cannot fill

Step 7's re-establish block read

    CORP_CERT="$MNT/certs/loose-candidates-selected/<the root file you pinned in Step 4>"

Quoted, so it was not the redirection defect from Revision 41 — the worse
version of it. The line ran, `$CORP_CERT` took a literal path containing angle
brackets, and the guard printed

    CORP_CERT is not set (MNT=/Volumes/all-secrets-...)

which is wrong twice over: `CORP_CERT` *was* set, and `MNT` — the only thing the
message names — was the one part that had worked. Four distinguishable failures
(no image, no such file, not a certificate, fine) were collapsed into one
message that pointed at the wrong one.

Behind that was a worse assumption: that the operator could supply the filename
from memory. Step 4 is GUI work in Keychain Access, three steps back, and the
names in `loose-candidates-selected/` are whatever the person who exported them
chose. On the machine this was found on, four files sit there and only one is
the root.

Step 0 now lists the directory and classifies each file by the property that
actually defines a root — subject equal to issuer — printing `ROOT`,
`NOT A ROOT` or `NOT A CERT` with the distinguished names that justify the
verdict. The operator substitutes a name they have just read rather than one
they are trying to recall, and the pin re-checks it: file exists, parses as a
certificate, and echoes its subject, issuer and dates. Each of the four
outcomes now prints its own line.

The Pitfall is re-aimed. The old one warned about `$CORP_CERT` being *unset*;
the reachable failure is that the example filename is left in place, which the
new check catches before step 1 could truncate `~/.certs/corp-root.pem` to zero
bytes.

**Step 1 no longer writes before it verifies.** The same placeholder pattern sat
in the keychain form —

    security find-certificate -a -c "<Root CA common name>" -p ... > ~/.certs/corp-root.pem

— and was run as written. `-c` matched nothing, so the redirect created a
zero-byte `corp-root.pem`. The `grep -c` caught it, but only after the
destination had already been destroyed: the check was downstream of the damage.

Both sources now write `/tmp/corp-root-staging.pem`, and a single gate decides
whether anything reaches `~/.certs/`. It reports `EMPTY` (with the two reasons,
one per source), `NOT A ROOT` (subject and issuer differ, printed so the verdict
is checkable), or `INSTALLED` with the count and the certificate's subject,
issuer and dates. `ROOT_CN` is assigned on its own line for the reason step 0
gives: a named value can be read back, survives a re-run, and fails legibly when
pasted unchanged. Verified against generated fixtures for all three branches —
empty file, self-signed root, CA-signed leaf.

The `count` capture is `count="$(grep -c ...)" || count=0` rather than
`|| echo 0`: `grep -c` prints `0` *and* exits 1 on no match, so the `echo` form
yields two lines and the arithmetic test then fails on a malformed operand.

Also corrected in the same step: the intermediate-CA note said
`cat root.pem issuing.pem > ~/.certs/corp-root.pem`, which truncates its own
input when `root.pem` is the file being written. It now appends.

**`~/.certs/corp-root.pem` appeared eight times as a literal.** Steps 2 through 5
each spelled the path out, so the destination step 1 had just chosen was
re-asserted by hand at every use — the same class of defect as the filename in
step 0, one level up.

The first attempt at the fix only moved the literal: `CA_BUNDLE` was assigned
inside the gate, and the `.zprofile` heredoc still spelled the path out four
more times. The path is now written down once, at the top of step 1, split into
`CA_BUNDLE_REL` and `CA_BUNDLE`. Step 2 does not re-declare it — a fresh
terminal re-runs those same two lines, which is the point of them being the one
definition.

The split into a relative and an absolute half is not decoration. The
`.zprofile` block has to put a *literal* `$HOME` in the file, so it stays
correct if the account moves, while taking the *filename* from a variable. A
quoted heredoc gives the first and refuses the second. `printf` with a
single-quoted format string gives both: `'export %s="$HOME/%s"'`. Verified —
setting `CA_BUNDLE_REL=.certs/ALT-NAME.pem` changes what lands in `.zprofile`,
and no absolute home path leaks into the file.

**`CA_BUNDLE` is deliberately not derived from `CORP_CERT_FILE`.** They look
like the same value and are not. `CORP_CERT_FILE` names a file on the mounted
image; `CA_BUNDLE` names the file five tools are pointed at for the life of the
machine. Deriving one from the other breaks on all three counts: the keychain
source (A) never sets `CORP_CERT_FILE` at all, so the derivation is undefined on
the path the runbook recommends; the bundle may later hold the intermediate as
well as the root, which makes a name inherited from the root file wrong; and a
future image whose export is called something else would silently move the path
every tool's config already points at. The step now says this where the
variables are introduced.

**`ROOT_CN` read as a filename.** Sitting one block below
`CORP_CERT_FILE="root-ca.pem"`, an example value of `"Root Example CA"` gave no
signal about which kind of thing it was. It is a certificate common name matched
against the keychain — nothing on the DMG, nothing ending in `.pem` or `.cer`.
The step now says so against the `"labl"<blob>=` output it comes from, and a
three-row table contrasts `CORP_CERT_FILE`, `ROOT_CN` and `CA_BUNDLE` by kind of
value.

Two smaller corrections in the same pass. The current-shell exports and the
`.zprofile` lines are both generated from one variable list, so the four names
appear once rather than eight times; `export "$v=$CA_BUNDLE"` does that without
`eval`. And the intermediate-CA note still wrote `~/.certs/corp-root.pem`
literally and carried a bare `<issuing-cert>` inside inline code — it is now a
real command block using `$CA_BUNDLE`, with the count check that shows the
append worked, and it says to reach for it only after a clean `INSTALLED`
followed by `unable to get local issuer certificate`.

Steps 2 through 5 collapse to 2 and 3. The old split was per-tool — Node, Git,
Python — which put a `.zprofile` append in three separate blocks. Working the
step twice appended the exports three times over, and nothing said so. The
environment variables are now one `.zprofile` block behind a `REIMAGE-CA-BUNDLE`
marker that reports `ADDED` or `PRESENT`, written by a quoted heredoc so `$HOME`
reaches the file unexpanded. The per-tool config writes stay separate but are
guarded: Step 7 runs in Phase 10B, *before* Phase 12 installs npm and pip, so
each reports `SET` or `SKIP` instead of failing into the scrollback. The smoke
tests do the same, and the step says plainly that a `SKIP` is not a pass.

The smoke tests were rewritten from `cmd && printf PASS || printf FAIL` chains
to explicit `if`. The chain form is wrong for the guarded cases: in
`command -v node && node -e ... || printf SKIP`, the `||` sees *node's* exit
status, so a node that exists but fails TLS prints both `FAIL node` and
`SKIP node`. Per-tool one-line-of-output is the property that matters here and
the chain form does not have it.

Verified on fixtures: the step 1 gate against a generated self-signed root, a
CA-signed leaf and an empty file — one branch each; the `.zprofile` block run
twice against both a missing and a pre-existing profile — one marker, four
exports, literal `$HOME`, nothing clobbered. The smoke block's network calls
were not exercised; this environment has no egress for them.

**The hand-restore table claimed more than it could.** Its opening sentence said
these categories have "no runbook anywhere else in the toolkit", and two of the
seven rows did. `raycast/` is owned by `restore-apps` (Phase 12) Step 7, and
Raycast is not installed at Phase 10B, so following the row as written meant
importing into an application that is not there. The row now defers, and carries
the one thing this phase genuinely owes Phase 12: the `.rayconfig` password from
Phase 3C, which is not in `reimage.env` and is unreachable once the DMG is
ejected. The `chrome/` row now says that profiles and extensions are Phase 12
and that nothing on the row feeds them, so "intentionally not restored" is not
read as "Chrome is not restored".

`kube/` overlaps `home-files-backup/dotfiles/kube/`, which `restore-home`
(Phase 15) restores from a different source — the row now names the overlap and
the ordering.

The `cloud/` (AWS) row is deleted. There is no `cloud/` category: the image
carries fourteen, `cli-credentials/` among them, and AWS profile files are in
that one. The table gained an **Owner** column so this is answerable at a glance
rather than by reading each cell.

**Conditional categories were being read as nonexistent ones.** Step 9 named
`$MNT/licenses/` and `$MNT/package-managers/` as "typical sources" while
*Artifact and Script Locations* said there is "deliberately no `git/`,
`licenses/`, or `package-managers/` category". The two passages did contradict
each other — and the second one was the wrong half. `create-secrets-dmg.sh`
stages all three explicitly; they are **conditional**, created only when there
is applicable material, and this image simply had none. Absent is not
unsupported, and the first fix here deleted them on the strength of one image's
`categories.txt`, which is exactly the wrong inference to draw from a
conditional category.

The note now says the list is what this image carries rather than the whole
scheme, and separates the two reasons a category can be missing. `cloud/` (AWS)
is the one excluded by design — cloud CLIs are re-authenticated rather than
restored — and `create-secrets-dmg.md` → *What Gets Staged* is cited as the
authority.

That note also conflated `git/` with `~/.gitconfig`. The category holds
`~/.git-credentials` and the helper cache, which are credentials; `.gitconfig`
is not one and lives in `home-files-backup/dotfiles/` for Phase 11A. Both facts
are now stated, and the fact that they are easy to confuse is stated with them.

Step 9 lists all four credential categories again, marks them conditional, and
replaces "typical sources" with a probe that reports `PRESENT` with a file count
or `ABSENT` per category — so a missing directory reads as "nothing was staged",
which is what it means. It also says to prefer re-authentication for `git/` and
`package-managers/`: a registry token or helper cache off a three-week-old image
is as likely to be stale as valid. The Pitfall points secret license screenshots
back at `secrets-encrypted/licenses/`, with the timing that matters — staging
them there before the Phase 3C build is what causes the category to exist, and
nothing is added to a DMG after it is built.

The `cloud/` row deleted from the hand-restore table stays deleted, but for the
better reason: not "the image carries fourteen categories" but that the producer
excludes it deliberately.

Caught in the same pass: the new cross-reference pointed at a
`create-secrets-dmg#Categories and Sources` heading that does not exist.
`verify-doc-paths.sh` checks paths, not wikilink anchors, so it passed. Fixed to
*What Gets Staged*, and every `[[doc#anchor|...]]` in `restore-access.md` was
checked against the target's real headings — the rest resolve.

One bare placeholder survived Revision 41 in this runbook: `ssh -G <alias>` in
the Step 3 troubleshooting callout. Callout-nested blocks were invisible to that
sweep because every line carries a `> ` prefix. Fixed by assignment, as the rule
prescribes.

---

## Revision 41 — a bare `<placeholder>` is a redirection

`ssh -T git@<alias-from-the-list-above>` fails with
`no such file or directory: alias-from-the-list-above`. `<` and `>` are
redirection operators in every POSIX shell, so a bare angle-bracket placeholder
in a command block is parsed as a redirect rather than as a blank to fill in —
and the error names the placeholder, which reads as a broken command instead of
an unfilled one.

Thirteen bare placeholders exist across the runbooks; three were written in this
session. The three in `restore-access.md` are fixed, two by quoting and one by
the better form — assigning on the line above, which names the value, survives a
re-run, and fails clearly when pasted unchanged.

`reimaging-guide.md` → Core Assumptions now covers this alongside the `#` case
from Revision 40; they are the same lesson, that a pasted block passes through a
shell first. `runbook-prompt.md` carries the rule, scoped to executable lines —
angle brackets in prose, tables and heredoc bodies are fine.

The remaining ten live in `backup-home.md`, `prepare-artifact-root.md`,
`reimaging-scripts-guide.md`, `restore-docker.md`, `restore-home.md` and
`run-time-machine.md`. Slice 4.

**Step 6's TLS validation names how to choose a host.** "Use an internal
endpoint" was the vague half: an internal-looking host serving a publicly-trusted
certificate passes the test without exercising the corporate root at all. The
step now selects by issuer — an `openssl s_client` loop printing each
candidate's issuer — and says that if every candidate reports a public issuer the
test proves nothing and should be deferred to the first real build rather than
recorded as a pass that measured nothing. It also points at where the operator's
own config already names internal hosts.

---

## Revision 40 — freshness, a real Step 6 validation, and zsh comments

**Comparison freshness (`--reprobe`).** The exit checklist's
`Runtime comparison recorded` row asked whether a comparison *existed*, never
whether it still described the machine. On this repo a nine-pass sign-off cited a
comparison recording Node at `v24.19.0` — the regression — while the machine was
already fixed to `v26.7.0`. The row was green because a file was present.

Time cannot answer it. That stale comparison was four minutes older than the
checklist citing it, and a comparison being older than its exit checklist is the
*normal* ordering. What went stale was the content, so the check is a content
check: `compare-restored-state.sh --reprobe` re-runs the probes now and diffs
them against the `live` column of the official run.

It lives in the comparison script rather than the recorder deliberately. The
probe table must exist in exactly one place; copying it into the exit recorder
would be the two-implementations-of-one-contract failure that this row exists to
catch, reintroduced by the fix for it. It also uses that table rather than
re-executing commands stored in the run file — nothing here evaluates a shell
command read off the artifact drive — and reports a label the table no longer
covers instead of silently dropping it.

Exit 0 no drift, 1 drift, **2 the question cannot be asked**. The recorder turns
2 into a `record_manual` row rather than a pass or a fail, because scoring "could
not check" as either is how a checklist starts lying. Verified against the live
drive: the drift path returns 1 with a per-tool table, and a run with no
`rows.tsv` returns 2 with the reason. The reprobe reads only the `live` column,
so runs predating the tab fix in Revision 34 compare correctly anyway.

**Step 6 said "validate an internal TLS use case afterward" and stopped there.**
It now carries two checks that answer different questions: a `keytool -list`
count confirming the JVM can read the store at all, and a single-file Java
program that completes an actual handshake. `curl` is explicitly ruled out —
it reads its own CA bundle, not the JVM's, so it passes while Java still fails.
A table reads the outcome by its failure mode: `PKIX path building failed` is
the wrong JDK or a store without the root; `UnknownHostException` is network and
not trust at all.

**Step 7 used `$CORP_CERT` on its first line and set it nowhere.** Step 4 pins
it, and Steps 4 and 5 are GUI work, so a fresh terminal by Step 7 is the normal
case. Unset, it expands to an empty path, both `openssl` forms fail *after*
truncating `~/.certs/corp-root.pem` to zero bytes, and five tools go on to trust
an empty bundle. A step 0 re-establishes `$MNT` and `$CORP_CERT` and prints the
subject as proof; a Pitfall names the zero-byte outcome; and where the image is
already detached it points at the keychain export instead of a needless re-mount.

**Trailing `#` comments are out of command blocks.** Interactive zsh — what the
operator pastes into — does not treat `#` as a comment unless
`interactivecomments` is set. `grep -c PATTERN file   # expect 1 or more; 0 means
failed` therefore ran `grep` with five extra filenames and then tried to execute
`0`. The command had succeeded; everything after it was the comment running.

Found by an operator hitting it live. Thirty-five such lines exist across ten
runbooks and nothing warned about any of them. `reimaging-guide.md` →
Core Assumptions now states the behaviour once, beside the working-directory
assumption, with the `setopt` for anyone pasting their own. `runbook-prompt.md`
bans them in new blocks, noting the rule was already implied: the prompt requires
a one-line sentence above every block, and a trailing comment duplicates that
into the single place it can break. The two in `restore-access.md` are cleared and
their content moved to prose, including the `grep -c` reading — `<path>:1` rather
than a bare `1` is normal, since `grep` prints the filename when it believes it
was given more than one.

The remaining thirty-three are covered by the Core Assumptions statement and left
for slice 4.

---

## Revision 39 — a runbook has no memory of itself

Four passages in `restore-access.md` explained what an earlier revision of the
step had said before it was corrected. All four removed, substance kept as
present fact: "there is no `jssecacerts` at the top of `java-security/` — every
store sits one level down under its JDK label" carries everything the
archaeology did and stays true after the next rewrite.

The rule is now in `.github/ai-prompts/runbook-prompts/runbook-prompt.md`, with
the distinction that makes it not arbitrary: `bin/` and `.internal/` scripts
*should* carry "an earlier revision got this wrong" comments — that is how a fix
survives the next person who finds the code surprising, and it was already the
convention there before this session. A runbook should not. A code comment is
read by someone changing the code; a runbook step is read by someone following
it. Different audiences, different rules. Before this session no runbook in the
repository contained the phrase; all four instances were introduced here.

---

## Revision 38 — a path that never existed, and a version that would go stale

**Step 6 copied from a path the image has never had.** It read
`"$MNT/certs/java-security/jssecacerts"`. Phase 3A captures **one store per
JDK**, each under its own label — `java-security/openjdk-21.jdk/jssecacerts`,
`.../temurin-17.jdk/jssecacerts`, and so on. The flat path fails with "No such
file or directory", which reads as a missing capture rather than a wrong path.
Third instance of that shape in this runbook, after the `git/` category and the
`Step 11` references.

The step now lists `"$MNT/certs/java-security/"` first, has the reader pick the
label matching the JDK they pinned, and verifies the choice against
`java-jssecacerts-inventory-*.md` — which sits beside the image and is readable
**without the DMG password**, so the file can be confirmed before it is trusted.

**And it surfaced a design fact the step never mentioned.** `jssecacerts` does
not extend `cacerts`; the JVM uses it *instead of* `cacerts` when present. Copying
a captured store therefore replaces the new JDK's entire trust set with the old
machine's, public roots included, frozen at capture date. The step now prints
what the capture actually adds — a `keytool -list` diff of both stores — and
offers two forms: **A** wholesale copy for a recent capture, **B** fresh
`cacerts` plus only the added aliases when the capture is months old.

That choice is also now a bullet in **Confirm Your Intent**, because A is one
command and B is several, and meeting that fork halfway through Step 6 is how A
gets chosen by momentum rather than on the merits.

**The JDK version is no longer hardcoded anywhere that runs.** `-v 21` appeared
in three live checks across both boundary recorders and in the Step 6 pin, plus
the Pitfalls quoting them. All of it would have started failing the day the
baseline moved — and failing in a way that reads like a missing JDK. Both
recorders gained `resolve_java_home` / `java_baseline_label`: an optional
`REIMAGE_JDK_BASELINE` in `reimage.env` pins a major when several JDKs are
installed, and unset means the machine default. **The rows now report which path
resolved instead of asserting a number**, so the evidence carries the answer and
there is nothing left to go stale. `reimage.env.example` declares the key,
documenting that Phase 10B writes the trust override into whichever JDK resolves
here — so an unpinned value on a multi-JDK machine can put it in the wrong one.

The two new helpers are duplicated across both recorders, which is the same
preamble the entrypoint review is meant to extract. Noted rather than extracted,
for the reasons given in Revision 35.

**Still hardcoded, deliberately:** `restore-runtime.md`. That runbook *installs*
the JDK, so naming a baseline there is a stated decision rather than an
incidental constant. Its `java_home -v 21` verification commands should follow
this pattern and are left for slice 4.

---

## Revision 37 — trust anchors, and the post branch reads the index

**Step 5 was telling the operator to do the wrong thing, in its title.** It read
"Trust Imported Root **and Issuing CA** Certificates" and instructed setting
Always Trust on both. A root is a trust anchor and needs an explicit override; an
intermediate is vouched for by the root and validates through the chain. Trusting
an intermediate directly creates a second independent anchor — it survives the
root being revoked, and since intermediates rotate far more often than roots the
override goes stale and starts bypassing the chain it was meant to follow.

Found by an operator mid-phase, who saw `Root GAIG CA` at `Always Trust` /
"marked as trusted for this account" and `Issuing-CERTPROD-CA01` at
`Use System Defaults` / "This certificate is valid", and asked what to do about
the difference. The answer was *nothing* — that is the correct end state, and the
runbook was the thing in error.

The step is now "Trust the Internal Root Certificate". It opens with
`security dump-trust-settings` for both domains, gives a two-row table of the end
state to confirm, and says plainly that if both already read that way the step is
done. Troubleshooting added: an intermediate that is not "valid" means the
problem is **above** it, and trusting the intermediate hides a broken chain
rather than repairing one. The `record_manual` row in `record-restore-exit.sh`
endorsed the same error and is corrected to match.

**Step 4 asked the image before it asked the machine.** On a managed Mac,
enrolment usually installs the corporate CA chain through a profile, so much of
what the step would import is already present. It now leads with
`security find-certificate -a -Z`, scopes the import to the gap, and notes that a
*missing* cert therefore means enrolment did not deliver it — a different problem
with a different fix, previously invisible because the step never looked.

It also gained a **CA-versus-leaf gate**. A directory of `.pem` and `.cer` files
says nothing about which are authorities, and the names mislead: `<org>-cert.pem`
sits beside `<org>-issuing-ca.pem` and `root-<org>-ca.pem` and is a leaf. The new
block prints `subject`, `issuer`, `sha256` and `Basic Constraints` for every
candidate, with a table saying what each field decides — `CA:FALSE` is a leaf,
`subject = issuer` is a root, and `sha256` is the only safe identity to match on,
since the same CA is routinely filed under different labels in different places.
Previously this rule existed only as a manual row in the exit checklist, which is
too late to be the only place it is said.

**Slice 3b — `bin/reimage-checklist.sh --phase post`.** Revision 36's migration
broke it: the post branch globbed `*initial-reimaged-system-*` at `-maxdepth 1`
and `-maxdepth 2`, and the migrated runs match neither — different name, one
level deeper. It now sources `artifact-runs.sh` and resolves the Phase 9 bundle
through `artifact_run_official`, and the evidence-stamp search reaches depth 3
with the run-grammar name. The legacy pattern was dropped rather than kept
alongside, per the no-compatibility-shims rule.

The rewrite also fixed something the glob could never express: it now separates
"never ran it" from "ran the pre-restart half and never came back after the
restart". The second looks like progress and is the one worth catching. Verified
against the live drive — post-restart, pre-restart, and the evidence stamp all
resolve.

---

## Revision 36 — first-boot bundles onto the run index, and three live blockers

**Data migration, on the artifact drive.** Six Phase 9 bundles moved off the
`reimaged-system/` root into `reimaged-system/restarts/runs/`, renamed to the run
grammar with the runbook name as `what`:

| was | now | point |
|---|---|---|
| `initial-reimaged-system-20260818-073250` | `post-image-verify-reimaged-system-initial-20260818-073250` | `unknown` |
| `pre-restart-…-002743` · `-003459` · `-004132` · `-012631` | `post-image-verify-reimaged-system-pre-restart-…` | `pre-restart` |
| `post-restart-…-013423` | `post-image-verify-reimaged-system-post-restart-20260819-013423` | `post-restart` |

The category folder carries the `initial-reimaged-system` identity; the run IDs
follow the grammar. The bare bundle indexes as `unknown` rather than being
guessed into a lineage — it carries no context label, and inferring one under a
first-wins rule that does not self-correct is the failure the rule exists to
prevent.

**Inside the bundles.** `initial-checklist.md` → `checklist.md` and
`time-machine-reimaged-system-plan.md` → `time-machine-plan.md` in the bare
bundle, so all six agree; anything reading `<run>/checklist.md` now finds it in
every one. The empty `checks/` directory was retired from all six — nothing has
ever written into it, and six copies of an empty directory is the
*Before adding a directory* rule violated six times.

**The pin.** `pre-restart` is first-wins, which named `002743`. Pinned to
`012631` with a reason: four runs precede the stabilization restart at 01:34 and
this is the last of them, so it is the state the machine was actually in when it
restarted. `002743` is an hour and three runs stale. The pin marker is in the run
directory; the manifest carries the reason.

**A bug in the migration itself, caught by its own check.** The first pass
derived the context with `${run%-*}`, which strips one dash-segment — and the
stamp `20260819-002743` contains a dash, so every context came out as
`…-20260819` and every point as `unknown`. The parse-back assertion written into
the migration returned 0 rows for all three lineages and stopped it. The index
was discarded and rebuilt with `${run%-*-*}`. The lesson is the one this repo
keeps relearning: the check that catches the mistake has to run, not be read.

**Producer converted (`bin/record-reimaged-system.sh`).** It brackets its work
with `artifact_run_begin` / `artifact_run_finalize` against
`<output-root>/restarts`, maps `--context pre-restart` straight onto the point of
the same name, defaults to `initial` (→ `unknown`) when no context is given, and
no longer creates `checks/`. The `latest-initial-reimaged-system-bundle.txt`
pointer is gone: one pointer cannot name three lineages, and naming whichever ran
last is precisely the bug that made `verify-reimaged-system.md` Step 6 hand-roll
its own prefix-filtered selection.

**`check_10A` repointed.** It read that retired pointer for the Phase 9 sign-off
row. It now asks the run index for the official `post-restart` run — the lineage
a Phase 9 sign-off is actually about, being the one taken after the restart.

**Retired, awaiting your deletion.** `device_bash` cannot delete on the mount, so
everything retired was moved to `reimaged-system/_to_delete/`: six empty
`checks/` directories, the legacy latest-bundle pointer, the discarded
first-attempt index, and an `.rmtest` scratch directory left by probing whether
`rmdir` works. Remove that folder when you are ready.

**KNOWN CONSEQUENCE — `bin/reimage-checklist.sh --phase post` is now stale.**
Lines 1456, 1482 and 1484 glob `*initial-reimaged-system-*` at `-maxdepth 2`
under `reimaged-system/`. The migrated runs match neither: the name no longer
contains that string and they sit at depth 3. Phase 14 will under-report until
its post branch reads the run index instead. That is slice 3b, and the migration
promoted it from deferred to required — it is not blocking now, Phase 14 being
several phases away, but it must land before Phase 14 runs.

**Also still describing the old layout:** `reimaging-guide.md`,
`verify-reimaged-system.md`, `reimaged-system-checks.md`,
`reimaging-scripts-guide.md`, and the three references. Slice 4.

**`restore-access.md` — three defects found by following it live.**

*Step 3 named a DMG category that has never existed.* `cp -R "$MNT"/git/. ~/`
fails with "No such file or directory" on every machine: the image's own
categories sidecar lists fourteen categories and `git` is not among them, and the
build manifest holds no `.gitconfig` or `.config/git` row at all. Phase 3A never
staged them because they are not credentials — they are in
`home-files-backup/dotfiles/`, and Phase 11A restores them. The line also
contradicted this runbook's own Ownership table twelve lines above it and the
note directly beneath it. Removed, with a note saying where Git config actually
comes from and how to list what an image holds without the password.

*Step 3's SSH check could not distinguish three different failures.* A first fix
added a `nc -z` port probe and claimed a successful probe meant the key was at
fault. Running it disproved that within minutes: `nc -z github.com 22` succeeded
while `ssh -T` still died with `ssh_dispatch_run_fatal … Operation timed out`.
`nc -z` opens a socket and sends no SSH traffic, so it reports green on a path
that cannot carry a session. The Pitfall now separates all three — auth refusal,
port blocked, and TCP-connects-but-protocol-hangs — names the MTU and middlebox
causes of the third, and points at `ssh -vvv` to locate where it dies.

Worth recording separately: **nothing in this workflow has ever tested port 22.**
Phase 9's `network-github.txt`, the 10A entry check, and the 10B exit rows all
speak HTTPS. `ssh -T` at Step 3 is the first thing that has ever tried SSH on a
rebuilt machine, so a timeout there is not evidence of a regression.

*Step 0 now absorbs the before-state capture.* `bin/record-restore-state.sh`
existed but appeared nowhere in this runbook, so following the runbook — which is
what the operator was doing — could never produce a state capture. Step 0 becomes
"Record Prerequisites and the Before-State": 0a the prerequisite check, 0b the
state capture. Numbered as sub-steps rather than a new Step 1 because renumbering
1-10 is the renumbering-slip failure this repo has already paid for, and no
runbook here has ever used a lettered or fractional step. A Pitfall states the
asymmetry plainly: 0a is rerunnable and costs nothing to repeat, 0b is gone once
Step 1 mounts and Step 3 writes, and a late `before` becomes permanently official
under first-wins while describing a machine the phase already changed.

*The Artifact and Script Locations block was wrong in both directions.* It listed
three DMG categories that have never been built — `git/`, `licenses/`,
`package-managers/` — and omitted ten that exist: `chrome`, `claude`,
`claude-code`, `docker`, `extra-secrets-certs-review`, `gnupg`, `intellij`,
`kube`, `raycast`, `repos-gitignored`. Now lists all fourteen, each annotated
with what restores it, plus the command that reads the image's own category
sidecar without the DMG password. Its artifacts block described `prereq-checks/`,
`exit-checks/`, `restore-targets/` and three `latest-*.txt` pointers, none of
which exist; replaced with `boundaries/` and `state/`, their manifests, and their
per-lineage `official/` pointers. `~/.gitconfig` and `~/.config/git/` are marked
NOT written by this phase. All three references to a Step 11 that was never
written are gone — the exit recorder is now described as "the closing step that
runs it is NOT YET WRITTEN", which is true.

*Step 3's SSH test named the wrong host.* `ssh -T git@github.com` is misleading on
any machine using host aliases — which is the convention `restore-git.md`
establishes for work-versus-personal routing. Found live: the operator's config
defines `github.com-shiva` with an `IdentityFile` and no bare `github.com` block
at all, so the documented test offered no key and returned `Connection closed`,
which reads exactly like a failed key restore. The step now lists the aliases the
restored config defines and tests those; the Pitfall gains `Connection closed` as
a third distinct failure with `ssh -G` to resolve it; and the 443 workaround is
shown as two lines added to the alias block that already carries the key, rather
than the bare `Host github.com` block that caused the symptom.

*Step 4's Pitfall reported one machine's run as the rule.* It said "this
machine's Phase 3A run recorded four identities, all refusing export". Generalised
to the mechanism — non-exportable identities produce review notes instead of a
`.p12`, and the material moves to `loose-candidates-selected/` — which is what
makes the listing-first approach necessary rather than a specific history.

---

## Revision 35 — the before/after state capture

**New file: `bin/record-restore-state.sh`** (mode 755). Also
`.claude/CLAUDE.md` and `.github/ai-prompts/README.md`, which both pointed at a
`runbook-fill-prompt.md` that does not exist; the file is `runbook-prompt.md`.
With those two fixed, `verify-doc-paths.sh` reports **0 MISSING** for the first
time — 104 OK, 0 WARN, 6 SKIP.

**What it captures, and why the phase's own before matters.** Phase 10A's
before-state is permanently gone, so its drift review had to be reconstructed
from a cross-erase comparison against the Phase 4B inventory. That answers a
weaker question: "does the rebuilt machine match the one that was erased" is not
"did this runbook put what it promised where it promised". Every restore phase
from here can answer the second, but only if something records the before. It
also unblocks `compare-restored-state.sh --against before`, which today refuses
with exit 2 rather than diffing against a baseline that does not exist.

**Four states, not two: present / absent / unresolved / unreadable.**
`unresolved` is the one that earns its keep. With `JAVA_HOME` empty,
`$JAVA_HOME/lib/security` collapses to `/lib/security`, which genuinely does not
exist — so a two-state check records `absent`, a confident wrong answer about a
path nothing ever looked at. At a `before` boundary an empty `JAVA_HOME` is the
*correct* state, because `restore-access.md` Step 6 is what sets it.
`unreadable` separates "not there" from "there and I was not allowed to read
it", which is what a locked keychain or a root-owned key looks like.

**Where the 19 paths live: a `paths` function in the script**, mirroring
`check_10A` / `check_10B` in the recorders beside it. The artifact-config
fragments describe the *artifact root*; these describe `$HOME`, and a fragment
set for one consumer would be a directory created in anticipation of files.

**Three traversal modes rather than numeric depths.** `file` hashes one path;
`tree` recurses; `shallow` stops at depth 1. `~/.config/` is `shallow` because
recursing there buries the fifteen paths that matter under thousands that do
not. **The directory itself always gets a row**, in both `tree` and `shallow`,
and so does every subdirectory under `tree` — without that, a present-but-empty
`~/.ssh` produces no rows at all and reads exactly like a path nobody checked.
That is the empty-expectation-set trap, and it was closed at the top level and
left open one level down until a fixture caught it.

**Hashes, not contents.** SHA-256 per file. Filenames are recorded in the clear:
the DMG's own build manifest already lists them, and an obscured name makes the
diff unreadable for no gain. Symlinks record their target instead of a hash.

**The path is the LAST TSV field**, and every other field is whitespace-squashed.
`rows.tsv` in `compare-restored-state.sh` learned this the hard way in Revision
34 — a recorded value carrying a tab split one field into two. A filename may
legally contain a tab, so putting it last costs the last field rather than
shifting every column.

**`before` is first-wins**, so re-running leaves the earliest run official and
says so on stderr. `after` is a separate lineage and latest-wins.

**A bug the fixtures caught, worth recording because it is the house pattern.**
`resolve_target` was called as `if ! resolved="$(resolve_target "$spec")"`. That
runs the function in a SUBSHELL, so the `UNRESOLVED_VAR` it sets is set in a
child and lost — the first fixture run printed `($ is empty)` with no variable
name. A function with two outputs, one of them only on failure, cannot report
through a command substitution. It returns through globals now.

**Placement: `bin/`, corrected during review.** It was first drafted under
`.internal/restore/` on the strength of the carve-out that keeps the boundary
recorders there. That was wrong, and the repo's own graduation rule says so — *a
helper graduates to `bin/` when a runbook tells the reader to run it directly* —
which is exactly what its usage block does. The carve-out does not reach this
file, because its stated reason is that the boundary recorders are one
implementation SHARED across every restore phase and called by restore
entrypoints at startup. Nothing calls this one but the operator, and leaving it
under `.internal/` would have added a third `bash .internal/…` invocation to the
runbooks — the precise thing the pending entrypoint review exists to remove.

Moving it changed the self-location line from `$SCRIPT_DIR/../..` to
`$SCRIPT_DIR/..`. That line has already broken twice in this repo, so it was
verified by running rather than by reading: `./bin/record-restore-state.sh
--phase 10B --point before --dry-run` completes, which proves the repo root
resolved and both sourced libraries were found.

It keeps `set -uo pipefail` rather than `set -euo pipefail`. The guide allows
that for a validator, and `bin/` already holds several on that footing —
`reimage-checklist.sh`, `verify-doc-paths.sh`, `verify-artifact-config.sh`.
Every target must produce a row; aborting on the first unreadable path would
discard the rest of the picture.

**Shared scaffolding, deferred.** Its option parsing, `absolute_path`, the
repo-checkout guard, and the `artifact_run_begin`/`finalize` bracket duplicate
the two boundary recorders. It does **not** duplicate `record`/`record_manual` —
there is no PASS/WARN/FAIL model here at all. So the extraction candidate is
narrower than `script-types-and-locations.md` anticipated when it said "extract
when a third recorder appears": a restore-helper *preamble*, not a recorder
library. Left for the entrypoint review, which will move code between `bin/` and
`.internal/` and would otherwise force a re-extraction.

**Verification.** `bash -n` and portability-lint clean; `shellcheck -x -S warning`
reports only the pre-existing SC2034 on
`ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT` that every sibling carries. Run
against a fixture `$HOME` built to exercise every branch: a mode-600 private key,
a 644 `known_hosts`, a nested file two levels down, a present-but-empty
directory, an empty subdirectory, a symlink, a mode-000 file, and an unset
`JAVA_HOME`. All four states observed — 16 present, 10 absent, 1 unresolved, 1
unreadable across 28 rows and 19 targets. The unreadable branch was reached by
running the whole capture as an unprivileged user, since root reads a mode-000
file happily and would have scored it `present`. `tree` recursion, `shallow`
depth-stopping, symlink targets, first-wins on a second `before`, a separate
`after` lineage, and exit 2 on each of three bad invocations all confirmed.

**Not verified on the target.** `/usr/bin/stat -f '%Lp'`, `'%z'`, and `'%m'` are
BSD format strings, exercised here with their GNU equivalents standing in.
`/usr/bin/stat -f '%Lp' ~/.ssh/config` on the Mac confirms the first; a `--dry-run`
confirms all three at once.

---

## Revision 34 — the findings batch

Nine files. Every item here was found by reading the code against the drive, and
each one is a case of a check reporting something other than what it measured.

**`artifact_run_finalize` could not fail.** A pointer write that did not happen
was reported on stderr and returned `0`, so `if ! artifact_run_finalize` — which
is how both recorders call it — could not see it. It returns `1` now and names
the repair command. The run is still indexed either way; what breaks is the
derived pointer, and saying so is the difference between a repair and a mystery.
It also refused nothing when handed an empty category root: the manifest path
became `/MANIFEST.md`, and the eventual failure named a location nobody
recognises. Both are the same shape as the `cd ""` and `dirname ""` cases the
recorders exist to catch.

**The manifest parser no longer depends on an awk dialect.** `/^\| [0-9]{4}-/`
became `/^\| [0-9][0-9][0-9][0-9]-/` in the two places that parse rows. Interval
expressions are a late addition to the one-true-awk macOS ships; the current
target has them, and a literal class costs nothing and removes the question. This
was verified against `original-awk`, the Debian build of that same lineage, not
assumed.

**Both recorders printed a `--help` naming the wrong directory.** They still
documented `prereq-checks/` and `exit-checks/` and a flat
`prereq-<phase>-<stamp>.md` filename, three revisions after the output moved into
`boundaries/runs/`. `--help` is the one document a reader trusts without checking
it, which is exactly why a stale one is worse than none.

**Both recorders hand-rolled the glob the run index exists to replace.**
`find … -path '*restore-runtime-diff*' | sort | tail -1` also matches
`.<id>.incomplete` staging directories, and it cannot express which lineage it
wants — the two problems `artifact-runs.sh` was extracted to remove, left in
place by the revision that built it. Both now call `artifact_run_official`, which
answers both and refuses a pointer whose run is not on disk.

*Not* fixed, and marked in the code as deliberately open: neither row checks that
the comparison POSTDATES the state it describes. A nine-pass sign-off has already
cited a comparison taken before a Node fix. A freshness rule needs a decision
about what "fresh" is measured against, so it stays a question rather than a
guess.

**`check_10A` produced no row at all when a sign-off pointer did not resolve.**
The loop skipped empty entries, so a missing `latest-enrollment-record.txt`
rendered as silence — "could not check" scored as nothing, in a checklist whose
whole purpose is recording that every question was asked. Each source now yields
a row in every case: resolved, dangling, or absent.

**The SSH row would have FAILed a correctly restored `~/.ssh`.** It tested every
file against mode 600, and `known_hosts` and `config` are conventionally 644 —
ssh does not care about either. The row said "keys" and the test said "every
file". It now identifies private keys by content and judges only those, accepting
400 alongside 600 because a read-only key is tighter rather than looser. The
zero-key branch stays: `~/.ssh` exists on a fresh macOS account, so neither its
presence nor a clean mode sweep proves Step 3 ran.

**The staged-loose row named a restore and tested a filename.** It PASSed when no
plaintext `staged-loose/MANIFEST.tsv` existed outside the image — but that
manifest lives ON the DMG, so its absence is the normal state whether Step 2 ran
or not. The DMG's own build manifest sits beside the image and is readable
without the password; filtering it to the `staged-loose/` rows yields the exact
destination list Step 2 owns, checkable after the image is detached. Presence is
necessary and not sufficient — a destination can exist because it was never swept
— so a Manual row now carries the half the automated one cannot answer.

**`rows.tsv` lost a field to a tab in the data.** The Phase 4B capture records
`ProductVersion:<TAB>26.6.1`, so carrying a recorded value straight into a
tab-delimited row split it across two fields and a consumer reading field 4 got
`ProductVersion:`. All three probes now squash whitespace before emitting.
`comparison.md` survived this because Markdown does not care; `rows.tsv`, added
specifically for machine consumption, did not.

**`mapfile` on a Bash 3.2 floor.** `.internal/git/stage-ignored-files.sh` used a
4.0 builtin, which aborts at 127 under `set -e`. It has never fired because
Phase 2A runs on a machine with Homebrew's bash 5.x first on `PATH` — but Phases
8 and 9 run `bin/` scripts before Phase 10A installs Homebrew, where
`#!/usr/bin/env bash` is stock `/bin/bash` 3.2.57. The floor is load-bearing, and
this is the only script that broke it.

**Executable bits.** `bin/init-shell-env.sh` and `bin/record-reimaged-system.sh`
had lost theirs to an earlier in-place rewrite while every sibling kept it; both
are invoked as `./bin/…` by a runbook, so both would have failed with permission
denied. Restored to 755. Every `bin/*.sh` is now executable.

**Documents.** `.github/copilot-instructions.md` §3 still said the recorders write
to `prereq-checks/` and `exit-checks/`; it now names `boundaries/` and says why
one category rather than two. `reimaging-scripts-guide.md` had a Phase 10A row
naming the deleted `bin/compare-runtime-versions.sh` and another naming
`prereq-checks/`; both rows are replaced by three that name what actually exists.
`restore-access.md` Step 0's one-line description of where the checklist lands is
corrected. The Artifact and Script Locations block in that runbook still
describes the old layout and is deliberately untouched — that is slice 4, along
with the same drift in `restore-runtime.md`, `verify-reimaged-system.md`, and
`references/master-directory-reference.md`.

**Verification.** All nine scripts `bash -n` clean and portability-lint clean.
`shellcheck -x -S warning` reports only pre-existing SC2034s on
`ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT` (used by the sourced loader) and
an unused `mnt` local. `artifact-runs.sh` was exercised end to end against
fixtures: an empty category root returns 2; a pointer directory that cannot be
created returns 1 with the run still indexed; two `before` runs in one lineage
leave the FIRST official, and `artifact_runs_rebuild` recomputes the same answer
after the pointers are deleted. The four changed check branches were run against
fixtures: `squash_ws` restores a four-field row from the real
`ProductVersion:<TAB>` value; the staged-loose loop counts 3 of 5 manifest lines
and finds 2 absent; the SSH loop finds 2 private keys among 5 files and flags
only the 644 one, leaving `known_hosts` and `config` alone; and every
sign-off-pointer case yields exactly two rows where the old loop yielded zero.

**Untested on the target.** `/usr/bin/stat -f '%Lp'` in the SSH row is BSD-only,
so it was exercised with the GNU `stat -c '%a'` equivalent standing in. Confirm
with `/usr/bin/stat -f '%Lp' ~/.ssh/config` on the Mac before trusting that row.

---

## Revision 33 — a portability check the toolkit could not previously run

**New file: `bin/verify-script-portability.sh`** (aggregate validator,
cross-cutting, mode 755). Two suppression sites added:
`.internal/apps/backup-intellij-state.sh` and `bin/reimage-checklist.sh`, one
line each.

**Why it exists.** Bash 3.2 compatibility is a feature-PRESENCE question, not a
runtime one. `declare -A` is rejected on 3.2 and works silently everywhere else,
so a clean run on any modern shell proves nothing — and every shell an AI session
can reach is Bash 5.x with GNU coreutils. Inspection is not a weaker substitute
for running it; it is the only method that answers the question at all. On its
first run it found `mapfile` in `.internal/git/stage-ignored-files.sh`, fixed in
Revision 34.

**Why the floor is real.** `record-restore-prereqs.sh` excludes
`Homebrew available` from its unanswered-row count on the grounds that Phase 10A
installs it — so Phases 8 and 9 run `bin/` scripts on a machine where
`#!/usr/bin/env bash` resolves to stock `/bin/bash`, 3.2.57. Measured on this
machine: `env bash` is Homebrew 5.3.15, `/bin/bash` is 3.2.57.

**Runbook command blocks are out of scope, deliberately.** A `bin/` script runs
under `#!/usr/bin/env bash`; a runbook block is pasted into the operator's
interactive zsh. Different targets, different incompatibilities, and one rule set
applied to both would be confidently wrong about half of them. The consequence
worth carrying into slice 0: moving an inline block into a `bin/` script moves it
from zsh to Bash 3.2, so a block that works when pasted may not survive the move.

**Comments are blanked before matching.** Without that, the check finds
`copilot-instructions.md`'s own rule — "avoid associative arrays, mapfile,
GNU-only options" — quoted in half the script headers, and reports the prose
forbidding a construct as a use of it. Blanked rather than deleted, so reported
line numbers still match the file you open.

**Suppression is a pragma, and it is not a silent escape hatch.**
`# portability-ok: RULE-ID — reason`, governing the line immediately below. A
reason is required, on the same argument `artifact_run_set_official` makes for
requiring one on a pin: an unexplained suppression cannot be reviewed three weeks
later. An unknown rule ID is reported, because a typo'd pragma suppresses nothing
while looking like it did. A pragma covering nothing is reported, because that is
how a suppression outlives the code it excused. Suppressed hits are counted in
the summary and listed under `--verbose` — they move from FAIL to accounted-for
rather than vanishing.

That last rule earned itself immediately: it caught both pragmas being placed one
line too high on first application, and a stray duplicate 25 lines from its
target.

**The two suppressed sites are genuine.** Both are guarded BSD-first fallbacks —
`/usr/bin/stat -f` is tried first and `stat -c` is the branch for a machine
without it. A line matcher cannot see the guard.

**It does not scan itself by default.** Its rule table holds, as data, every
pattern it searches for. Pass `--file bin/verify-script-portability.sh` to see
that.

**Verification.** `bash -n` and `shellcheck -x` clean apart from SC2317 on the
trap handler, which `verify-doc-paths.sh` carries identically. All five pragma
paths exercised against fixtures: well-formed suppresses and counts; missing
reason, unknown rule ID, and covering-nothing each report; comma-separated
multi-rule works. Exit 0/1/2, `--list-rules`, and `--verbose` confirmed. Across
all 65 scripts and templates: 64 clean, 2 suppressed, 0 warn, 0 fail.

**Not verified on the target.** The script scans clean under its own rules, but
that is inspection. `/bin/bash -n bin/verify-script-portability.sh` on the Mac is
the confirmation.

---

## Revision 32 — the comparison generalises and moves (slice 3a)

`bin/compare-runtime-versions.sh` → `.internal/restore/compare-restored-state.sh`.
**Delete the old file after copying the new one**; leaving both is the duplicated
path the implementation policy rules out.

**Why it moves out of `bin/`.** On its face this contradicts the graduation rule
— a runbook names it, so `bin/` looks right. But `script-types-and-locations.md`
carves out exactly this case for the prerequisite recorder: *one implementation
shared across every restore phase … graduation is for a helper that becomes a
phase command; this one stays a building block that several phases use.* The
moment the comparison serves `restore-access` and `restore-apps` as well as
`restore-runtime`, it is that same kind of thing.

**Why it renames.** The old name promised a runtime-version diff. The mechanism
is a keyed join and a classification, and neither is about versions: the same
code compares `~/.ssh` mode and entry count. Naming it for the general thing is
the reasoning that closed `phase2f-` → `secrets-dmg-rebuild-required-`.

**Two baselines, one mechanism.** `--against inventory` joins live probes to the
Phase 4B pre-image capture and answers *does the rebuilt machine match the one
that was erased*. `--against before` joins a phase's own before-state to its
after-state and answers *did this runbook install what it should have*. Same join
key, same classification; only the right-hand column's source differs.

**`--against before` refuses rather than pretending.** The recorder that writes a
before-state run does not exist yet, so the flag exits 2 and names what is
missing. Emitting a comparison with an empty right-hand column would report "no
change" because it had nothing to compare against — an empty expectation set
matching itself, which is the failure this toolkit keeps producing. `--phase 10B`
defaults to `before` and therefore refuses today; that is the honest state.

**Self-location depth changed with the directory.** `$SCRIPT_DIR/..` became
`$SCRIPT_DIR/../..`. This is the exact bug that left `record-restore-exit.sh`
broken while it sat in `bin/` carrying `../..` — the same error in the other
direction. Comment added at the line so a future move does not repeat it.

**The output moved into the run index**, from a flat
`restore-notes/runtime-version-comparison-*.md` to a `comparisons/` category with
`runs/`, `MANIFEST.md`, and `official/`. Each run now also drops `rows.tsv`
beside the rendered note, so a later comparison can join against it without
reparsing Markdown. `diff` was added to the known points in `artifact-runs.sh`
(latest-wins: a rerun after fixing a MISSING row is the newer truth).

**Both recorders' globs were repointed in the same revision.** They searched
`restore-notes/` for `runtime-version-comparison-*.md`; they now search
`comparisons/runs/` for a `*restore-runtime-diff*` run. Leaving that for later
would have made `Runtime comparison recorded` report a missing artifact the
moment the comparison was rerun under the new name.

**Consequence worth knowing:** the existing
`runtime-version-comparison-20260819-121523.md` is now invisible to that row. The
Phase 10A exit already recorded with it and that artifact stands; a *rerun* of
either recorder will report the comparison missing until it is run once under the
new tool, which takes seconds. The old file is left in place — it is evidence of
what was compared on the 19th, not clutter.

**Verification.** All four scripts `bash -n` clean, no Bash 3.2 hazards. Refusals
exercised: no `--phase`, unknown phase, `--against before`, and an invalid
`--against` value each exit 2 with a specific message. A full run against a
fixture inventory produced `5 missing / 0 differs / 1 same`, wrote
`comparison.md` and `rows.tsv` into a staged-then-promoted run, indexed one
manifest row, and resolved its `official/` pointer — after which
`record-restore-prereqs.sh --phase 10B` found it and recorded
`Runtime comparison recorded` as PASS, confirming the repointed glob works
against the artifact the new tool actually writes.

**Still to come.** `.internal/restore/record-restore-state.sh`, which unlocks
`--against before` and the within-phase diff. Then slice 2b
(`record-reimaged-system.sh`, `record-enrollment.sh`, and removing `restarts/`),
slice 3b (`reimage-checklist.sh --phase post`), and slice 4 (runbooks and the
three reference docs).

---

## Revision 31 — boundary recorders on the shared index, and a Phase 10B exit

Slice 2. Both recorders now write staged, indexed runs instead of flat
timestamped files, and `record-restore-exit.sh` learns `--phase 10B`.

**Phase 10B had no exit boundary at all.** `record-restore-exit.sh` supported
only `10A` and rejected everything else with exit 2, so `restore-access.md` ended
on a hand-checked prose table while every other recorded phase produced an
artifact. `check_10B()` implements Step 10's table: DMG detached, SSH material
present and mode 600, `jssecacerts` in the JDK `java_home` resolves, the
`~/.certs/corp-root.pem` bundle non-empty, and the three TLS stores Step 7
configures. Four of Step 10's rows are judgement calls — is this cert genuinely
an internal root, were the by-hand DMG categories walked — and are recorded as
Manual `TODO`s rather than approximated. An approximated PASS on those is worse
than no row.

**One row from that table is deliberately absent.** `git config --global
user.email` is in Step 10's exit criteria, but `restore-access.md`'s own
Ownership table assigns Git identity to `restore-git.md` (Phase 11A). Gating 10B
on it would make the phase depend on the next one.

**The TLS rows test public hosts on purpose.** Five of Step 7's six settings
*replace* a tool's CA bundle rather than adding to it — only
`NODE_EXTRA_CA_CERTS` appends — so pointing them at a corporate-root-only file
breaks public TLS. `npm ping`, `git ls-remote https://github.com/git/git`, and a
`urllib` fetch of pypi.org are the tests that catch it.

**A bug found by running it, in code written this session.** The SSH row first
read "no file under `~/.ssh` is mode 600 or looser" and PASSed on a machine where
Step 3 had never run — because `~/.ssh` exists on a fresh macOS account and an
empty directory satisfies a mode-only test trivially. That is the empty-
expectation-set failure this toolkit keeps producing, reintroduced in a new
check. The row now counts files before judging modes and distinguishes "exists
but empty — Step 3 did not run" from "files present but loose". Both branches
verified against fixtures.

**Both boundaries now share one category.** `prereq-checks/` and `exit-checks/`
become `boundaries/`, holding `runs/`, `MANIFEST.md`, and `official/`. Entry and
exit are the same question asked from either side of a phase, and putting them in
one index means a single file answers "did this phase both start and finish"
rather than requiring two directories to be read together. Nothing in `bin/`
consumed the old paths — only prose did — so the move costs no script change
outside these two files.

**Run context is `post-image-<runbook>-<point>`**, not the phase ordinal.
Ordinals renumber — twice in one day on this repo — and a directory name already
written to the drive cannot be renumbered afterwards. `restore-access` is stable;
`10B` is not. This is the same reasoning that closed `phase2f-` →
`secrets-dmg-rebuild-required-`.

**The footer that described the wrong phase.** `emit()` hardcoded "Both FAIL rows
here fail quietly" and named Phase 10A's Step 9 and Step 10 — text that stayed put
when `--phase 10B` was added, so a 10B checklist explained 10A's rows to the
reader. Counts and phase names are now interpolated from the run.

**Legacy artifacts are left alone.** The existing `prereq-checks/` files,
including today's `prereq-10B-20260820-015233.md`, stay exactly where they are.
No migration, no moving files on a drive being restored from. `artifact_runs_rebuild`
can index them later as `point=unknown` if that is ever wanted.

**Verification.** Both scripts `bash -n` clean, no Bash 3.2 hazards. Run end to
end against a fixture toolkit and artifact root: the entry recorder produced
5 pass / 2 warn / 1 fail with correct rows for a machine lacking a JDK and
direnv; the exit recorder produced its eight automated rows plus four Manual
TODOs; three runs across two lineages indexed into one `MANIFEST.md` with their
counts in the row; and both `official/` pointers resolved, the exit lineage
correctly advancing to the newer of its two runs under latest-wins.

**Still to come.** Slice 2b: `record-reimaged-system.sh` and
`record-enrollment.sh`, which is where the `restarts/` directory that nothing
writes to gets removed. Slice 3: `reimage-checklist.sh --phase post` and
`compare-runtime-versions.sh`. Slice 4: runbooks and the three reference docs —
including `restore-access.md`'s `restore-targets/` block and its three references
to a Step 11, which this revision makes real.

---

## Revision 30 — shared run index (`.internal/artifact-runs.sh`) — NEW FILE

Slice 1 of restructuring what post-image runbooks write under `reimaged-system/`.
This revision adds the foundation only; no existing producer calls it yet, so it
is inert on arrival and safe to apply mid-phase.

**What it replaces.** Producers currently disagree in five ways: three write
`runs/<context>-<stamp>/` with a `MANIFEST.md`, two write flat timestamped files
with no index, one writes bundles at the container root with no container at all;
pointers are relative in one place and absolute in another, and name a directory
in one and a file inside it in another. `record-restore-prereqs.sh:241-242`
already special-cases two of those conventions in four lines.

**Extracted, not invented.** `bin/report-loose-secrets.sh` lines 295-410 already
does this carefully — `.incomplete` staging with an atomic rename, a manifest
header sentinel, temp-then-`mv` pointer writes, a timestamp-collision refusal,
and one `finalize` called from every clean exit. This file is that implementation
generalised, so the debugged parts are unchanged and only the callers are new.

**One pointer per lineage, not one `latest-run.txt`.** A category holds several
independent lineages and a single "latest" pointer names whichever ran last.
That is already broken in two places: `resolve_latest_repo_audit_run` in
`reimage-checklist.sh` reads one pointer and accepts either `runs/pre-image-*` or
`runs/post-image-*`, so it cannot express which it wants; and
`verify-reimaged-system.md` Step 6 hand-rolls prefix-filtered selection because
the pointer could not answer its question. `official/<context>.txt` answers both.

**"Official", not "latest", because the rule differs by point.** For `before` and
`pre-restart` the meaningful run is the FIRST: a `before` captured after the
runbook has written is well-formed and wrong, and the diff it produces reads
"nothing changed". A pointer named `latest-` encodes recency as policy and would
silently overwrite it. Latest-wins applies to `after`, `entry`, `exit`,
`post-restart`, and `final`. An unrecognised point is recorded as `unknown` and
gets latest-wins rather than being guessed at — inferring `before` wrongly would
pin the wrong run under a rule that does not correct itself.

**Overrides are explicit, reasoned, and durable.** `artifact_run_set_official`
requires a reason, refuses a run belonging to another lineage, refuses one not on
disk or not indexed, and refuses an `.incomplete` directory. It writes
`PINNED-OFFICIAL.txt` into the run it promotes *before* appending the manifest
row and refreshing the pointer, so a crash at any point leaves a state the next
rebuild reconciles forward. The marker records a **pin**, not officialness —
officialness is always computed — so the marker and the manifest are not copies
of each other, and a run directory copied elsewhere carries its own pin.

**MANIFEST.md is authoritative; `official/` is a derived cache.** That makes a
stale pointer a repair command rather than a diagnosis, which retires the
two-paragraph troubleshooting section in `verify-reimaged-system.md:576`. Nothing
is ever edited in place: overrides and clears append rows, last pin winning.

**Placement.** `.internal/` root, beside the two config loaders, because its
callers span `restore/`, `home/`, and the artifact-root reporters and no single
domain owns it — and the guide's own rule says a lone helper does not earn a
domain directory. `.github/guides/script-types-and-locations.md` needs a line for
it: the loader row currently justifies itself with "there are two."

**Verification.** `bash -n` clean; no `mapfile`, `readarray`, or associative
arrays, and the file sets no shell options, so Bash 3.2 and the sourced-file
contract both hold. Exercised against fixtures: latest-wins advanced across three
runs; first-wins held the first across three and printed the override command
each time it declined; a pin held against a subsequent run and reverted correctly
on clear; all four refusal paths returned non-zero; a foreign `MANIFEST.md` was
refused rather than appended to; abort left nothing indexed; pointers rebuilt
from the manifest after deletion; and — the case the marker exists for — a pin
survived the manifest being destroyed and regenerated from `runs/` alone.
Two-token points (`pre-restart`, `post-restart`) parse correctly, which is the
pairing `verify-reimaged-system.md` Step 6 currently filters by hand.

**Not yet done.** Slice 2 converts `record-restore-prereqs.sh`,
`record-restore-exit.sh`, `record-reimaged-system.sh`, and
`record-enrollment.sh`, and removes the `restarts/` directory that
`record-reimaged-system.sh:286` creates and nothing writes to. Slice 3 updates
the consumers — `reimage-checklist.sh --phase post` and
`compare-runtime-versions.sh` — which must land with or after slice 2 because the
post branch globs the current shapes. Slice 4 is the runbooks and the three
reference docs. `emit()`'s phase-specific footer, which prints 10A's WARN
semantics under a 10B checklist, is fixed in slice 2 where that function is
already being rewritten.

---

## Revision 29 — Step 0 reported installed tools as missing (`record-restore-prereqs.sh`)

Found by running Phase 10B Step 0 on the live machine. Four edits, one of which
changes behaviour.

**The tooling row said `missing: node npm` on a machine with Node installed.**
`check_10B()` tested `gradle mvn node npm` in one loop and reported any absence
as a single WARN pointing at `restore-runtime.md` Steps 7-8. But nvm activates a
version by prepending to `PATH` from a shell function, so a shell that never
sourced `nvm.sh` — or one where no default alias is set — reports both tools
absent while `~/.nvm/versions/node` holds a perfectly good install. The row then
sends the reader back to reinstall what is already on disk. "Not on `PATH`" and
"not installed" are different findings and now read differently: the check
inspects the nvm install directory and, when a version is there, WARNs with the
version it found and the `nvm alias default` command that fixes it.

**The row also conflated two different consequences.** `gradle` and `mvn` appear
nowhere in `restore-access.md`, so a gap there blocks Phase 11B or 12. `node` and
`npm` are load-bearing in Step 7, which runs `npm config set cafile`, `npm ping`,
and `node -e` to establish corporate CA trust outside the keychain — a gap there
breaks part of *this* phase, and surfaces two phases later as
`SELF_SIGNED_CERT_IN_CHAIN`, looking like a network problem rather than a skipped
step. Split into `JVM build tools present` (WARN) and `Node tooling present`.

**Node genuinely absent is now FAIL, not WARN.** This changes the phase's exit
code. It matches the bar set for `reimage-checklist.sh --phase post` — a FAIL
means a phase did not finish — and signing off 10B with npm and node still not
trusting the corporate CA does mean it did not finish. The nvm-inactive case
stays WARN, since nothing is missing and the fix is one command.

**Two stale comments and one piece of dead code.** The section header claimed
`restore-runtime.md` Step 11 also runs `--phase 10B`; Revision 25 moved that call
to `restore-access.md` Step 0 and the comment was not updated. The comment above
check 5 described the staged-loose manifest while the check underneath tests the
DMG categories sidecar. And that check opened with
`[[ -f "…/all-secrets-"*"-categories.txt" ]]`, which can never match — `[[ ]]`
does no pathname expansion, so the glob was tested as a literal string and the
`|| ls` fallback did all the work. The dead test is removed and the reason
recorded so it is not reintroduced.

**Verification.** Every replacement asserted an exact occurrence count before
applying. `bash -n` clean; no `mapfile`, `readarray`, or associative arrays, so
Bash 3.2 holds. All four branches of the new Node row exercised against fixtures
in a minimal environment: nvm-installed-but-inactive → WARN naming the version
and the fix; genuinely absent → FAIL; on `PATH` → PASS with versions; `NVM_DIR`
unset falling back to `$HOME/.nvm` → WARN. The first of those is the case that
produced the wrong answer on the live machine.

**Related, not fixed here.** `record-restore-exit.sh`'s `check_10A()` already
splits these into `JVM build tools run` and `Node tooling runs` and makes both
FAIL, so the entry and exit halves of the same boundary have drifted on both
granularity and severity — and neither carries the nvm distinction. The pair is
documented in `script-types-and-locations.md` as sharing a contract on purpose,
with extraction deferred until a third recorder appears. A contract that has
already drifted between two implementations is arguably the same signal.

---

## Revision 28 — Phase 10B blocker batch (`restore-access.md`)

Six edits, found by reading the runbook end to end before following it. Four are
blockers — a command that would have failed silently, or an instruction ordered
after the action it is meant to precede. Two are stale claims in the intro that
Step 0 and Step 2 falsified when they were added.

**The intro claimed the runbook runs no scripts.** Line 7 said it "is manual and
does not run a fractogenesis-toolkit entrypoint," and the How the Workflow Works
section said it "is script-free by design" — both written before Step 0 (the
prerequisite recorder) and Step 2 (`bin/restore-staged-loose.sh`) existed, and
both contradicted by the Artifact and Script Locations block three screens
lower, which lists three scripts by path. Rescoped rather than deleted: the
*restores* are still manual by design, which is the real claim and still true;
boundary recording and the Phase 3B rehydration are not restores.

**Step 1 captured the mount point with the exact command substitution Step 0
exists to catch.** `MNT="$(hdiutil attach "$DMG" | awk …)"` swallows a non-zero
exit, so a wrong password, an already-attached image, or a corrupt DMG leaves
`MNT` empty — rendered by the following `echo "$MNT"` as a blank line that reads
like output. Every later step then runs against `/`: Step 3 copies from
`/ssh/*`, Step 5 reads `/certs/…`, Step 10 runs `hdiutil detach ""`. The runbook
warned at length about the *glob* hazard for `$MNT` and not at all about the
empty-string hazard from the substitution it had just used — a guard present in
one place and absent in its sibling. Now guarded, with the mount printed as a
labelled path so a blank value cannot pass for success.

**Step 1's re-derivation snippet failed into a plausible wrong answer.**
`MNT="$(dirname "$(ls -1d /Volumes/*/staged-loose | tail -1)")"` — with no
match, `ls` errors, the inner substitution is empty, and `dirname ""` returns
`.`, so `$MNT` becomes the current directory and every later `"$MNT"/ssh/*`
reads out of the toolkit checkout. Not empty, not an error: a value. Replaced
with a loop that tests for `MANIFEST.tsv` — the same test
`bin/restore-staged-loose.sh` already uses to find the same image — and reports
failure on stderr. Verified by running both forms: the old one returns `.`, the
new one reports the miss and resolves a fixture correctly.

**Steps 4, 5, and 7 hard-coded a certificate filename that this machine's DMG
probably does not contain.** All three read
`certs/keychain-manual-exports/root-ca.cer`. That directory receives a `.p12`
only when a Keychain identity was *exportable*, and the Phase 3A run recorded
four identities all refusing export with "The contents of this item cannot be
retrieved" — while the reviewed cert material went to
`certs/loose-candidates-selected/`. Followed as written the steps fail with "No
such file or directory," which reads as a missing file rather than a wrong
assumption. Step 4 now lists `certs/` first and pins one `CORP_CERT` variable
that Steps 5 and 7 reuse, so the path is resolved once from what is actually
there instead of asserted three times. `open -a "Keychain Access"` against a
*directory* was also wrong on its own terms — the app opens certificate files,
not folders — and is now plain `open`.

**Step 7's PEM conversion created an empty file on the wrong input.**
`openssl x509 -inform DER` against a file that is already PEM fails **and still
writes the output**, zero bytes — after which `NODE_EXTRA_CA_CERTS`,
`CURL_CA_BUNDLE`, `npm cafile`, `http.sslCAInfo`, and `REQUESTS_CA_BUNDLE` all
point at an empty CA bundle. Both input forms are now tried, and the existing
`grep -c 'BEGIN CERTIFICATE'` gained the expected value it never stated.

**Step 10 told you to check the by-hand categories after the commands that
destroy your ability to.** The detach block sat at the top of the step and the
sentence "Before you detach, check DMG Categories Restored By Hand" eight lines
below it. Read top to bottom, the image is gone before you reach the
instruction — and that table covers `gnupg/`, `cloud/`, `kube/`, `claude/`,
`claude-code/`, and `raycast/`, none of which has a restore step anywhere else
in the toolkit. The walk now opens the step, the detach follows it, and the
duplicated sentence is removed. The `grep -c all-secrets` verification also
gained a note that it prints `0` *and* exits 1 on no match, so the result is
judged by the printed number.

**Verification.** Every replacement asserted an exact occurrence count before
applying, so a pattern matching zero times aborts rather than silently doing
nothing. All 33 bash blocks syntax-checked afterwards; the one reported failure
is the pre-existing `openjdk@21` snippet nested inside an Obsidian `> [!note]`
callout, where the `>` are callout markers rather than shell. No stale `$CERT`
or `root-ca.cer` references remain. All eleven step headings intact.

**Known-stale, deliberately not touched in this batch.** `restore-access.md`
still references a **Step 11** that does not exist — three times, added when the
Artifact and Script Locations block was rewritten — and
`.internal/restore/record-restore-exit.sh` still rejects `--phase 10B`. The
generated-artifacts list also names `restore-targets/`, superseded in design
discussion by a `state/` category under the `runs/` + `MANIFEST.md` +
`official/` scheme. Both land with that work, not here.

---

## What changed, by theme

**Managed applications.** Phase 8 gained a step for installing from the Company
Portal Apps tab, covering the Required-vs-Available distinction that left Office
uninstalled. Step 3's list of components arriving automatically became a table
mapping each one to where it actually appears — `Falcon.app` rather than
"CrowdStrike", `Zscaler/Zscaler.app` nested a level down, Intune enrollment as a
package receipt rather than an app — because the previous flat list invited a
reverse-mapping the reader has no way to perform. Office was removed from that
list entirely: it is an Available assignment and never arrives on its own.

**Step 5's update-reboot shortcut was removed rather than reworded.** It told you
an OS-update reboot could count as the Step 7 stabilization restart if you ran
Step 6 first. Two problems: Step 7 is a four-item gate rather than just a reboot,
and one of its confirmations is "any required update-triggered restart is already
done or in motion" — circular when that restart *is* the one being gated. More
seriously, updates apply during the reboot, so a Step 6 record taken beforehand
is not the everything-applied snapshot it claims to be, and the Step 6/Step 8
comparison ends up spanning an OS version change as well as a reboot. The
Decisions table row offering the same shortcut as an open judgement call was
replaced, since leaving it would have contradicted the step.

**A verification command in Step 4 was silently reporting nothing.**
`sudo profiles list | grep -iB2 -A4 'microsoft|office|autoupdate'` has no `-E`,
so in a basic regex the `|` is a literal character and the pattern can never
match — output was empty on a Mac with Microsoft profiles installed, which reads
as "none found" rather than as a broken command. Now `grep -iEB2 -A4`. A scan of
every `grep` in the delivered set found no other instance: `-qxF` is
fixed-string, `'^| 20'` matches a literal table row, and `pgrep -f` takes an
extended regex by default.

Step 4 also gained a note on what a complete Office install looks like by
package receipt, since the app names and the identifiers do not correspond —
`com.microsoft.package.Microsoft_<App>.app` per app, plus AutoUpdate, licensing,
and shared components — and since Teams and OneDrive ship with the suite rather
than as separate assignments.

Step 3's table gained three rows for components with no application bundle at
all, found by reading a real `sudo profiles list` from an enrolled Mac: DLP,
endpoint-recovery, and SSO agents that exist only as system extensions and
payloads; SCEP certificate payloads, which are how the Keychain identities that
could not be exported before the erase come back; and FileVault enforcement with
escrow, which Phase 14 fails sign-off on. A note also directs the operator to
record the profile count, since a machine mid-push shows fewer and the total is
the cheapest way to tell "policy landed" from "policy is still landing".

**Three signals that were being checked by hand are now recorded.**
`record-enrollment.sh` gained `raw/09-keychain-identities.txt`, capturing
`security find-identity -v` in both the general and ssl-client scopes — the one
managed component with no restore path other than re-issuance, and therefore the
one whose count is the only evidence that re-issuance worked. FileVault and the
configuration profiles were already captured but had no exit-criteria row, so the
answer lived only in a raw file; both now have rows, and the profile count is
extracted into the table rather than left for the reader to find.

Counts are reported rather than judged wherever the right answer is site-specific:
how many identities this Mac should have is not something the script can know, so
it stamps `WARN` only on zero. `unknown` distinguishes "could not read" from
"none installed" — the profile total appears only at sufficient privilege.
Identity counts are parsed from each listing's trailing summary rather than by
counting numbered lines, since the file holds two listings and counting entries
would silently add them together; both singular and plural forms are handled.

**The managed-app comparison read the wrong source and the profile count read
the wrong scope.** Both were caught by running the recorder on a real enrolled
Mac rather than a fixture.

The comparison extracted every `<name>.app` token from the whole
`managed-inventory/` tree, which includes `03-installed-app-bundles.txt` — every
application the pre-image Mac had. At Phase 8 that reported the entire
un-restored application set: 104 absent, none of them findings. It now reads
`07-company-filter-pass.txt`, the company-scoped subset the capture already
produces, falling back to `04-installed-package-receipts.txt` and never to `03`.
Those files hold package receipt identifiers, so matching is exact against a new
`raw/10-package-receipts.txt` capture rather than fuzzy on app names. On the same
machine the count went 104 → 2, and both remaining entries are components of a
superseded management stack that re-enrolment will never restore.

`profiles list` unprivileged returns user-scope profiles only — 4, against 17 at
system scope — so the row reported a true answer to the wrong question. The
capture now tries `sudo -n` first, which never prompts and so keeps the script
non-interactive, records which scope it obtained, and reports it alongside the
number.

A gating bug surfaced while testing the new source chain: a `managed-inventory/`
tree present but holding no company-scoped file produced an empty expectation
set, which trivially matched and scored `PASS`. It is `TODO` now. That is the
same "could not check is not checked and fine" rule the row was written to
enforce, failing at a case one level further in.

Three further defects appeared on the next live run and are fixed:

- **Scope detection read the wrong part of its own file.** `record_pipeline`
  writes a `# Command: …` header quoting the entire pipeline, and that pipeline
  contains the literal words `scope: system` inside an `echo`. So the marker was
  present whether or not the branch that emits it ever ran, and a user-scope
  capture reported `4 (system scope)`. Detection now keys on `^_computerlevel`,
  which appears only in genuine system-scope output and cannot be echoed by the
  command line itself. General lesson for this script: never grep a raw capture
  for a string that also appears in the command that produced it.
- **The haystack was too narrow for the source.**
  `07-company-filter-pass.txt` is sectioned — receipts, application bundles,
  configuration profiles, background components, preference domains — and only
  the first two were being matched, so whole sections read as absent. It now
  spans captures 02, 04, 05, and 10.
- `raw/10-package-receipts.txt` was captured but never added to the report or
  manifest file lists.

**`sudo -v` was added to the Step 6 and Step 8 commands**, with the reason stated
rather than assumed. The script deliberately never prompts for a password — it
tries `sudo -n`, which succeeds only against an already-cached credential — so
the system-scope profile count is captured only when the operator has used sudo
recently. `sudo -v` refreshes that credential without running anything. It stays
optional: without it the run still succeeds and the row reports `user scope` and
says so. Step 8 carries a pitfall noting the credential does not survive the
restart, so omitting it there leaves the pre- and post-restart counts measuring
different things — the one comparison the record pair exists to support.

The profile row's note is now chosen by scope. It previously told the reader to
rerun with sudo even on a run that already had it, which is how notes get
skipped.

**The comparison was matching the wrong shapes.** Reading the actual absent list
from a live run showed it was almost entirely absolute paths to launchd plists —
`/Library/LaunchDaemons/com.zscaler.service.plist` and the like — which appear in
no capture the script was taking. Two fixes: a new
`raw/11-launchd-components.txt` capturing `/Library/LaunchAgents`,
`/Library/LaunchDaemons`, and the user equivalent as absolute paths; and a
basename retry before an entry is called absent, since the inventory records
`/Applications/Microsoft Word.app` while `ls /Applications` prints
`Microsoft Word.app`. Against the real absent list the count went 13 → 3, and all
three survivors are legitimate: components of a superseded management stack, and
a version-pinned installer receipt that cannot match once the vendor ships a
newer build. That third category is now named in the guidance, since "the
software is present but the receipt name moved" is not something a reader would
infer.

Reading the next run's absent list found two more vocabulary mismatches. The
inventory records at least one section as **command status lines** rather than
identifiers — `* * TEAMID com.vendor.agent (1.0/2.0) Agent Name [activated
enabled]` — and a whole line like that matches nothing, so an activated endpoint
agent reported as absent. The parser now reduces such lines to the reverse-DNS
identifier they contain, distinguishing them from absolute paths by the rule
"contains whitespace and does not begin with a slash", which keeps bundle names
with spaces intact. A twelfth capture, `raw/12-system-extensions.txt`, gives
those identifiers something to match against.

The lesson this row keeps teaching: an expectation set and the thing it is
compared against have to be in the same vocabulary, and the only way to find out
they are not is to read what the check actually reported. Four rounds of that
took the count from 104 to 7, and each round was invisible until someone looked
at the list rather than the number.

**The workspace fragments were the third thing that does not survive an erase.**
`$REIMAGE_WORKSPACE_ROOT/artifact-config/` and `staged-certs/` are gitignored,
edited per machine, and live outside the toolkit, so no install route carries
them and neither does a clone — the same situation as `reimage.env`, but they
were on no jump drive either. Phase 6A now copies them, Phase 8 Step 2 restores
them, and Phase 9 Step 1 gates on them.

A gate rather than a note because the failure is silent: with
`REIMAGE_WORKSPACE_ROOT` set and the directory absent, `artifact-config.sh`
prints one line to stderr and falls back to the committed templates. Nothing
fails, the evidence is written, and it is indistinguishable from a run against
the operator's real configuration. The gate distinguishes three states — present,
configured-but-missing, and deliberately unset, the last being legitimate.

**Four stale references were found by reading a generated checklist rather than
the script.** `verify-reimaged-system.md Step 8` became Step 7 when Time Machine
left Phase 9; `enroll-and-stabilize.md Step 2` became Step 4 in the Phase 8
restructure, and this instance escaped the earlier sweep because it omitted the
"Phase 8" prefix the sweep matched on; and two Recommended Next Actions still
told the operator to take a Time Machine backup in Phase 9 and warned that
OneDrive would collide with a Time Machine step that is no longer there. Templates
embedded in heredocs are not covered by a grep over runbook prose.

**The four Phase 11B/12 plan-note emitters had a clean 2x2 of missing guards**,
and every fix already existed in a sibling — each pair had documented in a
comment precisely the failure the other pair was exposed to.
`restore-docker.sh` and `restore-repos.sh` carried the path guards but not the
write check; `restore-apps.sh` and `restore-intellij.sh` the reverse. All four
now have: an artifact root that must be a mounted directory (without it,
`mkdir -p` silently builds the whole tree on the boot disk and the note lands
where Phase 14 never looks), a refusal to write under the repo checkout with
relative paths resolved first so the guard cannot be sidestepped, and a checked
redirect (without it a failed write still prints the success line, and Phase 14
reads the newest note — a phantom hand-off). Verified behaviourally: unmounted
root refuses and creates nothing, absolute and relative escapes into the
checkout both refused, happy path still writes.

Also in those scripts: two `Phase 2C` references corrected to `2D`, and
`restore-apps.sh`'s `resolve_vscode_source()` removed — a function whose two
comments contradicted each other, guarding a fallback that did not exist.

**`bin/compare-runtime-versions.sh` replaces Phase 10A Step 9's manual pass.**
The step listed fourteen version commands to run and eyeball against a
sixteen-file inventory, described as "a paper trail step, not an automated
diff". Eyeballing finds the tool whose version changed; it reliably misses the
tool that is simply absent, because nothing prints when nothing is installed.
The script probes fifteen tools, reports `MISSING` / `differs` / `same` against
the newest pre-image bundle, and treats an approved-newer version as normal
rather than as drift.

Comparison is on the extracted version number rather than the raw string.
`npm --version` prints `10.9.7` while the inventory recorded `npm 10.9.7`, and
`sw_vers -productVersion` prints `15.6` against a recorded
`ProductVersion: 15.6` — comparing raw text made every such pair read `differs`,
which teaches the reader to ignore the only column that matters. Both raw
strings are still displayed. Summary counts are derived from the same function
that renders the rows, so the summary cannot disagree with the table beneath
it.

**Obsidian moved from Phase 12 to Phase 10A Step 5.** Every runbook from Phase
10 onward is Markdown written for Obsidian — callouts, wiki-links, collapsible
sections — and read in `less` a `> [!warning] Pitfall` is a line of punctuation
while `[[restore-git|restore-git.md]]` is not a link. Phase 12 already argued
Obsidian should come early "so the vault, this runbook included, is available
while the rest of the phase runs"; the argument is stronger two phases sooner.
The split that makes it work: installing Obsidian and opening the *toolkit*
needs only Homebrew, while opening `reference-vault` needs SSH and a clone and
so stays in Phase 12, which now points back rather than repeating the install.
Two pitfalls travel with it — Obsidian writes a gitignored `.obsidian/` into
whatever it opens, and the vault will be aimed at a directory Phase 11B deletes.

That insert renumbered Steps 5–10 to 6–11 and produced two slips worth
recording, both caught by diffing against the original rather than by reading
the result: a plural `Steps 1–8` that a `\bStep N\b` pattern cannot see, and a
cross-file `restore-access.md Step 6` wrongly bumped to Step 7 because the
sentinel guarding cross-file references only matched the `[[restore-access#Step`
wiki-link form, not the plain-prose form. Step 6 is *Restore Java Trust
Overrides*, which is what that sentence is about; Step 7 is a different step.
**A renumber has to protect prose references, not just link syntax.**

**Three helpers moved, and two were broken by the move.**
`scan-archive-contents.sh` and `scan-postman-collections.py` went to
`.internal/home/`, `generate-performance-rollup-summary.py` to
`.internal/performance/`. Both scanners resolved `REPO_ROOT` one level up, which
was right at the `.internal/` root and wrong one directory deeper: `REPO_ROOT`
became `.internal/`, the loader was sought at `.internal/.internal/`, and each
script exited 2 before doing any work. Both now resolve two levels up — the same
correction `record-restore-prereqs.sh` needed when it moved. Call sites updated
in `backup-home.md` (2), `backup-apps.md` (1), and
`capture-performance-audit.md` (3).

The scanners' apparent circular reference turned out to be neither a cycle nor
shared logic: they co-own `loose-secrets-reports/content-scans/MANIFEST.md`, and
each creates its header if absent — one in Bash, one in Python. Two
implementations of one file format, which drift silently. A shared recorder is
still worth extracting; both now sit in the same directory, so it has an
unambiguous home.

`script-types-and-locations.md` gained `home/` and `restore/` to its domain list,
and a note that a domain is named for the material a helper works on rather than
always for the runbook that calls it — which is why both scanners live in `home/`
though `backup-apps.md` invokes one of them.

**Step 0 — Record Prerequisites** is now a documented convention across the
template, the runbook prompt, `copilot-instructions.md`, and
`script-types-and-locations.md`. Prerequisites declares in prose and carries no
commands; Step 0 verifies and writes the artifact. It is numbered 0 because it
gates the phase rather than advancing it, is rerunnable at any point unlike the
sequential steps, and adding one to an existing runbook renumbers nothing — which
matters given two renumbers in this session each produced slips. Include it only
where a precondition can fail *silently*; omit it rather than adding an empty one.

`runbook-fill-prompt.md` was renamed **`runbook-prompt.md`** and its migration
residue removed: the `rename_suggestion` input, its changelog instruction, and its
line in the example JSON. That JSON also carried a stale `Phase 2C — Backup Apps`
back-link, corrected to 2D.

**Four corrections found by running Phase 10A on a live machine.**

`compare-runtime-versions.sh` probed for the CF CLI in `14-cloud.txt`, which
records OneDrive and iCloud *paths* rather than cloud CLI versions — a mapping
that could never match. Retargeted; the row now reads honestly rather than
reporting a phantom absence.

Step 3's Homebrew shell bootstrap used `brew shellenv`; Homebrew 6.x prints
`brew shellenv zsh`. Both work, but following the installer's message *and* the
runbook leaves two lines doing one job. The runbook now defers to whatever the
installer prints.

Step 4's `brew bundle list` omits casks, taps, and `mas`/`npm`/`vscode` entries
unless given `--all` — so a review that looks complete hides exactly the entries
worth questioning: on this machine a VPN client, a packet analyser, and a window
manager from an untrusted tap. Now `--all`, and `check --verbose` so an unmet
dependency says *which*.

`init-shell-env.sh` now documents that `--remove` clears only its own marked
block. That is correct behaviour — it cannot know whether unmarked lines are
still wanted — but a profile that accumulated bare `export FRACTOGENESIS_HOME`
lines before this script existed still carries them afterwards, which surprised
the operator on a live run.

**Step 7's install order was wrong, and the formatting hid it.** Five `brew
install` lines sat in one block — git, openjdk@21, gradle, maven, groovy —
followed by the keg-only symlink and its verification in a second block. Run as
written, `gradle`, `maven`, and `groovy` each pull `openjdk` (the versionless,
current formula) as a dependency, so a second JDK lands before the 21 you
installed has been linked or verified. The result is two JDKs, no
`java_home` entry for either, and a `java -version` answer that cannot be
accounted for — which is exactly the state the step's own troubleshooting entry
then sends the reader to debug.

Now one command per block, in dependency order: git, then openjdk@21, then the
symlink, then `java_home -v 21` as a gate, and only then the three build tools
individually. A Pitfall states plainly why the build tools wait. Single-command
blocks are also the requested house style — run one thing, read its output,
proceed — and here that style is what makes the ordering visible.

**Step 8 asked the reader to check a project that does not exist yet.** It said
to read `package.json` and `.nvmrc` for a required Node version — but Phase 11B
clones the repositories, so at Phase 10A there is no project anywhere to read.
Now: take the baseline from the pre-image `11-node.txt` capture, install it or
the current LTS, and set it as the default so a shell outside any project still
has a working `node`. Per-project versions are deferred to where they can
actually be answered, with a note that `nvm use` reads `.nvmrc` with no argument
once the repos exist. Same class as Step 7 — a step written as though the machine
were further along than the phase order allows.

**Step 9 gained the two failures a live run produced.** `command not found: cf`
after an apparently successful install traces to a tap being added without its
formula — which the captured `Brewfile` reproduces exactly, listing
`tap "cloudfoundry/tap"` with no matching `cf-cli` entry. And a freshly reimaged
Mac has no Gatekeeper history, so the unsigned `fly` cask is blocked on first
launch with a malware warning that reads like a compromised download rather than
a missing approval. Both documented, with the quarantine flag cleared
deliberately after confirming provenance rather than reflexively, and a note that
Gatekeeper policy may be MDM-controlled on a managed Mac. Step 9's installs and
verifications are now one command per block.

**`command not found: cf` turned out to be three stacked causes**, which is why
it survived two apparent fixes on a live run. The tap was present without its
formula; current Homebrew then refused the formula as coming from an untrusted
third-party tap; and `cf-cli@7`, being a versioned formula, installs keg-only and
unlinked. Each fix revealed the next, and `brew install` on an already-present
keg reports *"already installed, it's just not linked"* and stops — which reads
as success. Documented in order, with the point that `brew trust` records trust
and nothing else: it does not retry the command that triggered the error.

A related note landed with it: an unlinked keg is omitted from `brew list
--formula`, so a failed bulk install can appear to have installed nothing while
having installed several things unlinked. That is exactly what happened here —
the earlier `brew bundle` run was read as leaving no trace, and `cf-cli@7` 7.8.0
was on disk the whole time.

**The version comparison asked a question the capture cannot answer.** Run
against the real inventory it produced six `no baseline` rows and two garbage
extractions — `--- Docker version ---` and a bare `direnv` are a section header
and a package name, not versions. The cause was a wrong assumption rather than
wrong anchors: `06-homebrew.txt` is a package *list*, bare names with no
versions, so for most formulae there is no version to compare and never was.

Probes are now three kinds. `probe_version` where the capture genuinely records
one — macOS, Homebrew, Java, Gradle, Groovy, Node, npm, Python. `probe_presence`
where it records only a name, comparing installed-then against installed-now,
which is the only honest question that list supports. And `probe_later` for a
tool a subsequent phase installs: Docker Desktop belongs to Phase 12, so its
absence at Phase 10A is the sequence working, and reporting it as MISSING was
the same error as Git and Homebrew reading TODO in the Phase 9 checklist.

Two anchors were also simply pointed at the wrong file — Groovy's version lives
in `10-java.txt`, not the Homebrew list. Verified against a fixture built to
match the real capture's format rather than an assumed one, which is what the
first version should have been.

**Phase 10A had no close-out artifact, and nothing said where one should live.**
Phases 8, 9, and 14 each produce a sign-off record; Phases 10A and 10B produced
none, because they have no entrypoint to generate one — so Step 11 asked the
reader to confirm ten things by eye with nothing written down. A question asked
three days later had no answer.

`.internal/restore/record-restore-exit.sh` is the mirror of the prerequisite
recorder: one answers "may this phase start", the other "did it finish". Nine
automated rows plus two `TODO` rows for judgements a script cannot make —
whether each version difference is acceptable, and whether a missing platform CLI
matters on this machine. Recording that those were *asked* is the point.

Chosen over appending the checklist to `runtime-version-comparison-*.md`, which
would have been fewer files: entry and exit are different questions, a file named
for a version comparison that also carries a phase sign-off understates its
contents, and renaming it would break the glob Phase 10B's entry check uses to
confirm the comparison ran.

The option parsing, path guards, and row recording duplicate the prerequisite
recorder closely. That is deliberate and now documented in
`script-types-and-locations.md`: extracting a shared library for a pair invites
indirection before the pattern is proven, so extract when a third recorder
appears. The rule itself is in `copilot-instructions.md` — one check per
boundary, a phase never runs the next phase's entry check and never re-checks its
own entry at the end.

**Two competing patterns were introduced and one was wrong.** Revision 25 put a
Step 0 at the start of Phase 10A recording its own prerequisites, and then had
Phase 10A Step 11 record Phase 10B's — two conventions in one runbook, and the
second a duplicate of the check Phase 10B would run itself. Corrected to a single
rule, which also matches the house pattern already set by Phase 8 Step 9 and
Phase 9 Step 7:

> **Step 0 verifies entry. The final step closes out exit. One prerequisite check
> per phase, at its start.**

So Phase 10A Step 11 is `Close Out the Exit Criteria` again — a human close-out
of what 10A produced — and `--phase 10B` moved to a new `Step 0` in
`restore-access.md`, where it belongs. The `--phase 10B` implementation is
unchanged; only its call site moved.

**Step 11's formatting was the original complaint and still is fixed.** It listed ten areas with
expected results in a single column, which made it hard to tell where a command
ended and its expected output began, and left every row to manual judgement.
Phase 10A's exit criteria and Phase 10B's entry criteria are the same question
asked from either side, so it is implemented once as
`record-restore-prereqs.sh --phase 10B` and both runbooks call it.

Three rows are `FAIL` because Phase 10B cannot proceed without them: `java_home`
resolving, the toolkit root, and the secrets DMG. The Java row exists because it
is the only one that fails invisibly — `restore-access.md` Step 6 wraps
`java_home` in command substitution, which swallows a non-zero exit and leaves
`JAVA_HOME` empty, sending `jssecacerts` to a path that is not the JDK. Four rows
are `WARN`: a gap there blocks a later phase, not this one.

A note also records that an empty `JAVA_HOME` at the end of Phase 10A is expected
and correct — nothing in 10A sets it, and 10B Step 6 does — because seeing it
empty right after the Step 7 pitfall reads like the failure that pitfall warns
about.

Remaining spot-checks are one command per block with the expected result in prose
beneath, replacing a table that ran command and result together.

**Step 0 landed in `restore-runtime.md` itself**, which the earlier revision
documented as a convention and then failed to apply — the prerequisite call was
left sitting under Prerequisites, the exact placement the convention exists to
forbid. It is now `### Step 0 — Record Prerequisites` opening Sequential Steps,
with Prerequisites keeping its four bullets and a line saying it declares while
Step 0 verifies. Steps 1–11 are untouched, which is the point of numbering it 0.

**Step 4's Brewfile guidance told the reader to review and then handed them a
command that installs.** It read "do it only after reviewing" followed by
`brew bundle --file`, which is the install form; no review command appeared
anywhere. Followed as written on a live rebuild, it began installing a
forty-package Brewfile. Now `brew bundle list` and `brew bundle check`, with a
Pitfall saying outright that the bare form installs, and guidance to treat the
Brewfile as a checklist *after* Steps 7–9 rather than a shortcut past them. Two
notes record what that run taught: a deprecated tap reporting empty and an
untrusted third-party cask being refused are both correct outcomes, and a failed
`brew bundle` can still leave taps behind even when it installs nothing.

**Phase 10A's prerequisites became checkable, then became a recorded artifact.**
Of the four the runbook stated in prose, only internet access had a
corresponding PASS row anywhere earlier in the workflow; the other three were
assertions, and all three fail quietly — an unset `FRACTOGENESIS_HOME` makes
`cd ""` a no-op returning 0, an unmounted artifact root makes Step 10 compare
against an inventory that is not there, and a sign-off with unanswered rows is
indistinguishable from a completed one.

The inline command block grew past the size the repo's authoring rules allow, so
it became `.internal/restore/record-restore-prereqs.sh`. It is an internal
helper rather than a `bin/` command because the restore entrypoints from Phase
11B onward can call it at startup; Phase 10A has no entrypoint, so its runbook
invokes it directly, which the rules permit for a helper given explicit
arguments. Named `record-`, not `check-`: it writes a dated artifact under
`reimaged-system/prereq-checks/` and the verdict summarises it, matching
`record-enrollment.sh` and `record-reimaged-system.sh`. Self-location resolves
two levels up, since a helper at `.internal/restore/` has the repo root as its
grandparent.

**Two false positives drove the counting logic, both found by running it.**
A naive `grep -c TODO` matches instruction prose — "Update the `TODO` rows
above" — and reports a completed sign-off as incomplete. Counting is now
restricted to `TODO` appearing as a table *cell*, handling both the bare
`| TODO |` of the enrollment record and the backticked form of the first-boot
checklist. Separately, `Git available` and `Homebrew available` are recorded by
Phase 9 and installed by Phase 10A, so a `TODO` there is the correct state and
not an unanswered question; they are excluded by label.

The root cause was fixed too: `record-reimaged-system.sh` now reports those two
rows as `INFO` rather than `TODO`, relabelled *(installed in Phase 10A)*, since
a `TODO` no step in the phase can clear teaches the reader to ignore `TODO`.
Presence still reports `PASS` — Xcode Command Line Tools supplies `git`, so it
can legitimately appear before Phase 10A runs, as it did on this machine.

**All post-image artifacts live under `reimaged-system/`**, and both references
now say so rather than leaving it implied. The pre-image phases each add a
top-level directory to the artifact root because each is an independent capture
with its own lifecycle; the restore half is one continuous rebuild whose
evidence is a single chronological record, so it writes only into subfolders
here. `prereq-checks/` joins `restore-notes/`, `restarts/`, and `time-machine/`.
The master reference also gained the four enrollment raw captures it was missing
(`09`–`12`).

**Phase 10A Step 3's Homebrew install was hardened after hitting the failure
live.** It used `/bin/bash -c "$(curl -fsSL …)"`, and with `-f -s` a 404 or a
captive-portal redirect yields empty output, `bash` runs nothing, and the
command exits **0** — no Homebrew, no error, and the next step fails for an
unrelated-looking reason. This is the same trap `restore-strategy-guide.md`
already documents for `bootstrap.sh`, and it is easy to reach by mistyping the
URL: the installer lives in `Homebrew/install`, not `Homebrew/brew`. Now a
two-step `curl -fL -o` plus `test -s`, with a note on `NONINTERACTIVE=1` and
`sudo -v` for unattended starts. `record-enrollment.sh` gained an eighth raw capture comparing the
installed app set against the pre-image `managed-inventory/` capture, stamped
`TODO` rather than `PASS` when that source is unreachable.

**`--context` labels.** Both recorders accept `--context LABEL`, producing
`pre-restart-record-enrollment-YYYYMMDD-HHMMSS`. The label leads, matching
`post-image-performance-audit-*` and `pre-image-*`. Readers gained leading
wildcards; `reimage-checklist.sh` gained `newest_stamped_dir`, which ranks on the
trailing stamp rather than the whole name.

**Bundle-internal filenames** no longer repeat their directory's prefix:
`enrollment-record.md` → `record.md`, `initial-checklist.md` → `checklist.md`,
`time-machine-reimaged-system-plan.md` → `time-machine-plan.md`.

**Phase 16 — Post-Image Time Machine.** One backup, after Restore Home, replacing
one in Phase 9 that captured a machine holding nothing irreplaceable and one at
the end of Phase 14 that missed the home directory. `run-time-machine.md` owns
both passes, the way `capture-*.md` serve Phases 4 and 13.

**Toolkit environment.** Phase 8 owns its own first two steps — install the
toolkit, restore the shell environment — instead of leaving them in the guide as
block quotes. `bin/init-shell-env.sh` bridges Phase 8 → 10A, where direnv takes
over and the bridge is removed. `references/toolkit-environment-reference.md`
documents the whole arrangement across the three install routes.

**Wording.** `$FRACTOGENESIS_HOME` is the *toolkit root* everywhere, never the
"repository root" (it has no `.git` between the erase and Phase 11B) and never
confused with `$REIMAGE_ARTIFACT_ROOT`.

**Toolkit location is chosen by the operator.** Phase 8 Step 1 exports
`FRACTOGENESIS_HOME` before running `bootstrap.sh`, which honours it as the
install destination. Every command downstream refers to the variable rather than
a hardcoded `$HOME/fractogenesis-toolkit`, so putting the toolkit elsewhere means
editing one line. Three places could not use the variable and were restructured
instead rather than left as literal paths:

- Phase 10A Step 5 removes the bridge and `exec`s a new shell, at which point no
  mechanism is setting the variable — so it `cd`s into the toolkit first and
  relies on `exec` inheriting the working directory.
- Phase 11B Step 4 and the reference's *Moving Between Instances* capture
  `TOOLKIT_BOOTSTRAP="$FRACTOGENESIS_HOME"` before repointing, since afterwards
  the variable names the clone and that is the only handle left on the copy being
  removed.

Literal paths that remain are deliberate: prose describing `bootstrap.sh`'s
default, `reimage-guide-access.md`'s assertions that nothing landed in the
default location (expressing those as the variable would make the check
vacuous), and `init-shell-env.sh`'s error hint, printed precisely when the
resolved root is wrong.

---

## Verification at time of delivery

- All Obsidian anchors resolve in all 18 markdown files; no duplicate headings
  introduced; code fences balanced.
- All 4 shell scripts pass `bash -n`.
- Functional fixtures: the managed-app comparison in four cases; `--context`
  validation accept/reject; glob and sort behaviour across mixed name shapes;
  `init-shell-env.sh` write / idempotent rerun / real sourcing / allexport
  safety / `--remove`; the Phase 9 Step 6 and Phase 8 Step 9 selection snippets;
  the full Phase 8 install-and-wire flow against a deliberately non-default
  toolkit path (`$HOME/my-toolkit`), confirming the install, the `~/.zprofile`
  block, and a fresh login shell all resolve to it.

## Known follow-ups, not applied

- `reimaging-scripts-guide.md` has a pre-existing duplicate heading,
  `#### ./bin/backup-home.sh --onedrive-only`.
- `prepare-artifact-root.md` repeats one paragraph about `dotenv reimage.env` in
  each direnv branch — arguably deliberate, since the branches stand alone.
- `reimage-guide-access.md` has duplicate `Option A`–`Option D` headings across
  its two route sections. Nothing links to them.
