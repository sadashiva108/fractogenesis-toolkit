[[reimaging-guide|← Back to Mac Reimaging Guide]]

# Environment Variable Reference

**Last Updated:** 2026-09-01

Which runbook owns each `reimage.env` key, when it is written, and why most keys are absent from `reimage.env.example` rather than sitting in it blank.

This exists because the answer used to be spread across three places that disagreed. `reimage.env.example` carried blanks for keys no phase set until much later; `bin/setup-reimage-env.sh` captured a dozen of those at creation time if they happened to be exported; and each runbook's *Environment Variables* table named values without saying who wrote them. The result was a key — `GIT_PERSONAL_GITHUB_OWNER` — that a script read, no runbook documented, and nothing set, which is only discoverable by reading the script.

---

## Table of Contents

- [[#The Ownership Rule|The Ownership Rule]]
- [[#The Key Catalog|The Key Catalog]]
- [[#Why Most Keys Are Absent From the Template|Why Most Keys Are Absent From the Template]]
- [[#Writing a Key — the Guard|Writing a Key — the Guard]]
- [[#Optional Keys and All-or-Nothing Groups|Optional Keys and All-or-Nothing Groups]]
- [[#Where a Key Gets Checked|Where a Key Gets Checked]]
- [[#Adding a New Key|Adding a New Key]]
- [[#Owned Elsewhere|Owned Elsewhere]]

> In Obsidian, these are internal heading links. Click in Reading View, or Cmd-click in Live Preview/editing mode.

---

## The Ownership Rule

**The runbook that uses a value is the runbook that sets it.**

The question to ask of any key, in any runbook, is: *does this runbook need it set, and does it use it?* If yes, that runbook writes it. If no, it does not appear in that runbook's tables, its template, or its capture lists — not even as a blank.

One consequence is worth stating plainly, because it is the one that keeps getting re-litigated: a value is not recorded early "so it is not forgotten". A key recorded three phases before its first use is a value nobody has verified against the machine that will actually consume it, sitting in a file that reads as though someone did.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## The Key Catalog

`FRACTOGENESIS_HOME` is deliberately absent from every row below: it is the one value that cannot live in `reimage.env`, because you need it to find the file. See [[toolkit-environment-reference|Toolkit Environment Reference]].

### Written during `prepare-artifact-root.md` (Phase 1)

These are what `reimage.env.example` carries, and what `bin/prepare-artifact-root.py init-reimage-env` writes into the copy.

| Variable | Notes |
|---|---|
| `EXTERNAL_DATA_VOLUME` | The mounted volume, not the event folder on it. |
| `EXTERNAL_APPLE_BACKUPS_VOLUME` | Optional dedicated Time Machine destination. |
| `JUMP_DRIVE_VOLUME` | No-network bootstrap fallback drive. Captured from the shell by `setup-reimage-env.sh`, not computed. |
| `TOOLKIT_GITHUB_ACCOUNT` | Account the toolkit is fetched from. Captured from the shell, not computed. Deliberately not the source of truth for the first fetch after an erase — see [[reimage-guide-access\|reimage-guide-access.md]]. |
| `ASSET_OR_HOST` | Defaults to the hostname. |
| `REIMAGE_START_DATE` | Defaults to today, `YYYYMMDD`. |
| `REIMAGE_ARTIFACT_ROOT` | Computed from the three above; resolved at creation, not edited afterwards. |
| `REIMAGE_WORKSPACE_ROOT` | Holds the artifact-config and staged-certs fragments. |
| `PERFORMANCE_HISTORY_SOURCE` | Emitted blank; [[capture-performance-audit\|capture-performance-audit.md]] (Phase 4C) records the real value. |
| `OFFICE_WATCH` | Emitted blank; [[capture-office-stability\|capture-office-stability.md]] (Phase 4D) records the real value. |
| `ONEDRIVE_FOLDER_NAME`, `ONEDRIVE_PARENT_DIR`, `ONEDRIVE_ROOT`, `ONEDRIVE_DEST_SUBDIR` | Resolved together; all four stay blank when OneDrive is not in play. |

### Written by a later runbook

None of these appear in `reimage.env.example`. They do not exist in `reimage.env` until the step named here writes them.

| Variable | Written by | Step |
|---|---|---|
| `LOCAL_WORK_REPO_ROOT` | [[backup-repos\|backup-repos.md]] (Phase 2A) | Step 1 |
| `LOCAL_PERSONAL_REPO_ROOT` | [[backup-repos\|backup-repos.md]] (Phase 2A) | Step 1 |
| `REIMAGE_JDK_BASELINE` | [[restore-runtime\|restore-runtime.md]] (Phase 10A) | Step 7 |
| `JAVA_HOME` | [[restore-runtime\|restore-runtime.md]] (Phase 10A) | Step 7 |
| `GIT_WORK_NAME`, `GIT_WORK_EMAIL`, `GIT_WORK_SSH_KEY`, `GIT_WORK_GITHUB_HOST`, `GIT_DEFAULT_BRANCH` | [[restore-git\|restore-git.md]] (Phase 11A) | Step 0c |
| `GIT_PERSONAL_NAME`, `GIT_PERSONAL_EMAIL`, `GIT_PERSONAL_SSH_KEY`, `GIT_PERSONAL_GITHUB_HOST` | [[restore-git\|restore-git.md]] (Phase 11A) | Step 0c |
| `GIT_PERSONAL_GITHUB_HOSTNAME` | [[restore-git\|restore-git.md]] (Phase 11A) | Step 0c |
| `GIT_PERSONAL_GITHUB_OWNER` | [[restore-repos\|restore-repos.md]] (Phase 11B) | Step 0c |

[[restore-access|restore-access.md]] (Phase 10B) Step 0 re-records `REIMAGE_JDK_BASELINE` and `JAVA_HOME` when a `reimage.env` predating Phase 10A Step 7 reaches it. That is a recovery path, not ownership: it confirms first and writes only when the value is missing.

### Deliberately not a key

| Value | Why |
|---|---|
| The secrets DMG password | `reimage.env` sits in plaintext on the artifact volume beside the DMG and is sourced into every script's environment. Storing the password there defeats the encryption it protects. Keep it in a password manager and record only the entry *name* on the cheatsheet. |
| A per-host TLS verification skip | TLS verification stays on. A host that genuinely will not verify is a debugging situation, not a configuration option — see [[restore-git#An internal Enterprise Server host fails TLS verification\|restore-git.md → Troubleshooting]]. `record-restore-exit.sh --runbook restore-git` records a `FAIL` on a global `http.sslverify=false`. |
| `FRACTOGENESIS_HOME` | Needed to find `reimage.env`, so it cannot come from it. A shell-startup concern. |

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Why Most Keys Are Absent From the Template

Not blank in it. **Absent.**

A blank in `reimage.env.example` reads as *fill me in now*. Copied at Phase 1, it invites an operator to supply a Phase 11A value on a machine that has not been erased yet, with nothing checking that the value is the one the rebuilt Mac will actually restore with. A key listed there that no runbook owns is worse: `GIT_PERSONAL_GITHUB_OWNER` sat in the template unset and undocumented through an entire reimage, silently meaning *never rewrite a clone URL* — which looks exactly like a clean run.

Nothing needs the placeholder. `prepare-artifact-root.py upsert-env` replaces a matching `export KEY=` line when it finds one and **appends** the key when it does not:

```python
for key, value in normalized.items():
    if key not in seen:
        out.append("export {0}={1}".format(key, quote_value(value)))
```

So `reimage.env` accumulates keys in the order the phases actually run, and the file itself becomes a record of how far the reimage got.

`bin/setup-reimage-env.sh` captures only `OFFICE_WATCH`, `JUMP_DRIVE_VOLUME` and `TOOLKIT_GITHUB_ACCOUNT` from the shell for the same reason. It used to capture the two repository roots and nine Git identity keys; that was the back door the template's blanks invited, and it is closed.

> [!warning] Pitfall
> `upsert-env` matches on a line beginning `export `. A key written without it — `REIMAGE_JDK_BASELINE=` rather than `export REIMAGE_JDK_BASELINE=` — is invisible to the matcher, so a later write appends a **second** line and the file carries two, with only the last one winning when sourced. Every key in `reimage.env` is an `export`.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Writing a Key — the Guard

`upsert-env` writes whatever it is given, including an empty value, and reports no error when it does. Nothing downstream distinguishes *never set* from *set to nothing*.

So a runbook checks the values **in the same block that writes them**, where the check cannot drift away from the thing it protects. The established form, from [[restore-runtime#Step 7 — Install Java and the JVM Build Tools|restore-runtime.md]] Step 7:

```bash
if [ -z "$REIMAGE_JDK_BASELINE" ] || [ -z "$JAVA_HOME" ]; then
  printf 'REFUSING to write: REIMAGE_JDK_BASELINE=%s JAVA_HOME=%s\n' \
    "${REIMAGE_JDK_BASELINE:-<empty>}" "${JAVA_HOME:-<empty>}"
  printf 'Fix the empty one above before running upsert-env.\n'
else
  python3 bin/prepare-artifact-root.py \
    upsert-env \
    --env-file reimage.env \
    "REIMAGE_JDK_BASELINE=${REIMAGE_JDK_BASELINE}" \
    "JAVA_HOME=${JAVA_HOME%/}"
fi
```

Two properties matter. It refuses to write **either** key when **either** is empty, rather than recording half a pair. And it is followed by a read-back from the file — `grep -E '^(export )?…' reimage.env` — rather than a re-print of the shell variables that were just written, because those two can disagree.

`JAVA_HOME` is the one key that must never be present-but-empty rather than absent. Unlike the `REIMAGE_*` keys, the shell and every JVM tool already read it, so `export JAVA_HOME=` overwrites a working value with an empty string the moment `reimage.env` is sourced.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Optional Keys and All-or-Nothing Groups

Three shapes, and they are not interchangeable:

### `LOCAL_` and `GIT_` are not the same kind of key

`LOCAL_WORK_REPO_ROOT` and `LOCAL_PERSONAL_REPO_ROOT` are **directories on this
Mac** — where clones land, and what `includeIf` matches on to decide which
identity authors a commit. They are also the two keys that may legitimately hold
different values before and after a reimage, because where repositories live is a
choice the rebuild gets to remake.

Every remaining `GIT_*` key describes Git or GitHub itself: an identity, an SSH
key, a routing host, a default branch, an account that owns repositories. Those
are the same on any machine that authenticates as you.

The prefix is the question each key answers — *where on disk* against *who am I
and where do I push*. A path named `GIT_` invites the reading that it is
something GitHub knows about, which is how it came to sound like a remote rather
than a folder.

| Shape | Meaning | Example |
|---|---|---|
| Required | The step refuses to write without it. | `GIT_WORK_EMAIL`, `LOCAL_WORK_REPO_ROOT` |
| Optional | Blank is a decision with a defined meaning. | `GIT_PERSONAL_GITHUB_OWNER` — blank means *never rewrite a clone URL*; `GIT_PERSONAL_GITHUB_HOSTNAME` — blank means *`HostName` inherits the `Host` value* |
| All-or-nothing group | Fill every member or leave every member blank. Half a group is never right. | The four `GIT_PERSONAL_*` identity keys, together with `LOCAL_PERSONAL_REPO_ROOT` |

The personal Git group is the worked example. A Mac with no separate personal identity leaves all five blank, and that is a `PASS` at every bookend. A half-filled group is what fails quietly: an identity with no root leaves `restore-git.md` Step 5's override at `/.gitconfig`, and a root with no identity clones into a directory `includeIf` never matches, so those commits land under the **work** identity and nothing reports it until someone else notices the author line.

Both directions are checked — in `check_restore_git()` in `bin/record-restore-exit.sh`, and again in `check_restore_repos()` in `bin/record-restore-prereqs.sh`.

`GIT_PERSONAL_GITHUB_HOSTNAME` is written by the same step and belongs to the same runbook, but deliberately **not** to that group. Blank is its normal value on most Macs and means `HostName` inherits whatever `GIT_PERSONAL_GITHUB_HOST` holds, which is correct whenever the two identities sit on different servers. It is filled only when that host is an alias — two accounts on one server, where a single `Host` block cannot carry two keys. Adding it to the all-or-nothing group would fail every correctly configured Mac that has no alias.

Optional does not mean unchecked. `check_restore_git()` reads the `Host` block back out of `~/.ssh/config` and compares its `HostName` against what `reimage.env` says it should be, so the failure the key exists to prevent — an alias with nothing real behind it, where `Host` and `HostName` are the same unresolvable name — is caught whether or not the key is set.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Where a Key Gets Checked

A phase has two bookends, and a key belongs to exactly one of them.

| Recorder | Asks | A key belongs here when |
|---|---|---|
| `bin/record-restore-prereqs.sh` (entry, Step 0a) | May this phase start? | An **earlier** phase wrote it. |
| `bin/record-restore-exit.sh` (exit, final step) | Did this phase do what it promised? | **This** phase wrote it. |

A row over a value the phase itself records can only ever fail at entry — a scheduled false alarm, and the mirror of the failure the entry recorder exists to prevent ("recording `PASS` for something nobody verified"). `restore-git`'s identity keys are checked at exit for exactly this reason; its entry bookend does not mention them.

The recorders overlap without duplicating. Where the same subject is checked on both sides it is renamed, not repeated — `restore-access` entry has *Identity SSH keys restored and tight*, its exit has *SSH private keys restored and tight*. One check per bookend; a phase never runs the next phase's entry check.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Adding a New Key

1. Decide which runbook **uses** it. That runbook owns it. If two do, the first one to use it owns it and the second documents it as read-only.
2. Add it to that runbook's *Artifact and Script Locations → Environment Variables* table, naming the step that writes it and whether it is required, optional, or part of an all-or-nothing group.
3. Write it in that step, with the guard above, followed by a read-back from the file.
4. Add a row to that phase's `check_*()` in `bin/record-restore-exit.sh`. Not to the entry recorder.
5. Add it to the catalog above.
6. Do **not** add it to `reimage.env.example`, and do not add it to `setup-reimage-env.sh`'s capture loop, unless `prepare-artifact-root.md` is the runbook that sets it.

[[#Table of Contents|⬆ Back to Table of Contents]]

---

## Owned Elsewhere

This reference says who owns each key and why. It does not duplicate the procedures.

| Topic | Owned by |
|---|---|
| Creating `reimage.env`, and the Phase 1 values | [[prepare-artifact-root\|prepare-artifact-root.md]] (Phase 1) |
| How `reimage.env` is found, carried across the erase, and reloaded | [[toolkit-environment-reference\|Toolkit Environment Reference]] |
| What belongs in `reimage.env` versus a workspace config fragment | [[artifact-config-reference\|Artifact Config Reference]] |
| `upsert-env` and the other `prepare-artifact-root.py` subcommands | [[reimaging-scripts-guide\|reimaging-scripts-guide.md]] |

[[#Table of Contents|⬆ Back to Table of Contents]]
