[[reimaging-guide#Phase 6A — Guide Access on a Freshly Reimaged Mac|← Back to Mac Reimaging Guide]]

# Guide Access on a Freshly Reimaged Mac

**Last updated:** 2026-08-17

Prove, before the Mac is erased, that `fractogenesis-toolkit` can actually be fetched onto a Mac with no Git, no SSH keys, and no prior checkout — once over the network with `curl` and `bootstrap.sh`, once from the jump drive with no network at all.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Confirm What a Bare Mac Actually Has|Step 1 — Confirm What a Bare Mac Actually Has]]
    - [[#Step 2 — Validate Bootstrapped fractogenesis-toolkit (curl)|Step 2 — Validate Bootstrapped fractogenesis-toolkit (curl)]]
    - [[#Step 3 — Validate Jump Drive fractogenesis-toolkit|Step 3 — Validate Jump Drive fractogenesis-toolkit]]
    - [[#Step 4 — Clean Up|Step 4 — Clean Up]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#When to Rerun This|When to Rerun This]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

This validates the two ways `fractogenesis-toolkit` gets onto a Mac with no Git, no SSH keys, and no prior checkout — the exact situation Phase 8 onward depends on. It runs while the original system is still available and easy to fix problems on, so a broken escape hatch is found before the erase rather than after it. Nothing here is a backup: the only output is proof that one of the two fetch paths works.

**What it sets up**

- **A proven curl path** — `bootstrap.sh` fetched over the network and extracted into a throwaway location, with the `bin/` scripts arriving executable.
- **A proven jump drive path** — a freshly built payload tarball plus `bootstrap.sh` on the drive itself, installed without referencing your real checkout.
- **A recorded `python3` finding** — evidence of whether a bare Mac can run the toolkit's Python entrypoints without triggering the Command Line Developer Tools prompt.

**What the rest of the workflow relies on it for**

- Phase 6B's final pre-erase gate proceeds on the assumption that the recovery path is real rather than theoretical.
- Phase 8 onward fetches the toolkit onto the reimaged Mac by whichever of these two paths this phase proved.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| validating the curl / `bootstrap.sh` fetch path on a bare Mac | the final pre-erase readiness gate — `reimage-prep-checks` (Phase 6B) |
| validating the jump drive fallback, including building the payload used for the test | the reasoning for why this repo must be independently fetchable — `restore-strategy-guide` (reference) |
| the throwaway test locations and their cleanup | the real fetch onto the reimaged Mac — `reimaging-guide` (Phase 8) |

This validation is safe to rerun at any time: both tests extract into a throwaway location and delete it when they finish, so no real checkout and no artifact root is touched.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The goal is proof, not preparation: by the time the Mac is erased you should have watched the toolkit arrive twice, by two independent routes, on a machine that has nothing. Every command below uses only what stock macOS already has, deliberately — the whole point is proving this works *before* trusting it during a real reimage.

The two routes are tested in that order because the first is the one you would reach for. `bootstrap.sh` over `curl` needs a working network and a reachable GitHub; the jump drive needs neither, and exists for the reimage that leaves you without either. Both tests extract into a throwaway location, never a real dev checkout, and each ends by deleting what it created.

> [!note]
> Paths may print as `/tmp/...` in one place and `/private/tmp/...` in another. That is not a bug or a duplicate copy — on macOS, `/tmp` is a symlink to `/private/tmp` (confirm with `ls -ld /tmp`), so both spellings point at the exact same file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Scripts exercised, alphabetical:

```text
$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh   # entrypoint — builds the jump drive payload tarball
$FRACTOGENESIS_HOME/bin/prepare-artifact-root.py      # entrypoint — run with --help only, as an execution smoke test
$FRACTOGENESIS_HOME/bootstrap.sh                      # entrypoint — fetches and extracts the toolkit, from curl or from the jump drive
```

This runbook writes nothing under `$REIMAGE_ARTIFACT_ROOT`. Its only outputs are throwaway, and the last step deletes them:

```text
/tmp/fractogenesis-toolkit-access-test/curl-kit           # curl test destination (FRACTOGENESIS_HOME override)
/tmp/fractogenesis-toolkit-access-test/jump-drive-kit     # jump drive test destination (FRACTOGENESIS_HOME override)
$JUMP_DRIVE_VOLUME/bootstrap.sh                           # installer copied onto the drive itself
$JUMP_DRIVE_VOLUME/tarball/fractogenesis-toolkit.tar.gz   # payload built for the test
```

### Environment Variables

The values this runbook sets or reads. `JUMP_DRIVE_VOLUME` and `TOOLKIT_GITHUB_ACCOUNT` are `reimage.env` keys resolved and written during `prepare-artifact-root.md`; the other two are set by hand for the duration of a test.

| Variable | Meaning |
|---|---|
| `TOOLKIT_GITHUB_ACCOUNT` | GitHub account the toolkit is fetched from. This runbook runs pre-image, so `reimage.env` is loaded and the variable is available — unlike the Phase 8 cold start, which has no `reimage.env` and takes the account from the emailed cheatsheet instead. |
| `FRACTOGENESIS_HOME` | Where the toolkit is checked out. Both tests deliberately override it to a throwaway path so nothing lands in your real checkout. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |
| `FRACTOGENESIS_PARENT` | Set for the jump drive test only: the directory holding your real `fractogenesis-toolkit` checkout, from which a fresh payload is built. Not a `reimage.env` key. |
| `JUMP_DRIVE_VOLUME` | Mount path of the small dedicated jump drive used as the no-network bootstrap fallback, for example `/Volumes/REIMAGEKIT`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- Your shell is at the repository root — `cd "$FRACTOGENESIS_HOME"` once for the session. Per the guide's [[reimaging-guide#Core Assumptions|Core Assumptions]], the commands below assume this and don't repeat it.
- The original system is still intact — this phase runs before the erase, while problems are still easy to fix.
- For the jump drive test: the jump drive is mounted, and your real checkout is committed and pushed if you want the tarball to reflect your latest state.

### Confirm Your Intent

- Which path you are validating this run: the curl / `bootstrap.sh` fetch, the jump drive fallback, or both. Before trusting either mechanism for a real reimage, prove both.
- Whether `$JUMP_DRIVE_VOLUME` points at the actual physical jump drive or at a local-tarball stand-in. The commands are identical either way; only the mount path differs.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order: confirm the bare-Mac toolchain is really there, validate the curl path, validate the jump drive path, then clear anything either test left behind.

### Step 1 — Confirm What a Bare Mac Actually Has

Run each of these before either test below. They confirm the tools this whole mechanism depends on are actually present and working — not assumed.

**Confirm `bash` is available (it always is — macOS's default shell binary):**

```bash
bash --version
```

**Confirm `curl` is available (it always is — part of the base OS):**

```bash
curl --version
```

**Confirm `python3` is available — watch closely here:**

```bash
python3 --version
```

This one is worth testing deliberately, not assuming. On several past macOS versions, running `python3` for the very first time — before Xcode Command Line Tools are installed — triggers the *same* "requires the Command Line Developer Tools" popup and download that `git` does. If `python3 --version` prints a version cleanly with no popup, you're clear.

> [!bug] Troubleshooting
> If the popup appears, it's a real finding: `prepare-artifact-root.py` (and every other Python script in `bin/`) would be blocked by the exact popup this whole toolkit was designed to avoid. Note it, decline/cancel it, and flag it in the reimage's own migration log.

### Step 2 — Validate Bootstrapped fractogenesis-toolkit (curl)

**1. Create a throwaway toolkit directory:**

```bash
mkdir -p /tmp/fractogenesis-toolkit-access-test
```

**2. `cd` to the throwaway toolkit directory just created:**

```bash
cd /tmp/fractogenesis-toolkit-access-test
```

**3. Explicitly override `FRACTOGENESIS_HOME` on its own line first** — this is the authoritative safeguard, since it works regardless of which directory you're actually in:

```bash
export FRACTOGENESIS_HOME=/tmp/fractogenesis-toolkit-access-test/curl-kit
: "${FRACTOGENESIS_HOME:?export failed — do not continue}"
echo "FRACTOGENESIS_HOME=[$FRACTOGENESIS_HOME]"
```

The echo is not padding. This variable is load-bearing for every step that follows,
and every way it can be wrong is silent: `bootstrap.sh` falls back to
`$HOME/fractogenesis-toolkit` when it is empty, and `cd "$FRACTOGENESIS_HOME"` in
step 8 becomes `cd ""` — a no-op that returns **0**, leaving you in the parent
directory with no `bin/` and an error that reads like a missing file. Confirm the
brackets contain the throwaway path before going on.

Note: a `VAR=val` prefix directly on the curl command (`FRACTOGENESIS_HOME=... curl ... | bash`) does **not** work here — that only sets the variable for `curl`, not for `bash` on the other side of the pipe, which is where `bootstrap.sh` actually runs. It has to be `export`ed on its own line beforehand.

**4. Then fetch and run `bootstrap.sh` — as two steps, not a pipe:**

```bash
: "${TOOLKIT_GITHUB_ACCOUNT:?not set — source reimage.env, or export it from the post-reimage cheatsheet}" &&
curl -fL -o /tmp/bootstrap.sh \
  "https://raw.githubusercontent.com/$TOOLKIT_GITHUB_ACCOUNT/fractogenesis-toolkit/main/bootstrap.sh" &&
bash /tmp/bootstrap.sh
```

> [!warning] Pitfall
> The guard on the first line is not decoration. With `TOOLKIT_GITHUB_ACCOUNT` unset the URL collapses to `raw.githubusercontent.com//fractogenesis-toolkit/…`; GitHub redirects the double slash and the redirect target 404s. What you see is `curl: (56) The requested URL returned error: 404` and `bash: /tmp/bootstrap.sh: No such file or directory` — which reads as "the file is missing from the repo" and sends you to check the wrong thing. The tell is **two** transfer lines in curl's progress output instead of one: a 76-byte redirect body, then the failure. The guard turns that into one unambiguous line naming the variable.

> [!warning] Pitfall
> Do not use `curl -fsSL … | bash`. With `-f -s`, a 404 — or a captive portal returning its own page — prints nothing, `bash` reads an empty stdin, and the pipeline exits **0**. The test then "passes" while installing nothing, and the failure only surfaces at the pass criteria in step 6, with no indication of the cause. Fetching to a file first turns a failed download into a visible `curl: (22)`.
>
> If the fetch 404s, the repository is private and the `curl` route needs a token — which defeats its purpose on a bare Mac. That is a finding worth having now: it makes the jump drive and the artifact root's `toolkit-snapshot/` the only credential-free routes.

**5. Confirm it landed in the throwaway location, not your real checkout:**

```bash
ls "$FRACTOGENESIS_HOME"
```

**6. Pass criteria — every row must print `PASS`:**

```bash
fail=0
chk() { if [ "$1" -eq 0 ]; then printf 'PASS  %s\n' "$2"; else printf 'FAIL  %s\n' "$2"; fail=1; fi; }

[ -n "$FRACTOGENESIS_HOME" ];                                    chk $? 'FRACTOGENESIS_HOME is set'
[ -d "$FRACTOGENESIS_HOME" ];                                    chk $? 'destination directory exists'
[ -f "$FRACTOGENESIS_HOME/bootstrap.sh" ];                       chk $? 'bootstrap.sh present'
[ -x "$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh" ];    chk $? 'bin/ scripts arrived executable'
[ ! -e "$HOME/fractogenesis-toolkit" ];                          chk $? 'no stray install in $HOME (the override took effect)'

[ "$fail" -eq 0 ] && echo "ALL PASS" || echo "NOT PROVEN — do not trust this route yet"
```

Every row prints `PASS` or `FAIL`. The previous `test … && echo "OK"` form printed
**nothing** when a check failed, so an unset `FRACTOGENESIS_HOME` — which fails all
of them at once — looked identical to not having run the block.

The last row is the one that catches a failed override. `bootstrap.sh` falls back to
`$HOME/fractogenesis-toolkit` when `FRACTOGENESIS_HOME` is empty, so the install
*succeeds* while landing somewhere this test never looks — and on a pre-erase machine
that is exactly where Phase 8 will later put the real checkout.

If anything prints `FAIL`, stop and diagnose before trusting this path during an actual reimage.

**7. Open the markdown files, using only what's available on a bare Mac** (no Obsidian, no VS Code — pick any one of these):

```bash
# Option A -- TextEdit (GUI, always present)
open -a TextEdit "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option B -- Quick Look (GUI, no app launch -- select the file in Finder, then press Space)
open -R "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option C -- Terminal, paginated (quit with q)
less "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option D -- Terminal, dumps the file
cat "$FRACTOGENESIS_HOME/prepare-artifact-root.md" | head -50
```

Any one of these confirms the file is legible plain text. None of them render Obsidian's `[[#Heading]]`-style links specially — that's expected, and not a requirement for the docs to be usable on a bare Mac. If Obsidian happens to be installed already (not guaranteed on a bare Mac), opening the throwaway folder as a vault gives the fuller experience, but that's a convenience, not a dependency.

**8. Test run the scripts, to confirm they actually execute — not just that the files exist.** `cd` into the installed copy first: step 2 left the shell in the *parent* of the install directory, so a bare `bin/…` path would resolve to nothing and report a false failure.

```bash
cd "$FRACTOGENESIS_HOME"
```

```bash
python3 bin/prepare-artifact-root.py --help
```

Expect the full subcommand list to print (`init-reimage-env`, `create-artifact-root`, `confirm-env`, and the rest) with no traceback.

```bash
bash bin/build-jump-drive-payload.sh
```

`build-jump-drive-payload.sh` requires two arguments — running it with none deliberately triggers its usage message, which is itself proof the script executes correctly:

```text
build-jump-drive-payload.sh: line N: 1: Usage: build-jump-drive-payload.sh /path/to/reimage-toolkit /path/to/output-dir
```

A usage error here is a **pass** — bash parsed and ran the script far enough to hit the argument check. A `command not found`, `Permission denied`, or Python traceback would be a real **fail** worth stopping on.

**9. Delete the throwaway copy once you're done testing:**

```bash
rm -rf /tmp/fractogenesis-toolkit-access-test
```

**10. Unset the override.** Note: `unset` takes a variable *name*, never a `$`-prefixed value — `unset $FRACTOGENESIS_HOME` tries to unset a variable named after whatever path was stored, which actually errors outright (`bad variable name`) rather than silently doing nothing:

```bash
unset FRACTOGENESIS_HOME
```

### Step 3 — Validate Jump Drive fractogenesis-toolkit

**1. Set the parent directory to where the cloned `fractogenesis-toolkit` lives** on your normal dev machine, and return to the repository root. The `cd` matters: Step 2 deleted the directory the shell was sitting in, and step 4 below invokes `bin/build-jump-drive-payload.sh` by relative path.

```bash
export FRACTOGENESIS_PARENT="/path/to/wherever/you/actually/cloned/it"
cd "$FRACTOGENESIS_PARENT/fractogenesis-toolkit"
```

**2. Set the jump drive's mount path** — adjust the volume name if yours differs:

```bash
export JUMP_DRIVE_VOLUME="/Volumes/REIMAGEKIT"
```

**3. Create a tarball directory on the jump drive:**

```bash
mkdir -p "$JUMP_DRIVE_VOLUME/tarball"
```

**4. Build a fresh payload from that real checkout.** The payload should reflect your actual current repo state. Pass the real path, not `.` — the tarball's name is derived from `basename` of this argument, so `.` would produce a tarball literally named `..tar.gz`:

```bash
bin/build-jump-drive-payload.sh "$FRACTOGENESIS_PARENT/fractogenesis-toolkit" "$JUMP_DRIVE_VOLUME/tarball"
```

If the output includes a line like `WARNING: working tree has uncommitted changes`, the tarball only reflects your last *commit*, not uncommitted edits — push first and rebuild if you want the actual latest state tested.

**5. Copy `bootstrap.sh` onto the jump drive itself, if it isn't already there.** This matters: the whole point of this test is simulating no access to your real checkout, so `bootstrap.sh` needs to live on the drive itself, not be referenced from your Mac's normal filesystem:

```bash
cp "$FRACTOGENESIS_PARENT/fractogenesis-toolkit/bootstrap.sh" "$JUMP_DRIVE_VOLUME/bootstrap.sh"
```

> [!warning] Pitfall
> While the drive is mounted, put `reimage.env` and the post-reimage cheatsheet on it too. Neither is in the tarball — `reimage.env` and `*.local.md` are gitignored, and `git archive` ships only committed files:
>
> ```bash
> cp "$FRACTOGENESIS_PARENT/fractogenesis-toolkit/reimage.env" "$JUMP_DRIVE_VOLUME/reimage.env"
> cp "$FRACTOGENESIS_PARENT/fractogenesis-toolkit/post-reimage-cheatsheet.local.md" "$JUMP_DRIVE_VOLUME/"
> ```
>
> A bootstrapped checkout with no `reimage.env` resolves `$REIMAGE_ARTIFACT_ROOT` to nothing, and regenerating it with `bin/setup-reimage-env.sh` after the erase defaults `REIMAGE_START_DATE` to *that* day — silently pointing the whole workflow at an artifact root that does not exist. Restoring the original file is the only correct move.

**6. Create a throwaway install directory for the toolkit:**

```bash
mkdir -p /tmp/fractogenesis-toolkit-access-test
```

**7. Set `FRACTOGENESIS_HOME` to a throwaway location:**

```bash
export FRACTOGENESIS_HOME="/tmp/fractogenesis-toolkit-access-test/jump-drive-kit"
: "${FRACTOGENESIS_HOME:?export failed — do not continue}"
echo "FRACTOGENESIS_HOME=[$FRACTOGENESIS_HOME]"
```

**8. Install from the jump drive, referencing both files from the drive itself** — not your real checkout, simulating the true no-network scenario:

```bash
bash "$JUMP_DRIVE_VOLUME/bootstrap.sh" "$JUMP_DRIVE_VOLUME/tarball/fractogenesis-toolkit.tar.gz"
```

**9. Confirm it landed in the throwaway location, not your real checkout:**

```bash
ls "$FRACTOGENESIS_HOME"
```

**10. Pass criteria — every row must print `PASS`:**

```bash
fail=0
chk() { if [ "$1" -eq 0 ]; then printf 'PASS  %s\n' "$2"; else printf 'FAIL  %s\n' "$2"; fail=1; fi; }

[ -n "$FRACTOGENESIS_HOME" ];                                    chk $? 'FRACTOGENESIS_HOME is set'
[ -d "$FRACTOGENESIS_HOME" ];                                    chk $? 'destination directory exists'
[ -f "$FRACTOGENESIS_HOME/bootstrap.sh" ];                       chk $? 'bootstrap.sh present'
[ -x "$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh" ];    chk $? 'bin/ scripts arrived executable'
[ ! -e "$HOME/fractogenesis-toolkit" ];                          chk $? 'no stray install in $HOME (the override took effect)'

[ "$fail" -eq 0 ] && echo "ALL PASS" || echo "NOT PROVEN — do not trust this route yet"
```

Every row prints `PASS` or `FAIL`. The previous `test … && echo "OK"` form printed
**nothing** when a check failed, so an unset `FRACTOGENESIS_HOME` — which fails all
of them at once — looked identical to not having run the block.

The last row is the one that catches a failed override. `bootstrap.sh` falls back to
`$HOME/fractogenesis-toolkit` when `FRACTOGENESIS_HOME` is empty, so the install
*succeeds* while landing somewhere this test never looks — and on a pre-erase machine
that is exactly where Phase 8 will later put the real checkout.

If anything prints `FAIL`, stop and diagnose before trusting this path during an actual reimage.

**11. Open the markdown files, using only what's available on a bare Mac:**

```bash
# Option A -- TextEdit (GUI, always present)
open -a TextEdit "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option B -- Quick Look (GUI, no app launch -- select the file in Finder, then press Space)
open -R "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option C -- Terminal, paginated (quit with q)
less "$FRACTOGENESIS_HOME/reimaging-guide.md"
```

```bash
# Option D -- Terminal, dumps the file
cat "$FRACTOGENESIS_HOME/prepare-artifact-root.md" | head -50
```

**12. Test run the scripts, to confirm they actually execute.** As in Step 2, `cd` into the installed copy first — the shell is still wherever step 4 left it, which is not the jump-drive install:

```bash
cd "$FRACTOGENESIS_HOME"
```

```bash
python3 bin/prepare-artifact-root.py --help
```

```bash
bash bin/build-jump-drive-payload.sh
```

Same pass/fail read as the curl test — a usage error is a pass; a traceback or `command not found` is a fail.

**13. Delete the throwaway copy once you're done testing:**

```bash
rm -rf /tmp/fractogenesis-toolkit-access-test
```

**14. Unset all three overrides:**

```bash
unset FRACTOGENESIS_HOME
unset JUMP_DRIVE_VOLUME
unset FRACTOGENESIS_PARENT
```

> [!note]
> If this is the actual physical jump drive rather than a local-tarball test, the same commands work as written — just make sure `$JUMP_DRIVE_VOLUME` points at the drive's real mount path.

### Step 4 — Clean Up

If either test was interrupted partway and left stray directories behind, this clears everything both tests could have created:

```bash
rm -rf /tmp/fractogenesis-toolkit-access-test

# If FRACTOGENESIS_HOME was ever empty during a run, bootstrap.sh installed here
# instead. Remove it: on a pre-erase machine this is a stray .git-less copy sitting
# exactly where Phase 8 will later bootstrap the real one.
[ -e "$HOME/fractogenesis-toolkit" ] && \
  echo "Removing stray fallback install: $HOME/fractogenesis-toolkit" && \
  rm -rf "$HOME/fractogenesis-toolkit"

unset FRACTOGENESIS_HOME JUMP_DRIVE_VOLUME FRACTOGENESIS_PARENT
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### When to Rerun This

- Before trusting either mechanism for a real reimage, the first time.
- Any time `bootstrap.sh` is edited.
- Any time a new phase is migrated into this repo (the file list changes — worth reconfirming the pass criteria still hold).
- Any time the jump drive's tarball is rebuilt.

For the reasoning behind why this repo needs to be independently fetchable at all — no Git, no SSH — see the Guide Access Solutions section of `references/restore-strategy-guide.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section ends with a single "Back to Table of Contents" link.
-->
