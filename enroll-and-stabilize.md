[[reimaging-guide#Phase 8 — Enroll and Stabilize|← Back to Mac Reimaging Guide]]

# Enroll and Stabilize

**Last updated:** 2026-08-18

Bring the freshly reimaged Mac to a clean, trusted managed baseline before any restore work begins. This phase covers the human-driven work — completing MDM enrollment, installing and confirming the managed app set from both Intune assignment modes, applying required macOS updates, taking the first stabilization restart, and reconfirming afterward — and pairs it with `record-enrollment.sh`, which records read-only command evidence for each managed subsystem and prefills the Phase 8 exit-criteria table for the command-verifiable rows.

---

## Table of Contents

- [[#Purpose|Purpose]]
- [[#How the Workflow Works|How the Workflow Works]]
    - [[#What Gets Recorded|What Gets Recorded]]
    - [[#Command-Verifiable vs Mixed vs Manual Rows|Command-Verifiable vs Mixed vs Manual Rows]]
    - [[#Run Order and When to Fill Rows|Run Order and When to Fill Rows]]
    - [[#Terminology|Terminology]]
- [[#Artifact and Script Locations|Artifact and Script Locations]]
    - [[#Record Bundle Layout|Record Bundle Layout]]
    - [[#Environment Variables|Environment Variables]]
- [[#Before You Run Anything|Before You Run Anything]]
    - [[#Prerequisites|Prerequisites]]
    - [[#Confirm Your Intent|Confirm Your Intent]]
- [[#Sequential Steps|Sequential Steps]]
    - [[#Step 1 — Reach Your Cheatsheet and Password Manager|Step 1 — Reach Your Cheatsheet and Password Manager]]
    - [[#Step 2 — Install the Toolkit onto the Rebuilt Mac|Step 2 — Install the Toolkit onto the Rebuilt Mac]]
    - [[#Step 3 — Establish the Shell Environment|Step 3 — Establish the Shell Environment]]
    - [[#Step 4 — Complete Managed Enrollment|Step 4 — Complete Managed Enrollment]]
    - [[#Step 5 — Install and Confirm Required and Available Managed Apps|Step 5 — Install and Confirm Required and Available Managed Apps]]
    - [[#Step 6 — Apply Required macOS Updates|Step 6 — Apply Required macOS Updates]]
    - [[#Step 7 — Record the Pre-Restart Baseline|Step 7 — Record the Pre-Restart Baseline]]
    - [[#Step 8 — Take the First Stabilization Restart|Step 8 — Take the First Stabilization Restart]]
    - [[#Step 9 — Record the Post-Restart Baseline|Step 9 — Record the Post-Restart Baseline]]
    - [[#Step 10 — Close Out the Exit Criteria|Step 10 — Close Out the Exit Criteria]]
- [[#Decisions|Decisions]]
- [[#Troubleshooting|Troubleshooting]]
- [[#Supplemental Reference|Supplemental Reference]]
    - [[#Per-Section Command Reference|Per-Section Command Reference]]
    - [[#Output Location Fallback Chain|Output Location Fallback Chain]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

> [!info] Callout legend
> This runbook uses Obsidian callouts so each type reads distinctly: `[!note]` an easily-missed fact · `[!warning]` Pitfall, a mistake you are likely to make here · `[!bug]` Troubleshooting, what to do when a step misbehaves.

---

## Purpose

Establish a clean, managed, and stable macOS baseline before restoring runtime tools, access material, repositories, apps, or local files, and leave behind a timestamped record of the evidence that supports each Phase 8 exit-criteria row. The record is diagnostic evidence, not a backup you restore from — nothing here re-applies to the machine.

**What it sets up**

- **The managed baseline** — the enrolled, profile-controlled, security-tooled
  state IT expects, with the full managed app set present from both assignment
  modes (Required push and Available catalog), required macOS updates applied,
  and the whole thing confirmed to survive the first stabilization restart.
- **Indexed evidence runs** — one run per `record-enrollment.sh` capture under `reimaged-system/restarts/`, holding the twelve raw evidence files, `record.md`, and `rows.tsv`.
- **An entry and an exit checklist** — under `reimaged-system/boundaries/`, recording what was decided about that evidence rather than what it says.
- **The closed-out Phase 8 exit-criteria table** — prefilled with heuristic verdicts on the command-verifiable rows and finished by hand for the manual-judgment rows.

**What the rest of the workflow relies on it for**

- Phase 9 reconnects the artifact root and runs its first post-image sanity
  checks against a baseline that is already enrolled, stable, and **fully
  installed**. Phase 9 compares two evidence bundles taken around a restart;
  managed apps installed after its first bundle appear as spurious diff rows
  and mask real regressions, so every managed install belongs here.
- Phases 10A and 10B assume enrollment, profiles, and security tooling are in place before any runtime or access material is restored.
- The post-restart record is the evidence cited when the Phase 8 exit criteria are signed off.

**Ownership**

| This runbook owns | Owned elsewhere |
|---|---|
| Phase 8 managed-baseline enrollment, stabilization, and evidence recording | runtime tooling restore (Xcode CLT, Homebrew, Java, Node) — `restore-runtime` (Phase 10A) |
| the `record-enrollment.sh` run and its timestamped bundle | the encrypted secrets DMG and any restore of secrets — `restore-access` (Phase 10B) |
| the Phase 8 exit-criteria table and its sign-off | the first post-enrollment usability sanity check — `verify-reimaged-system` (Phase 9) |
| the managed application set — both the Required push and the Available-catalog installs | company-managed inventory comparison across pre-image and post-image — `capture-managed-inventory` (Phases 2C / 13C) |
| the decision that an unlisted app is an IT request rather than a local fix | OneDrive sign-in and initial sync, deferred past Phase 9's restart and Time Machine steps |
| | non-managed application restore — `restore-apps` (Phase 12) |

This runbook can be rerun. Each run writes a fresh timestamped bundle and leaves earlier runs untouched, so an early pre-restart record and a later post-restart record can coexist and be compared.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## How the Workflow Works

Read this before running anything. The phase is mixed by design: some rows in the exit-criteria table are things a shell command can prove, some are things a shell command can only hint at, and some can only be confirmed by looking at the UI or by watching a restart happen. `record-enrollment.sh` runs one read-only command per managed subsystem, writes each result to a numbered raw file, applies a small set of heuristic PASS/WARN verdicts on the rows it can meaningfully judge, and leaves the truly human-judgment rows as `TODO`. You close those out after the UI review and the first stabilization restart.

The preferred path is script-first: run the script once before the restart to capture the pre-restart baseline, take the restart, then run it again afterward to capture the post-restart baseline. The same commands are also listed individually under Supplemental Reference for the rare case where you need to rerun or troubleshoot a single subsystem — use the script for the standard run, the individual commands only when isolating one section.

### What Gets Recorded

One numbered file per managed subsystem, plus a Markdown record with the exit-criteria table prefilled and a small manifest:

```text
01  MDM enrollment status              profiles status -type enrollment
02  configuration profiles list        profiles list
03  FileVault status                   fdesetup status
04  managed applications present       /Applications, including one level of nesting
05  managed processes present          ps aux name-filter for expected managed agents
06  macOS version and build            sw_vers
07  available software updates         softwareupdate --list
08  managed app expectations           diff of 04 against pre-image managed-inventory/
09  keychain identities                security find-identity -v, general and ssl-client
10  installed package receipts         pkgutil --pkgs
11  launchd managed components         /Library/Launch{Agents,Daemons} plists
12  system extensions                  systemextensionsctl list
```

Every command reads state; nothing writes to managed state. You can run this on a live managed machine without risk to compliance.

File `08` is different from the others: it is not a command capture but a
comparison. It reads the pre-image `managed-inventory/` capture on the artifact
root, extracts the application bundles this Mac had before the erase, and names
the ones absent now. That is the only source that knows what *this* Mac is
supposed to have — a fixed list of vendor names in the script would be a guess.
When the artifact volume is not yet mounted the comparison has no source, and
the row is stamped `TODO` rather than `PASS`, because "could not check" and
"checked and fine" must not look the same.

### Command-Verifiable vs Mixed vs Manual Rows

The Phase 8 exit-criteria table groups checks by how they can be proven. The script only prefills rows in the first two groups:

| Row group | What the script does | What you do |
|---|---|---|
| Command-verifiable / Mixed | Records the raw command output and stamps `PASS`/`WARN` based on a small heuristic. | Review the raw file, decide whether `WARN` is expected on this Mac, and finalize the row. |
| Manual-only | Nothing. The row is left as `TODO`. | Watch the UI, watch the restart, and fill the row in by hand. |

`WARN` is not the same as `FAIL`: it means the recorded evidence did not obviously match the expected pattern and needs a human look before the row is signed off (for example, `softwareupdate --list` still shows offered updates, or `profiles list` was empty at the moment of the run because policy was still landing).

### Run Order and When to Fill Rows

Two mistakes are easy to make here and both are avoidable by reading this first.

**Do the work before the record, not after.** Every `record-enrollment.sh` run is
a snapshot of the moment it runs. Enrollment, the managed app installs, and the
macOS updates all happen in Steps 4–6; Step 7 photographs the result. A record
taken while Company Portal is still installing is honest evidence of an
incomplete baseline, not a sign-off — so finish the step, then record.

**Fill the manual rows in the post-restart record only.** Each run generates a
fresh `record.md` with the manual rows reset to `TODO`, so anything
you hand-write into the pre-restart record is discarded by the next run. Step 9
produces the sign-off record; Step 10 is where the `TODO` rows get answered. Note
in particular that *First stabilization restart completed* cannot honestly be
answered in the Step 7 record, because at that point the restart has not
happened.

| Step | What you do | Manual rows |
|---|---|---|
| 1 | Reach the cheatsheet and your password manager. | — |
| 2–3 | Install the toolkit, restore `reimage.env`, wire up the shell. | — |
| 4–6 | Enroll, install managed apps, apply macOS updates. | — |
| 7 | Record the pre-restart baseline. | Leave every `TODO` alone. |
| 8 | Take the stabilization restart. | — |
| 9 | Record the post-restart baseline. | Leave them for Step 10. |
| 10 | Close out the exit criteria. | Fill them all, here, once. |

**Every script run has options.** Each step that runs a script previews
`--help` before the command, and the flags that matter for that step are named
alongside it. Read the preview before running the bare form — `--artifact-root`
in particular changes where the record lands, and a record written to the wrong
root has to be relocated by hand afterwards. `--context` labels the run
(`pre-restart`, `post-restart`) so the pair around the restart can be told
apart at a glance rather than by comparing timestamps.

### Terminology

| Term | Meaning |
|---|---|
| Managed baseline | The enrolled, profile-controlled, security-tooled state IT expects on a compliant Mac after Phase 8. |
| Configuration profile | A `.mobileconfig` payload pushed by MDM to enforce settings; listed by `profiles list`. |
| Stabilization restart | The first reboot taken after enrollment and required tool install, before restore work begins. |
| Pre-restart record | The Phase 8 record captured before the stabilization restart. |
| Post-restart record | The Phase 8 record captured after the stabilization restart; used as the sign-off record. |
| Record bundle | One indexed run holding the twelve raw files, `record.md`, and `rows.tsv`. |
| Point | The `--context` value, which becomes the run's point and completes its name: `enroll-and-stabilize-pre-restart-YYYYMMDD-HHMMSS`. `pre-restart` and `post-restart` for the pair around the restart, `initial` when omitted. `entry` and `exit` select the boundary modes instead of a capture. |
| Required assignment | An Intune app assignment that installs itself after enrollment, asynchronously. |
| Available assignment | An Intune app assignment that appears in the Company Portal **Apps** tab and installs only when you click Install. It never arrives on its own. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Artifact and Script Locations

Every path and directory tree this runbook uses is defined here, once. Later sections refer back to these names instead of redrawing them.

Primary script:

```text
$FRACTOGENESIS_HOME/bin/record-enrollment.sh    # entrypoint — records Phase 8 evidence, and its entry and exit boundaries
```

Artifact root:

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/      # Steps 7 and 9 — the evidence either side of the restart
$REIMAGE_ARTIFACT_ROOT/reimaged-system/boundaries/    # Steps 3 and 10 — the entry and exit checklists
```

### Record Bundle Layout

Both directories are run categories with one shape: `runs/<context>-YYYYMMDD-HHMMSS/` holding a single run's files, `official/<context>.txt` naming the run that counts, and an append-only `MANIFEST.md` indexing every completed run. Officialness is computed from the manifest rather than stored, so `official/` can be regenerated.

This phase writes five contexts: `enroll-and-stabilize-entry` and `-exit` under `boundaries/`, and `-initial`, `-pre-restart` and `-post-restart` under `restarts/`. `restarts/` is shared with Phase 9, which writes `verify-reimaged-system-<point>` there — both phases capture the machine either side of a stabilization restart, so they are one lineage keyed by point rather than two categories that have to be read together.

```text
$REIMAGE_ARTIFACT_ROOT/reimaged-system/restarts/
├── MANIFEST.md
├── official/
│   └── enroll-and-stabilize-<point>.txt
└── runs/
    └── enroll-and-stabilize-<point>-YYYYMMDD-HHMMSS/
        ├── record.md
        ├── rows.tsv
        └── raw/
            ├── 01-enrollment-status.txt
            ├── 02-profiles-list.txt
            ├── 03-filevault-status.txt
            ├── 04-managed-apps.txt
            ├── 05-managed-processes.txt
            ├── 06-macos-version.txt
            ├── 07-softwareupdate-list.txt
            ├── 08-managed-app-expectations.txt
            ├── 09-keychain-identities.txt
            ├── 10-package-receipts.txt
            ├── 11-launchd-components.txt
            └── 12-system-extensions.txt
```

`record.md` reports what the machine said; `rows.tsv` carries the same verdicts tab-separated. Step 9 reads the second, not the first — a table meant for a person and a table meant for a script have different jobs, and reparsing Markdown to get a verdict is how they drift apart.

The complete `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` layout is defined once in the Master Directory Reference:

[[master-directory-reference|Master Directory Reference]]

When the artifact volume is not yet mounted, the script falls back to `$REIMAGE_WORKSPACE_ROOT/` and then to `~/Desktop/reimaged-system-artifacts/`, creating the same `restarts/` and `boundaries/` categories under whichever it lands on. The full precedence is spelled out under Supplemental Reference.

### Environment Variables

The `reimage.env` values this runbook depends on. Values are resolved and written during `prepare-artifact-root.md`; on a freshly reimaged Mac the artifact root may not be mounted yet, and the script's fallback chain handles that case.

| Variable | Meaning |
|---|---|
| `REIMAGE_ARTIFACT_ROOT` | Absolute path to the artifact root where `reimaged-system/restarts/` and `reimaged-system/boundaries/` live. Optional here — the script falls back if it is unset or unmounted. |
| `REIMAGE_WORKSPACE_ROOT` | Absolute path to a local workspace used as the intermediate fallback; the categories land under `$REIMAGE_WORKSPACE_ROOT/` when the artifact root is not available. |
| `FRACTOGENESIS_HOME` | Absolute path to the toolkit repository root; entrypoints are run from here. Set by your shell startup / `.envrc`, not stored in `reimage.env`. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Before You Run Anything

A short pre-flight: confirm you are set up, then confirm what you intend this run to do.

### Prerequisites

- The reimage/erase in Phase 7 is complete and the Mac has restarted into Setup Assistant or the first login session.
- You have signed into the company Microsoft 365 / O365 account when prompted and network (Wi-Fi or Ethernet) is connected.
- You have the post-reimage cheatsheet you emailed yourself, or the jump drive built in Phase 6A. One of the two is required: the cheatsheet carries `TOOLKIT_GITHUB_ACCOUNT` for the network route, and the jump drive carries both `bootstrap.sh` and the `reimage.env` copy.

> [!note]
> Unlike every later runbook, this one does **not** assume a shell at
> `$FRACTOGENESIS_HOME` with `reimage.env` loaded. Neither exists yet — Steps 2
> and 3 create them. The guide's [[reimaging-guide#Core Assumptions|Core Assumptions]]
> apply from Step 3 onward.
- Company Portal is installed and signed in. It is the only sanctioned install
  channel for managed apps, and its **Apps** tab is where Available assignments
  are found. Nothing else in this phase substitutes for it.

> [!note]
> `REIMAGE_ARTIFACT_ROOT` and the external artifact volume are *not* required at this point. `record-enrollment.sh` falls back to `$REIMAGE_WORKSPACE_ROOT/` and then to `~/Desktop/reimaged-system-artifacts/`, creating the same `restarts/` and `boundaries/` categories under whichever it lands on, so Phase 8 can complete before the external drive is reconnected in Phase 9.

> [!bug] Troubleshooting
> If the script errors with "shared config loader not found", the toolkit was placed in the wrong location or is a partial extract — re-run bootstrap and confirm `$FRACTOGENESIS_HOME/.internal/load-reimage-config.sh` exists before continuing.

### Confirm Your Intent

- Whether this is the **pre-restart** run (Step 7, before the stabilization
  restart) or the **post-restart** run (Step 9, the sign-off record). Pass that
  answer as `--context pre-restart` or `--context post-restart` so the two
  records are distinguishable on disk without opening them. The flag is
  optional and changes nothing but the directory name and a header line.
- Where the record should land. Default is the artifact root when it is mounted, otherwise the workspace, otherwise `~/Desktop/reimaged-system-artifacts/`. Pass `--output DIR` to force a specific path.
- Whether the managed app set is complete. Required assignments arrive on their
  own; Available assignments never do. If the Company Portal **Apps** tab still
  lists something this Mac needs, finish Step 4 before recording anything.
- Whether the pre-image `managed-inventory/` capture is reachable. When the
  artifact volume is mounted the script can diff the current app set against
  what this Mac had before the erase; when it is not, that row is stamped
  `TODO` and the comparison falls to you.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Sequential Steps

Run these in order. Step 1 gets you the cheatsheet and passwords the rest depends on; Steps 2–3 put the toolkit and its configuration on the Mac; the human-driven steps (enrollment, managed app install, updates, the restart) come next; the script runs are the evidence that proves each step landed. The pre-restart record in Step 7 is the "everything installed and updates applied" snapshot, and the post-restart record in Step 9 is the sign-off snapshot that proves the baseline survived the reboot.

### Step 1 — Reach Your Cheatsheet and Password Manager

Nothing here touches the Mac's configuration. This step exists because the next
one needs two things this machine does not have yet: the account name that
`bootstrap.sh` fetches from, and whatever passwords the phase asks for.

**Open the post-reimage cheatsheet you emailed yourself.** It carries
`TOOLKIT_GITHUB_ACCOUNT` for the network route in Step 2, and the short list of
values worth having on screen before a fresh Mac starts asking for them. The
jump drive built in Phase 6A is the alternative and carries the same values plus
`bootstrap.sh` itself — if you have it, this step is already satisfied.

**Open your password manager** in the same session. Phase 8 and Phase 10B both
ask for credentials that are not on this machine and not on the artifact drive.

> [!note]
> Safari is on every fresh Mac and is enough for both. If your mail or your vault
> is reachable more easily in another browser — a Gmail account, or a vault whose
> extension you rely on — install Google Chrome from Company Portal first, which
> is [[#Step 5 — Install and Confirm Required and Available Managed Apps|Step 5]],
> and come back here. That reorders two steps and costs nothing; enrollment does
> not depend on anything in Step 2 or Step 3.

Neither the cheatsheet nor the vault is stored on the artifact drive on purpose:
the drive is not mounted yet at this point in the phase, and a credential that
only exists on the machine being rebuilt is not a credential you can use.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 2 — Install the Toolkit onto the Rebuilt Mac

Nothing else in this phase can run until the toolkit is on disk. There is no
repository, no `git`, and no SSH key at this point, and that is deliberate —
see [[restore-strategy-guide|restore-strategy-guide.md]] for why the toolkit is
fetched rather than cloned.

**First, decide where the toolkit lives** and export it. `bootstrap.sh` honours
`FRACTOGENESIS_HOME` as its install destination, and every command from here to
Phase 10A refers to the variable rather than a fixed path — so setting it now is
what makes the rest of this runbook work wherever you put the toolkit:

```bash
export FRACTOGENESIS_HOME="$HOME/fractogenesis-toolkit"
```

> [!warning] Pitfall
> Export it on its own line, before anything else. A `VAR=val curl … | bash`
> prefix sets the variable for `curl` only, not for the `bash` on the other side
> of the pipe — which is where `bootstrap.sh` actually runs, and where the value
> is needed.

**Primary route — network available.** Wi-Fi should already be connected from
the Phase 7 sign-in step:

```bash
export TOOLKIT_GITHUB_ACCOUNT="replace-with-the-account-from-your-cheatsheet"
case "${TOOLKIT_GITHUB_ACCOUNT:-}" in
  ''|*'<'*) echo "TOOLKIT_GITHUB_ACCOUNT is not a real account yet." >&2 ;;
  *) curl -fL -o /tmp/bootstrap.sh \
       "https://raw.githubusercontent.com/$TOOLKIT_GITHUB_ACCOUNT/fractogenesis-toolkit/main/bootstrap.sh" \
     && bash /tmp/bootstrap.sh ;;
esac
```

This installs to `$FRACTOGENESIS_HOME`, or to `$HOME/fractogenesis-toolkit` if
you skipped the export above. No `git` is involved: installing `git` on a bare
Mac triggers a large Xcode Command Line Tools download, which this deliberately
avoids.

> [!warning] Pitfall
> Quote and substitute the account. Unquoted, `<your-github-account>` is a shell
> redirection and the line is a syntax error; left unsubstituted, the fetch 404s
> in a way that looks like a missing file rather than a missing value. The `case`
> guard catches both.

> [!note]
> This is the one command in the workflow that cannot read
> `$TOOLKIT_GITHUB_ACCOUNT` from `reimage.env`. That file did not survive the
> erase, and anything able to hand it to you — the jump drive, the artifact
> volume — has already handed you the toolkit, making the fetch unnecessary.
> Take the account from the post-reimage cheatsheet you emailed yourself.

> [!note]
> Download and run as two steps, deliberately. `curl … | bash` hides its own
> failure: with `-f -s`, a 404 or captive-portal redirect prints nothing, `bash`
> reads an empty stdin, and the pipeline exits **0** — no toolkit, no error, and
> no obvious reason why the next command cannot find `bin/`. Fetching to a file
> first makes a failed download impossible to miss.

**Fallback route — no network yet.** Captive portal, delayed profile push, or
enrollment still settling. Use the jump drive prepared in
[[reimage-guide-access|reimage-guide-access.md]] (Phase 6A):

```bash
bash /Volumes/REIMAGEKIT/bootstrap.sh /Volumes/REIMAGEKIT/tarball/fractogenesis-toolkit.tar.gz
```

Note the `tarball/` path segment — that is where `bin/build-jump-drive-payload.sh`
writes the payload and its `.sha256` sidecar. `bootstrap.sh` verifies the
checksum before extracting and refuses to proceed on a corrupted copy rather
than installing something broken.

Either route ends with the toolkit on disk and no further network dependency
for reading the runbooks themselves.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 3 — Establish the Shell Environment

The erase destroyed `FRACTOGENESIS_HOME` and `reimage.env`, and every runbook
from here to Phase 16 assumes both exist. No other phase re-creates them.

**Restore `reimage.env` first.** It is gitignored, so no delivery route carries
it — not the GitHub fetch, not the jump-drive tarball, not a clone. The jump
drive holds the one copy, placed there in Phase 6A. It belongs at the toolkit
root — `$FRACTOGENESIS_HOME`, not the artifact drive — because
`.internal/artifact-config.sh` self-locates and reads `reimage.env` from there
and nowhere else:

```bash
cp /Volumes/REIMAGEKIT/reimage.env "$FRACTOGENESIS_HOME/reimage.env"
```

Paths are spelled out literally here on purpose: `$JUMP_DRIVE_VOLUME` and
`$REIMAGE_ARTIFACT_ROOT` are themselves `reimage.env` keys and are still unset.

**Restore the workspace fragments too.** `artifact-config/` and `staged-certs/`
live under `$REIMAGE_WORKSPACE_ROOT`, are gitignored like `reimage.env`, and are
read by every phase from here on:

```bash
mkdir -p "$HOME/reimage-workspace"
rsync -rlt --no-perms --no-owner --no-group \
  /Volumes/REIMAGEKIT/reimage-workspace/ "$HOME/reimage-workspace/"
ls -1 "$HOME/reimage-workspace/artifact-config/"
```

`--no-perms` because the jump drive is not a POSIX filesystem and everything on
it reads as `0777`.

> [!warning] Pitfall
> Their absence is silent. With `REIMAGE_WORKSPACE_ROOT` set but
> `artifact-config/` missing, every script prints one warning to stderr and then
> falls back to the committed templates — producing evidence that looks identical
> to a run against your own configuration. If the jump-drive copy is missing,
> recover from the home backup instead:
>
> ```bash
> find "$REIMAGE_ARTIFACT_ROOT/home-files-backup" -type d -name artifact-config
> ```
>
> and copy it back before running anything that records evidence.

> [!warning] Pitfall
> Do **not** rebuild `reimage.env` with `bin/setup-reimage-env.sh` when the copy
> is inconvenient to reach. That script *recomputes* values rather than
> restoring them: `REIMAGE_START_DATE` defaults to today, so
> `REIMAGE_ARTIFACT_ROOT` resolves to a **new, empty** event folder instead of
> the one holding your backups. Every restore step then reports MISSING for
> every source while writing its notes into the wrong tree — a failure that
> looks like a bad backup rather than a bad variable. Regenerating is only
> correct when starting a genuinely new reimage event.

**Then wire both into your shell, once:**

```bash
bash "$FRACTOGENESIS_HOME/bin/init-shell-env.sh"
exec zsh -l
```

`init-shell-env.sh` appends one marked block to `~/.zprofile` that exports
`FRACTOGENESIS_HOME` and sources `reimage.env` on every login shell. It writes
no values of its own — `reimage.env` stays the single source of truth, so
editing that file changes every new shell without touching your profile again.
The block is idempotent, and `--remove` takes it back out when the reimage is
finished.

Preview before it writes anything:

```bash
bash "$FRACTOGENESIS_HOME/bin/init-shell-env.sh" --dry-run
```

> [!note]
> This replaces what `.envrc` did before the erase. Without it, every new
> Terminal — including the one after the stabilization restart in Step 8 —
> starts with none of these values, and `cd "$FRACTOGENESIS_HOME"` becomes
> `cd ""`, a **no-op that returns 0**. You stay in `$HOME`, every `./bin/…`
> afterward reports "No such file or directory", and nothing points back at the
> missing variable.

Confirm before continuing:

```bash
cd "$FRACTOGENESIS_HOME"
./bin/check-reimage-env.sh
```

From this point on, the commands in this and every later runbook assume you are
at `$FRACTOGENESIS_HOME` with `reimage.env` loaded.

> [!note]
> `bin/` scripts do not actually depend on your shell: each one sources
> `.internal/load-reimage-config.sh`, which reads `reimage.env` from the toolkit
> root itself. What the profile block buys you is the *typed* commands —
> `ls "$REIMAGE_ARTIFACT_ROOT"` and the like — working without a manual
> `source` in every new terminal.
>
> The block is a bridge, not the permanent arrangement. direnv arrives in Phase
> 10A and takes over from `.envrc`; remove the block then. Full picture:
> [[toolkit-environment-reference|Toolkit Environment Reference]].

**Record the entry boundary.** Every other runbook records its entry conditions
at Step 0. This one cannot: Phase 8 begins on a Mac with no toolkit on it, and
`$FRACTOGENESIS_HOME` and `reimage.env` are what Steps 2 and 3 just created. Here
is the first moment there is anything to run, and the rows are about what was
true before the phase started as much as what these two steps established:

```bash
./bin/record-enrollment.sh --context entry
```

It writes `checklist.md` under `reimaged-system/boundaries/` with the context
`enroll-and-stabilize-entry`, and exits non-zero on any `FAIL`. A `FAIL` on
network or Company Portal stops the phase — enrollment, managed installs and
macOS updates each need both. Two rows are left `TODO`; answer them in that file
as described in Step 10, which explains the mechanics once for both boundaries.

> [!note]
> The artifact root row is expected to be `WARN` here. The external volume is not
> reconnected until Phase 9 Step 1, so this checklist lands on the workspace or
> Desktop fallback along with everything else this phase writes.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 4 — Complete Managed Enrollment

Complete the managed enrollment flow driven by the OS and Company Portal:

1. Restart the Mac if it has not already restarted after Phase 7.
2. Connect to Wi-Fi or Ethernet.
3. Sign in with the company Microsoft 365 / O365 account when prompted.
4. Confirm Intune / MDM enrollment starts and let the required profiles and base software begin installing.

Components that arrive on their own in this step — no clicking required. They
are **not** all applications, and the ones that are rarely carry the vendor's
name, which is why a plain "is CrowdStrike installed?" look at `/Applications`
misleads:

| Component | Where it actually shows up |
|---|---|
| Intune / MDM enrollment | `profiles status -type enrollment`; package receipt `com.microsoft.intuneMDMAgent`; `Company Portal.app` |
| Required management profiles | `sudo profiles list` — configuration payloads, not files in `/Applications` |
| Company Portal | `Company Portal.app`, receipt `com.microsoft.CompanyPortalMac` |
| CrowdStrike Falcon | **`Falcon.app`** — the bundle carries the product name, not the vendor's. Receipt `com.crowdstrike.falcon.sensor.sysx`; system extension `sysx` |
| Zscaler | **`/Applications/Zscaler/Zscaler.app`** — nested one level down, so a top-level listing shows only the enclosing `Zscaler` folder. Receipt `com.zscaler.zscaler` |
| Other agents assigned by policy | varies by company — for example a Check Point `Identity Agent.app` |
| Agents with **no app at all** | DLP, endpoint-recovery, and SSO components often ship as system extensions, daemons, or configuration payloads only. They appear in `sudo profiles list` and `systemextensionsctl list`, never in `/Applications` |
| Certificate identities | `Microsoft.Profiles.SCEP.*` and `*.credentials.*` payloads re-issue the Keychain identities that could not be exported before the erase. Captured automatically in `raw/09-keychain-identities.txt` |
| FileVault enforcement | `com.apple.MCX.FileVault2` plus escrow payloads. Captured in `raw/03-filevault-status.txt` and stamped as its own exit-criteria row — Phase 14 fails sign-off if it is off |

> [!note]
> **The profile count is the quickest check that policy landed in full.**
> `profiles list` ends with a line such as `There are 17 system configuration
> profiles installed`; a machine mid-push shows noticeably fewer. Step 7's record
> extracts that number into its own exit-criteria row, so there is nothing to
> note by hand — but the row reads `unknown` when the listing was not readable at
> the privilege level the script ran with, which means "could not tell", not
> "none installed".

> [!note]
> **Required pushes are asynchronous and keep arriving.** The set present when you
> first look is a snapshot, not the final state; an agent can land an hour later
> with no prompt and no action from you. Do not treat a component missing here as
> missing for good — Step 7's record captures whatever exists at that moment, and
> Step 9's post-restart record is the one that matters.

> [!note]
> **Microsoft Office does not arrive here.** It is almost always an *Available*
> assignment, which means it installs only when you click Install in the Company
> Portal Apps tab — that is Step 5. Waiting for Office in this step is the single
> most common way to lose an afternoon in Phase 8.

> [!warning] Pitfall
> Do not manually install Office or security tooling from a separate channel unless IT explicitly asks. Duplicate installs can conflict with the managed copy that policy is about to push.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 5 — Install and Confirm Required and Available Managed Apps

Intune assigns apps in two modes, and they behave differently. Both must be
settled before Phase 9 begins.

| Assignment | Behavior | What you do |
|---|---|---|
| Required | Pushed automatically after enrollment. Delivery is asynchronous and can take from minutes to hours. | Wait, and confirm arrival. |
| Available | Listed in the Company Portal **Apps** tab with an Install button. **Never installs on its own.** | Open the Apps tab and install what this Mac needs. |

Open **Company Portal** → **Apps** → **All apps**. The catalog lists everything
assigned to this account, but **do not install all of it here**. This phase needs
three, and each for a different reason:

| Install now | Why here rather than later |
|---|---|
| **Google Chrome** | Install this first. It is how you reach LastPass for every password this phase and the next need, and the email holding the post-reimage cheatsheet that carries `TOOLKIT_GITHUB_ACCOUNT` for Step 1. |
| **Microsoft 365 Apps for macOS** | The single suite item that delivers Word, Excel, PowerPoint, Outlook and OneNote — plus Teams, OneDrive and AutoUpdate. The individual Microsoft apps are not separately installable; this is the only way to get them. |
| **Zscaler** | The TLS-inspecting proxy agent. It has to be in place before Phase 10B trusts the corporate CA, and its absence changes how every later network failure reads. |

Everything else in the catalog belongs to a later phase or to no phase at all.
**Postman Enterprise in particular is installed during Phase 12**
([[restore-apps|restore-apps.md]]), together with its settings and environments —
installing it here gives you an empty copy that the restore then has to work
around. Microsoft Edge, PrinterLogic and Identity Agent are installed when you
actually need them, on the same reasoning.

> [!note]
> Chrome comes from Company Portal, which needs enrollment — so on a Mac where
> Step 3 has not finished, use Safari to reach the cheatsheet and LastPass for
> long enough to get through Step 1. Chrome is a convenience here, not a
> dependency; nothing in this runbook requires a specific browser.

Confirm what actually landed:

```bash
ls -1 /Applications
ls -1 /Applications/*/ 2>/dev/null | grep -Ei 'zscaler|falcon|crowdstrike'
pkgutil --pkgs | grep -iE 'com.microsoft|crowdstrike|zscaler'
sudo profiles list | grep -iEB2 -A4 'microsoft|office|autoupdate'
```

> [!note]
> Some managed apps install **nested**, not at the top level of
> `/Applications`.
> A top-level `ls | grep` will miss some and read as "not installed" on a machine
> where it is running fine. Check the menu bar before concluding an agent is
> absent.

> [!note]
> **Office installs as one suite, and brings more than Office.** A complete
> install of *Microsoft 365 Apps for macOS* puts Word, Excel, PowerPoint,
> Outlook, and OneNote in `/Applications` — and typically Teams, OneDrive, and
> Microsoft AutoUpdate alongside them. Confirm by receipt rather than by eye,
> since the app names and the package identifiers do not match:
>
> ```bash
> pkgutil --pkgs | grep -iE 'com\.microsoft\.(package|teams|OneDrive|pkg\.licensing)'
> ```
>
> Expect `com.microsoft.package.Microsoft_<App>.app` for each app, plus
> `com.microsoft.package.Microsoft_AutoUpdate.app`, `com.microsoft.pkg.licensing`,
> and shared components such as `Frameworks`, `Proofing_Tools`, and `DFonts`.
> If Teams and OneDrive appear here, they came with the suite and are not separate
> assignments to chase.

> [!note]
> The authoritative list of what this Mac should have is the pre-image capture,
> not this runbook. Compare against it rather than against a fixed expectation:
>
> ```bash
> grep -riE 'teams|onenote|crowdstrike|falcon|zscaler' \
>   "$REIMAGE_ARTIFACT_ROOT/managed-inventory/" | head -40
> ```
>
> Anything present pre-image and absent now is a real gap. Anything in neither
> was never assigned to this account.

If an app is in neither the Required push nor the Available catalog, it is not
assigned to you. That is an IT request, not a local fix — and the question to
ask is *"what is the sanctioned channel for this on a Mac here?"*, since some
apps are licensed for self-install from a vendor portal instead of deployed
through Intune.

> [!warning] Pitfall
> Do not install Office, security tooling, or any other managed app from a
> vendor download or from Homebrew. An unmanaged copy receives no configuration
> profiles, can collide with the managed package when it lands, and can read as
> non-compliant. Company Portal is the channel.

> [!warning] Pitfall
> Do not remove profiles, disable security software, or change management
> settings while waiting for installs to complete, even to work around a slow
> rollout. IT owns that state.

> [!note]
> Installing a TLS-inspecting proxy agent here is intentional and its effects
> are handled later. Tools carrying their own CA bundle — npm, pip, `requests`,
> Java — will fail certificate validation until
> [[restore-access#Step 7 — Trust the Corporate CA Outside the Keychain|Phase 10B Step 7]].
> That is expected, not a broken install.

> [!note]
> Leave OneDrive **signed out** for now. The app arrives with the Office suite,
> but starting an initial sync conflicts with the Phase 9 restart and Time
> Machine steps, and its interaction with the later home-files restore is not
> yet settled.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 6 — Apply Required macOS Updates

If IT policy, Company Portal, or System Settings requires macOS updates before restore work, complete them here.

1. Apply the required macOS updates using the approved path.
2. Allow any required reboot to complete.
3. Return to this runbook before doing restore work.

**If the update forces a reboot, let it happen here and carry on to Step 7
afterwards.** Do not try to count it as the Step 8 stabilization restart.

That shortcut looks like it saves a reboot, and it costs more than it saves:

- **Step 8 is a gate, not just a reboot.** It has four pre-restart confirmations,
  and skipping to Step 9 skips them. One of them — *"any required
  update-triggered restart is already done or in motion"* — cannot be satisfied
  by the very restart it is meant to gate.
- **It breaks what the pair of records means.** Step 7 is the
  everything-installed-and-updates-applied snapshot. Run before an update
  reboot, it is not: updates apply *during* that reboot. Step 9 then differs from
  Step 7 in two ways at once — a reboot *and* an OS version change — with
  `sw_vers` and `softwareupdate --list` both moving. The comparison exists to
  isolate whether the managed baseline survived a reboot, and it can no longer
  answer that.

Taking the update reboot as part of this step, then recording Step 7, then
taking a deliberate Step 8 restart costs about two extra minutes and keeps both
records meaning what they claim.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 7 — Record the Pre-Restart Baseline

Record the evidence that Steps 4–6 landed as expected. Preview the script's options first so you know which fallback path it will pick:

```bash
./bin/record-enrollment.sh --help
```

Run the record, labelling it as the pre-restart run. With no `--output`, the destination follows the fallback chain: the artifact root when it is mounted, otherwise `$REIMAGE_WORKSPACE_ROOT/`, otherwise the Desktop:

```bash
sudo -v && ./bin/record-enrollment.sh --context pre-restart
```

> [!note]
> **Why `sudo -v` first.** `profiles list` returns *user-level* profiles
> unprivileged — typically four — while the managed baseline lives at
> `_computerlevel` and is several times larger. The script never prompts for a
> password: it tries `sudo -n`, which succeeds only against an already-cached
> credential and fails instantly otherwise. That keeps the script safe to rerun
> unattended, and it means the system-scope count is captured only if you have
> used `sudo` recently.
>
> `sudo -v` refreshes that credential without running anything, so the record
> gets the number that matters. It is optional: without it the run still
> succeeds, and the profile row simply reports `user scope` and says so.

> [!note]
> The run lands at `restarts/runs/enroll-and-stabilize-pre-restart-YYYYMMDD-HHMMSS/`
> and is indexed in that category's `MANIFEST.md`. Nothing needs to glob for it:
> `official/enroll-and-stabilize-pre-restart.txt` names the run that counts, which
> is how Step 10 and Phase 9 both find it.


If the external artifact volume is already reconnected, force the record onto it explicitly:

```bash
sudo -v && ./bin/record-enrollment.sh --context pre-restart --artifact-root "$REIMAGE_ARTIFACT_ROOT"
```

The script prints each subsystem as it runs, writes the twelve `raw/NN-*.txt` files, generates `record.md`, writes `rows.tsv` beside it, and indexes the run.

> [!note]
> `WARN` on a row does not mean failure. Review the raw file for context — a `WARN` on the macOS updates row while updates are still pending is expected before Step 6 finishes.
>
> The record states what the machine reported and nothing more. It carries no exit criteria and no `TODO` rows: those are Step 10's, asked once, against the post-restart run. That separation is why rerunning a capture here can never discard an answer someone already gave.

> [!bug] Troubleshooting
> If the profiles row recorded nothing at all, see [[#Profiles list is empty right after enrollment|Profiles list is empty right after enrollment]].

> [!bug] Troubleshooting
> If the script reports a Desktop path instead of the artifact root, see [[#The record landed on the Desktop instead of the artifact root|The record landed on the Desktop instead of the artifact root]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 8 — Take the First Stabilization Restart

Restart the Mac to confirm the managed baseline survives a reboot.

Before restarting, confirm:

```text
required managed installs are not obviously in a broken state
any required update-triggered restart is already done or in motion
you are ready to validate the same baseline again after login
no Company Portal install or Microsoft AutoUpdate download is still in flight
```

After the restart:

1. Sign back in.
2. Reconnect network if needed.
3. Continue directly to Step 9.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 9 — Record the Post-Restart Baseline

Rerun the record after the restart, labelled as the post-restart run. This is the sign-off record: it is the one you cite when closing out the exit criteria in Step 10.

```bash
sudo -v && ./bin/record-enrollment.sh --context post-restart
```

> [!warning] Pitfall
> The `sudo` credential does not survive the restart. Without `sudo -v` here, the
> post-restart record captures user-scope profiles while the pre-restart record
> captured system-scope — and the two counts are then not comparable, which is
> the one thing this pair of records exists to support.

Each run writes a fresh indexed run, so the pre-restart record from Step 7 is left in place for comparison and `official/enroll-and-stabilize-post-restart.txt` moves to this one. Step 10 reads that pointer, so there is nothing to select by hand and no way to cite the Step 7 record by mistake.

Confirm manually that:

```text
Company Portal still opens and looks normal
required security tools appear to have survived reboot cleanly
there is no obvious loss of enrollment, profiles, or base managed apps
```

> [!bug] Troubleshooting
> If a key item disappeared after the restart (missing profiles, missing security tool, enrollment reporting unenrolled), stop and resolve that with IT before moving on. Do not begin restore work on a broken managed baseline.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

### Step 10 — Close Out the Exit Criteria

Confirm what this phase produced. This is a close-out, not a check of the next
phase: Phase 9 verifies its own entry conditions in its Step 0.

```bash
./bin/record-enrollment.sh --context exit
```

It writes `checklist.md` under `reimaged-system/boundaries/` with the context
`enroll-and-stabilize-exit`, and exits non-zero on any `FAIL`. The file holds two
tables: **Automated**, and **Manual** — the rows it cannot answer, left as `TODO`.

The Automated rows are not fresh probes. They restate the verdicts the Step 9 run
recorded, read from that run's `rows.tsv`, which the script finds through
`official/enroll-and-stabilize-post-restart.txt`. There is no pointer to walk and
no way to sign off against the Step 7 record by accident, and a checklist built
this way cannot disagree with the evidence it cites.

> [!warning] Pitfall
> A `FAIL` on **Post-restart baseline recorded** means Step 9 has not run since
> the restart. Run it, then rerun this — do not answer around the row. The whole
> close-out is a statement about the post-restart machine, and without that run
> there is nothing for it to be about.

**Answer the Manual rows.** Nothing re-probes them and no later phase collects
them: you answer them by editing `checklist.md` itself. Replace each `TODO` with
the answer and put the reasoning in Notes. `yes` and `accepted` close a row, and
so does `no` when `no` is the considered answer — the check is for rows nobody
looked at.

*Company Portal shows the expected state.* Open it, confirm the device is listed,
and check that the **Apps** tab shows nothing this Mac needs still listed as
installable. Anything outstanding belongs to Step 5, not here.

*Required security tools are installed or actively installing.* An agent mid-install
and an agent that failed look identical from a process list, which is why this row
is manual. Give it a few minutes and look again before closing it.

*First stabilization restart completed.* You observed it and came back to a login
session. Recorded because the two baselines mean nothing if the restart between
them never happened.

*Keychain identities re-issued.* Compare the count and shape against the pre-image
record. Expect the same number with different fingerprints — MDM re-issues these
rather than restoring them, so matching fingerprints would be the surprising
result.

> [!warning] Pitfall
> Each run writes its own dated directory, so a rerun does not update the file you
> answered — it produces a new `checklist.md` with every Manual row back at
> `TODO`. Answer them in the last run you intend to keep, and carry the answers
> forward if you rerun after answering.

The exit criteria for this phase, and where each is settled:

| Area | Settled by |
|---|---|
| Enrollment completed | Automated, from the Step 9 record |
| Required profiles and certificates present | Automated, from the Step 9 record |
| macOS updates complete or intentionally deferred | Automated, from the Step 9 record |
| Managed application set matches the pre-image inventory | Automated, from the Step 9 record |
| FileVault is on | Automated, from the Step 9 record — Phase 14 fails sign-off if it is off |
| Both baselines recorded, bracketing the restart | Automated, from the run index |
| Company Portal state, security tooling, the restart itself, identity re-issue | Manual, answered here |

Once the checklist has no `FAIL` and no unanswered `TODO`, move to
[[verify-reimaged-system|verify-reimaged-system.md]]. Its Step 0 reads this
checklist rather than re-deriving any of it, which is the reason to finish it here
rather than carrying an open row forward.

> [!bug] Troubleshooting
> If the enrollment row reads `WARN` on a Mac you know is enrolled, see [[#Enrollment row is WARN even though the Mac is clearly enrolled|Enrollment row is WARN even though the Mac is clearly enrolled]].

> [!bug] Troubleshooting
> If the security-tools row reads `WARN`, see [[#Security tools row is WARN|Security tools row is WARN]].

> [!bug] Troubleshooting
> If the managed-application row reads `TODO` or names apps you do not recognise, see [[#Managed application row is TODO or names unexpected apps|Managed application row is TODO or names unexpected apps]].

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Decisions

The script records uniformly and applies fixed heuristics; interpreting the managed state itself is the judgment call.

| Decision | Why it stays with you |
|---|---|
| Whether a `WARN` row is actually acceptable on this Mac. | Policy varies (deferred updates, staged security-tool rollouts, in-flight profile pushes); only you can weigh the raw evidence against what IT expects right now. |
| Whether to accept a `WARN` on the macOS-updates row rather than applying an offered update. | Policy varies on which updates are required before restore work and which can wait; only you know what IT expects on this Mac right now. |
| Whether a missing managed component means "wait longer" or "escalate to IT". | Rollouts are asynchronous; the script cannot tell in-progress from stalled. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Troubleshooting

Five outcomes look like failures but usually are not, and each would otherwise break the flow of the step that surfaces them. The step that surfaces each one links in from a callout.

[[#Table of Contents|⬆ Back to Table of Contents]]

### Profiles list is empty right after enrollment

Profile push is asynchronous. Wait a few minutes and rerun `./bin/record-enrollment.sh`. If it stays empty for more than roughly 10–15 minutes on a network-connected machine, check Company Portal for a pending enrollment issue before escalating.

[[#Step 8 — Take the First Stabilization Restart|⮕ Continue to Step 8 — Take the First Stabilization Restart]]

### The record landed on the Desktop instead of the artifact root

That is the intended final fallback when neither `REIMAGE_ARTIFACT_ROOT` nor `REIMAGE_WORKSPACE_ROOT` resolves to a mounted directory. Phase 9 Step 1 relocates what landed there; you can also rerun the script with `--artifact-root "$REIMAGE_ARTIFACT_ROOT"` once the volume is back, so the run is indexed alongside the other Phase 8+ evidence rather than in a second category on the Desktop.

[[#Step 8 — Take the First Stabilization Restart|⮕ Continue to Step 8 — Take the First Stabilization Restart]]

### Enrollment row is WARN even though the Mac is clearly enrolled

`profiles status -type enrollment` phrasing has changed across macOS versions; the heuristic looks for `enrolled|yes|mdm`. Open `raw/01-enrollment-status.txt` and read the actual line — if it reports MDM enrollment in different wording, mark the row `PASS` by hand and note the wording.

[[#Step 10 — Close Out the Exit Criteria|⮕ Continue to Step 10 — Close Out the Exit Criteria]]

### Managed application row is TODO or names unexpected apps

`TODO` means the comparison had no source: the pre-image `managed-inventory/`
capture was not reachable, which is normal when Phase 8 runs before the external
artifact volume is reconnected. Rerun after Phase 9 Step 1 with
`--artifact-root "$REIMAGE_ARTIFACT_ROOT"`, or close the row by hand against the
Company Portal **Apps** tab.

A `WARN` naming apps you do not recognise is usually the extraction being
literal rather than wrong. The comparison pulls every `.app` name it can find in
the inventory text, so it picks up bundles nested inside other applications and
helper bundles that were never separately installed. Read the list, ignore the
ones that were never top-level applications, and act only on the real absences.
The row is `Mixed` for exactly this reason — the script narrows the search, you
make the call.

[[#Step 10 — Close Out the Exit Criteria|⮕ Continue to Step 10 — Close Out the Exit Criteria]]

### Security tools row is WARN

Confirm the app or process name in `raw/04-managed-apps.txt` / `raw/05-managed-processes.txt`. CrowdStrike ships as `Falcon.app`, and the heuristic looks for both names — but a vendor rename or a staged rollout can miss the pattern. Rerun after the install finishes; if the tool is genuinely absent and policy expects it, escalate.

[[#Step 10 — Close Out the Exit Criteria|⮕ Continue to Step 10 — Close Out the Exit Criteria]]

---

## Supplemental Reference

Longer material most runs will not need, kept out of the main flow.

### Per-Section Command Reference

Use these only when you need to rerun or troubleshoot a single subsystem outside the script. Do not duplicate evidence the script already recorded successfully — the script and this reference cover the same commands.

Enrollment status:

```bash
profiles status -type enrollment 2>/dev/null || true
```

Installed configuration profiles:

```bash
profiles list 2>/dev/null || true
```

FileVault status:

```bash
fdesetup status
```

Applications present under `/Applications`, including one level of nesting so
agents such as `Zscaler/Zscaler.app` are not missed:

```bash
{ ls -1 /Applications 2>/dev/null; \
  ls -1d /Applications/*/*.app 2>/dev/null | sed 's#^/Applications/##'; } | sort -u
```

What this Mac had before the erase, for comparison:

```bash
grep -rhoiE '[A-Za-z0-9][A-Za-z0-9._ -]*\.app' \
  "$REIMAGE_ARTIFACT_ROOT/managed-inventory" 2>/dev/null | sort -uf
```

Expected managed processes running:

```bash
ps aux | grep -Ei 'Intune|Company Portal|CrowdStrike|falcon|Zscaler|Microsoft AutoUpdate|MAU|mdmclient' | grep -v grep || true
```

Current macOS version and build:

```bash
sw_vers
```

Available software updates:

```bash
softwareupdate --list 2>/dev/null || true
```

### Output Location Fallback Chain

`record-enrollment.sh` picks its output directory in this order when `--output` is not supplied. The chain exists because Phase 8 typically runs before the external artifact volume is reconnected.

| Order | Condition | Path |
|---|---|---|
| 1 | `REIMAGE_ARTIFACT_ROOT` set and directory exists | `$REIMAGE_ARTIFACT_ROOT/reimaged-system/` |
| 2 | Artifact root unavailable, `REIMAGE_WORKSPACE_ROOT` set and directory exists | `$REIMAGE_WORKSPACE_ROOT/` |
| 3 | Neither of the above | `~/Desktop/reimaged-system-artifacts/` |

The `restarts/` and `boundaries/` categories are created under whichever tier wins, so a fallback run is a complete, indexed category rather than a loose directory.

The script refuses to write output under the toolkit repo checkout as a safety invariant — a record landing inside the working tree almost always signals an unset or relative root variable, not a real destination.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

<!--
TOC verification performed before publishing:
- every Table of Contents entry resolves to a heading present in this file;
- deleted optional sections were also removed from the Table of Contents;
- each top-level section and each Sequential Step ends with a "Back to Table of
  Contents" link and a divider, except the first step, which has nothing above it
  to return from, and Troubleshooting, whose back-link sits under its intro and
  whose routed symptom subsections stay out of the Table of Contents.
-->
