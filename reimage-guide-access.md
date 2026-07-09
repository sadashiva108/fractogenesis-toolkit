# Guide Access on a Freshly Reimaged Mac

> [[reimaging-guide|← Back to Mac Reimaging Guide]]

## Table of Contents

- [[#Purpose|Purpose]]
- [[#Prerequisite Check — What a Bare Mac Actually Has|Prerequisite Check — What a Bare Mac Actually Has]]
- [[#Validate Bootstrapped fractogenesis-toolkit (curl)|Validate Bootstrapped fractogenesis-toolkit (curl)]]
- [[#Validate Jump Drive fractogenesis-toolkit|Validate Jump Drive fractogenesis-toolkit]]
- [[#Clean Up|Clean Up]]
- [[#When to Rerun This|When to Rerun This]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## Purpose

This validates the two ways `fractogenesis-toolkit` gets onto a Mac with no Git, no SSH keys, and no prior checkout — the exact situation Phase 6 onward depends on. Every command below uses only what stock macOS already has, deliberately — the whole point is proving this works *before* trusting it during a real reimage.

Both tests extract into a throwaway location, never a real dev checkout.

One thing you'll likely see while running these: paths may print as `/tmp/...` in one place and `/private/tmp/...` in another. That's not a bug or a duplicate copy — on macOS, `/tmp` is a symlink to `/private/tmp` (confirm with `ls -ld /tmp`), so both spellings point at the exact same file.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Prerequisite Check — What a Bare Mac Actually Has

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

⚠️ **Worth testing deliberately, not assuming.** On several past macOS versions, running `python3` for the very first time — before Xcode Command Line Tools are installed — triggers the *same* "requires the Command Line Developer Tools" popup and download that `git` does. If that happens, it's a real finding: `prepare-artifact-root.py` (and every other Python script in `bin/`) would be blocked by the exact popup this whole toolkit was designed to avoid. If the popup appears, note it, decline/cancel it, and flag it in the reimage's own migration log. If `python3 --version` prints a version cleanly with no popup, you're clear.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Validate Bootstrapped fractogenesis-toolkit (curl)

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
```

Note: a `VAR=val` prefix directly on the curl command (`FRACTOGENESIS_HOME=... curl ... | bash`) does **not** work here — that only sets the variable for `curl`, not for `bash` on the other side of the pipe, which is where `bootstrap.sh` actually runs. It has to be `export`ed on its own line beforehand.

**4. Then run the curl command normally:**

```bash
curl -fsSL https://raw.githubusercontent.com/<your-github-account>/fractogenesis-toolkit/main/bootstrap.sh | bash
```

**5. Confirm it landed in the throwaway location, not your real checkout:**

```bash
ls "$FRACTOGENESIS_HOME"
```

**6. Pass criteria — all three should be true:**

```bash
test -d "$FRACTOGENESIS_HOME" && echo "OK: destination directory exists"
test -f "$FRACTOGENESIS_HOME/bootstrap.sh" && echo "OK: bootstrap.sh present"
test -x "$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh" && echo "OK: bin/ scripts came through executable"
```

If any of these fail, stop and diagnose before trusting this path during an actual reimage.

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

**8. Test run the scripts, to confirm they actually execute — not just that the files exist:**

```bash
cd "$FRACTOGENESIS_HOME"
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

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Validate Jump Drive fractogenesis-toolkit

**1. Set the jump drive's mount path** — adjust the volume name if yours differs:

```bash
export JUMP_DRIVE_VOLUME="/Volumes/REIMAGEKIT"
```

**2. Create a tarball directory on the jump drive:**

```bash
mkdir -p "$JUMP_DRIVE_VOLUME/tarball"
```

**3. Set the parent directory to where the cloned `fractogenesis-toolkit` lives** on your normal dev machine:

```bash
export FRACTOGENESIS_PARENT="/path/to/wherever/you/actually/cloned/it"
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

**6. Create a throwaway install directory for the toolkit:**

```bash
mkdir -p /tmp/fractogenesis-toolkit-access-test
```

**7. Set `FRACTOGENESIS_HOME` to a throwaway location:**

```bash
export FRACTOGENESIS_HOME="/tmp/fractogenesis-toolkit-access-test/jump-drive-kit"
```

**8. Install from the jump drive, referencing both files from the drive itself** — not your real checkout, simulating the true no-network scenario:

```bash
bash "$JUMP_DRIVE_VOLUME/bootstrap.sh" "$JUMP_DRIVE_VOLUME/tarball/fractogenesis-toolkit.tar.gz"
```

**9. Confirm it landed in the throwaway location, not your real checkout:**

```bash
ls "$FRACTOGENESIS_HOME"
```

**10. Pass criteria — all three should be true:**

```bash
test -d "$FRACTOGENESIS_HOME" && echo "OK: destination directory exists"
test -f "$FRACTOGENESIS_HOME/bootstrap.sh" && echo "OK: bootstrap.sh present"
test -x "$FRACTOGENESIS_HOME/bin/build-jump-drive-payload.sh" && echo "OK: bin/ scripts came through executable"
```

If any of these fail, stop and diagnose before trusting this path during an actual reimage.

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

**12. Test run the scripts, to confirm they actually execute:**

```bash
cd "$FRACTOGENESIS_HOME"
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

If this is the actual physical jump drive rather than a local-tarball test, the same commands work as written — just make sure `$JUMP_DRIVE_VOLUME` points at the drive's real mount path.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Clean Up

If either test was interrupted partway and left stray directories behind, this clears everything both tests could have created:

```bash
rm -rf /tmp/fractogenesis-toolkit-access-test
unset FRACTOGENESIS_HOME JUMP_DRIVE_VOLUME FRACTOGENESIS_PARENT
```

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## When to Rerun This

- Before trusting either mechanism for a real reimage, the first time.
- Any time `bootstrap.sh` is edited.
- Any time a new phase is migrated into this repo (the file list changes — worth reconfirming the pass criteria still hold).
- Any time the jump drive's tarball is rebuilt (step 4 of the jump drive test above).

For the reasoning behind why this repo needs to be independently fetchable at all — no Git, no SSH — see the Guide Access Solutions section of `references/restore-strategy-guide.md`.

[[#Table of Contents|⬆ Back to Table of Contents]]
