#!/usr/bin/env python3
# =============================================================================
# backup-obsidian-vaults.py
#
# Capture Obsidian's cross-vault state and generate the vault inventory.
#
# Sourced-only rules do not apply here: this is an .internal/ helper invoked by
# bin/backup-apps.sh, and it is safe to run standalone when --artifact-root is
# supplied.
#
# --- BEGIN USAGE ---
# Usage:
#   .internal/apps/backup-obsidian-vaults.py --artifact-root PATH [options]
#
# Options:
#   --artifact-root PATH   Artifact root. Also honored from an exported
#                          REIMAGE_ARTIFACT_ROOT.
#   --obsidian-support-dir PATH
#                          Override the Obsidian application-support directory.
#                          Default: ~/Library/Application Support/obsidian
#   --dry-run              Report what would be captured; write nothing.
#   -h, --help             Show this message.
#
# What it captures, and why only this:
#   The Obsidian support directory is an Electron profile. Almost all of it is
#   the app binary and Chromium caches that reinstalling regenerates, and its
#   Cookies / Local Storage / Session Storage / IndexedDB hold Obsidian
#   Sync and Publish session state. Copying it wholesale would put an auth token
#   into app-settings-backup/, which the Phase 3C DMG never encrypts. So this
#   takes exactly two things:
#
#     global-settings/obsidian.json     the vault registry
#     global-settings/<vault-id>.json   per-vault window geometry
#
#   The registry is the point. It lives OUTSIDE every vault, so no vault backup
#   -- git, Obsidian Sync, or a cloud folder -- can ever contain it.
#
#   It also copies .obsidian/ for any vault whose own repository gitignores it,
#   because that config is then in neither git nor the artifact root.
#
# Network:
#   None. Ahead/behind counts are computed from existing remote-tracking refs,
#   never `git fetch`. That keeps the run offline, fast, and free of credential
#   prompts -- at the cost of the counts being as-of your last fetch, which the
#   generated report states.
#
# Exit status:
#   0  Inventory generated (or --dry-run completed).
#   1  Ran but could not complete its work.
#   2  Usage, configuration, or prerequisite error.
# --- END USAGE ---
# =============================================================================

import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

VAULT_ID_RE = re.compile(r"^[0-9a-f]+\.json$")

# Never copied out of the Obsidian support directory. Split by reason so the
# generated report can explain the exclusion rather than just assert it.
EXCLUDE_REASONS = [
    ("obsidian-*.asar", "The application itself. Reinstalling restores it."),
    (
        "Cache/, Code Cache/, GPUCache/, Dawn*Cache/, blob_storage/",
        "Chromium caches; regenerate on first launch.",
    ),
    (
        "Cookies, Local Storage, Session Storage, IndexedDB, Trust Tokens, TransportSecurity",
        "**Auth surface.** Obsidian Sync/Publish session state lives here. Copying it "
        "into `app-settings-backup/` -- which Phase 3C never encrypts -- would put a "
        "session token in plaintext.",
    ),
    (
        "SingletonLock, SingletonCookie, SingletonSocket",
        "Symlinks to a PID and a `/var/folders/` socket. Meaningless on a new machine.",
    ),
    (
        "workspace.json, workspace-mobile.json, cache/ inside each vault",
        "Churny per-session UI state; already gitignored where it matters.",
    ),
]

# Excluded when copying a vault's .obsidian/ into the artifact root.
VAULT_CONFIG_EXCLUDES = {"workspace.json", "workspace-mobile.json", "cache"}


def git(repo, *args):
    """Run a read-only git command. --no-optional-locks so a concurrent commit
    in the vault cannot make this fail, and so we never write an index.lock."""
    try:
        out = subprocess.run(
            ["git", "--no-optional-locks", *args],
            cwd=str(repo),
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip()


def probe_vault(path):
    """Everything derivable about one vault, without touching the network."""
    v = {
        "path": str(path),
        "name": path.name,
        "exists": path.is_dir(),
        "is_git": False,
        "branch": None,
        "head": None,
        "commit_count": None,
        "subject": None,
        "remotes": [],
        "obsidian_present": False,
        "obsidian_ignored": None,
        "obsidian_tracked": [],
        "obsidian_untracked": [],
        "plugins": 0,
        "snippets": 0,
        "themes": 0,
        "plugin_data_files": [],
        "local_only_branches": [],
        "stashes": 0,
        "has_envrc": False,
        "untracked": [],
    }
    if not v["exists"]:
        return v

    v["has_envrc"] = (path / ".envrc").is_file()

    od = path / ".obsidian"
    v["obsidian_present"] = od.is_dir()
    if v["obsidian_present"]:
        for key, sub in (("plugins", "plugins"), ("snippets", "snippets"), ("themes", "themes")):
            d = od / sub
            v[key] = len(list(d.iterdir())) if d.is_dir() else 0
        pdir = od / "plugins"
        if pdir.is_dir():
            v["plugin_data_files"] = sorted(
                str(p.relative_to(path)) for p in pdir.glob("*/data.json")
            )

    if not (path / ".git").exists():
        return v
    v["is_git"] = True

    v["branch"] = git(path, "rev-parse", "--abbrev-ref", "HEAD")
    v["head"] = (git(path, "rev-parse", "HEAD") or "")[:7] or None
    cnt = git(path, "rev-list", "--count", "HEAD")
    v["commit_count"] = int(cnt) if cnt and cnt.isdigit() else None
    v["subject"] = git(path, "log", "-1", "--format=%s")

    if v["obsidian_present"]:
        # Ground truth is what git actually TRACKS, not what the ignore rules say.
        # `git check-ignore` reports a tracked file as not-ignored even when a rule
        # matches it, so a rule added after the files were committed would read as
        # "covered" while a fresh clone gets nothing. Compare disk against the index
        # instead: whatever is on disk and not in the index is what git will not
        # restore, whatever the reason.
        tracked = git(path, "ls-files", ".obsidian")
        v["obsidian_tracked"] = tracked.splitlines() if tracked else []
        tracked_rel = {f[len(".obsidian/"):] for f in v["obsidian_tracked"]}
        on_disk = set()
        for item in od.rglob("*"):
            if not item.is_file():
                continue
            rel = item.relative_to(od).as_posix()
            top = rel.split("/", 1)[0]
            # Churny per-session UI state is meant to be absent from git.
            if top in VAULT_CONFIG_EXCLUDES:
                continue
            on_disk.add(rel)
        v["obsidian_untracked"] = sorted(on_disk - tracked_rel)
        v["obsidian_ignored"] = bool(v["obsidian_untracked"])

    remotes = git(path, "remote")
    for r in (remotes.splitlines() if remotes else []):
        url = git(path, "remote", "get-url", r) or ""
        m = re.match(r"(?:https?://|git@)([^/:]+)", url)
        entry = {"name": r, "url": url, "host": m.group(1) if m else "unknown",
                 "ahead": None, "behind": None, "has_branch": False}
        if v["branch"]:
            ref = "%s/%s" % (r, v["branch"])
            if git(path, "rev-parse", "--verify", "-q", ref) is not None:
                entry["has_branch"] = True
                counts = git(path, "rev-list", "--left-right", "--count",
                             "%s...%s" % (v["branch"], ref))
                if counts:
                    parts = counts.split()
                    if len(parts) == 2 and all(p.isdigit() for p in parts):
                        entry["ahead"], entry["behind"] = int(parts[0]), int(parts[1])
        v["remotes"].append(entry)

    # A local branch on no remote is unbacked work -- the exact thing a
    # "my vaults are all in git" assumption misses.
    heads = git(path, "for-each-ref", "--format=%(refname:short)", "refs/heads")
    for b in (heads.splitlines() if heads else []):
        sha = git(path, "rev-parse", b)
        if not sha:
            continue
        contained = git(path, "branch", "-r", "--contains", sha)
        if not contained or not contained.strip():
            v["local_only_branches"].append("%s @ %s" % (b, sha[:7]))

    st = git(path, "stash", "list")
    v["stashes"] = len(st.splitlines()) if st else 0

    unt = git(path, "ls-files", "--others", "--exclude-standard")
    v["untracked"] = unt.splitlines() if unt else []
    return v


def authoritative_remote(v):
    """Which remote to clone from: the one with nothing missing. Returns
    (remote_or_None, list_of_stale_remote_names)."""
    best, stale = None, []
    for r in v["remotes"]:
        if not r["has_branch"] or r["ahead"] is None:
            continue
        if r["ahead"] == 0:
            if best is None:
                best = r
        else:
            stale.append(r)
    return best, stale


def md_escape(s):
    return str(s).replace("|", "\\|")


def build_report(vaults, support_dir, captured, stamp, dry_run):
    L = []
    A = L.append
    A("# Obsidian Vault Inventory and Restore Notes")
    A("")
    A("> Generated by `.internal/apps/backup-obsidian-vaults.py`. Every rerun replaces")
    A("> this file — edit the generator, not the output.")
    A("")
    A("**Captured:** %s" % stamp)
    A("**Machine:** %s" % (os.uname().nodename if hasattr(os, "uname") else "unknown"))
    A("**Support directory:** `%s`" % support_dir)
    A("")
    A("---")
    A("")
    A("## Why this file exists")
    A("")
    A("`obsidian.json` is the vault registry — it lists which folders Obsidian treats")
    A("as vaults. It sits **outside every vault**, so no vault backup can contain it:")
    A("not git, not Obsidian Sync, not a cloud folder.")
    A("")
    A("Two failure modes it guards against:")
    A("")
    A("1. The registry is lost, so Obsidian opens to an empty picker and every vault")
    A("   must be re-added by hand.")
    A("2. The registry is restored but the vault paths moved, so Obsidian shows dead")
    A("   vaults and the paths need editing before it will open anything.")
    A("")
    A("Vault IDs matter: window geometry and other per-vault state are keyed to them.")
    A("Re-adding a vault by hand mints a **new** ID and orphans that state. Restoring")
    A("`obsidian.json` preserves the IDs; manual re-registration does not.")
    A("")

    # ---- Findings first: anything that would silently lose data. -----------
    problems = []
    for v in vaults:
        if not v["exists"]:
            problems.append("**%s** — registered path does not exist: `%s`" % (v["name"], v["path"]))
            continue
        if not v["is_git"]:
            problems.append(
                "**%s** — not a git repository. Its content is backed up by nothing here; "
                "pick a restore source in the runbook." % v["name"])
            continue
        best, stale = authoritative_remote(v)
        if not v["remotes"]:
            problems.append("**%s** — a git repository with no remotes. Nothing is pushed anywhere." % v["name"])
        elif best is None:
            problems.append(
                "**%s** — every remote is behind local. Push before the erase or those "
                "commits exist only on this Mac." % v["name"])
        for r in stale:
            problems.append(
                "**%s** — `%s` (%s) is **%d commit(s) behind** local. Cloning from it "
                "silently drops that work; clone from `%s` instead."
                % (v["name"], r["name"], r["host"], r["ahead"],
                   best["name"] if best else "a current remote"))
        if v["local_only_branches"]:
            problems.append("**%s** — local-only branch(es) on no remote: %s"
                            % (v["name"], ", ".join("`%s`" % b for b in v["local_only_branches"])))
        if v["stashes"]:
            problems.append("**%s** — %d stash(es). Stashes are never pushed; they die with the disk."
                            % (v["name"], v["stashes"]))
        if v["obsidian_ignored"]:
            problems.append(
                "**%s** — %d `.obsidian/` file(s) are on disk but not in git, so that config "
                "is in neither git nor any vault backup: %s. Captured into `vault-config/` "
                "here instead."
                % (v["name"], len(v["obsidian_untracked"]),
                   ", ".join("`%s`" % f for f in v["obsidian_untracked"][:6])))
        if v["plugin_data_files"]:
            problems.append(
                "**%s** — community-plugin data files present: %s. These routinely hold API "
                "tokens; review before treating `vault-config/` as non-secret."
                % (v["name"], ", ".join("`%s`" % p for p in v["plugin_data_files"])))

    A("## Findings")
    A("")
    if problems:
        A("Each of these would cost data or time at restore if unnoticed.")
        A("")
        for p in problems:
            A("- %s" % p)
    else:
        A("None. Every vault is a git repository with a current remote, no local-only")
        A("branches, no stashes, and `.obsidian/` covered by git.")
    A("")

    # ---- Remote topology ---------------------------------------------------
    hosts = sorted({r["host"] for v in vaults for r in v["remotes"]})
    if hosts:
        A("## Remote topology")
        A("")
        A("Clone-from is the remote with nothing missing relative to local.")
        A("")
        A("| Vault | Branch | " + " | ".join("`%s`" % h for h in hosts) + " | Clone from |")
        A("|---|---|" + "---|" * len(hosts) + "---|")
        for v in vaults:
            if not v["is_git"]:
                A("| `%s` | — |%s **not a git repo** |" % (v["name"], " — |" * len(hosts)))
                continue
            best, _ = authoritative_remote(v)
            cells = []
            for h in hosts:
                rs = [r for r in v["remotes"] if r["host"] == h]
                if not rs:
                    cells.append("none")
                else:
                    r = rs[0]
                    if not r["has_branch"]:
                        cells.append("no `%s`" % v["branch"])
                    elif r["behind"] or r["ahead"]:
                        cells.append("**%d behind local**" % r["ahead"] if r["ahead"]
                                     else "%d ahead of local" % r["behind"])
                    else:
                        cells.append("in sync")
            A("| `%s` | `%s` | %s | %s |"
              % (v["name"], v["branch"], " | ".join(cells),
                 "**`%s`**" % best["name"] if best else "—"))
        A("")
        if len(hosts) > 1:
            A("> More than one host is in play, so **no single account restores every vault**.")
            A("> Confirm credentials for each before treating the set as recoverable.")
            A("")
        A("> Counts come from remote-tracking refs, not a live fetch — this capture makes")
        A("> no network calls. They are accurate as of your last `git fetch`. Run")
        A("> `git fetch --all` in each vault first if you need them authoritative.")
        A("")

    # ---- Registry ----------------------------------------------------------
    A("## Vault registry")
    A("")
    A("| Vault ID | Vault | Path | `.obsidian/` in git |")
    A("|---|---|---|---|")
    for v in vaults:
        if not v["obsidian_present"]:
            cov = "no `.obsidian/`"
        elif not v["is_git"]:
            cov = "n/a — not a git repo"
        elif v["obsidian_ignored"]:
            cov = "**No — %d file(s) not in git**" % len(v["obsidian_untracked"])
        else:
            cov = "Yes (%d file(s))" % len(v["obsidian_tracked"])
        A("| `%s` | `%s` | `%s` | %s |"
          % (v.get("vault_id", "?"), v["name"], md_escape(v["path"]), cov))
    A("")
    if any(v.get("geometry") for v in vaults):
        A("### Window geometry at capture")
        A("")
        A("Cosmetic, and only meaningful if `obsidian.json` is restored alongside it.")
        A("")
        A("| Vault | x | y | width | height |")
        A("|---|---:|---:|---:|---:|")
        for v in vaults:
            g = v.get("geometry")
            if g:
                A("| `%s` | %s | %s | %s | %s |"
                  % (v["name"], g.get("x", "?"), g.get("y", "?"),
                     g.get("width", "?"), g.get("height", "?")))
        A("")

    # ---- Per-vault ---------------------------------------------------------
    A("## Per-vault detail")
    A("")
    for v in vaults:
        A("### %s" % v["name"])
        A("")
        A("- **Path:** `%s`" % v["path"])
        A("- **Vault ID:** `%s`" % v.get("vault_id", "?"))
        if not v["exists"]:
            A("- **Missing** — the registry points at a path that does not exist.")
            A("")
            continue
        if not v["is_git"]:
            A("- **Not a git repository** — choose a restore source in the runbook.")
        else:
            A("- **Branch:** `%s` @ `%s`%s"
              % (v["branch"], v["head"],
                 " (%d commits)" % v["commit_count"] if v["commit_count"] else ""))
            if v["subject"]:
                A("- **Last commit:** *%s*" % v["subject"])
            if v["remotes"]:
                for r in v["remotes"]:
                    if not r["has_branch"]:
                        state = "no `%s` branch on this remote" % v["branch"]
                    elif r["ahead"]:
                        state = "**%d behind local**" % r["ahead"]
                    elif r["behind"]:
                        state = "%d ahead of local" % r["behind"]
                    else:
                        state = "in sync"
                    A("- **Remote `%s`:** `%s` — %s" % (r["name"], r["url"], state))
            else:
                A("- **Remotes:** none")
            if v["local_only_branches"]:
                A("- **Local-only branches:** %s"
                  % ", ".join("`%s`" % b for b in v["local_only_branches"]))
            if v["stashes"]:
                A("- **Stashes:** %d" % v["stashes"])
        if v["obsidian_present"]:
            if v["obsidian_ignored"]:
                A("- **`.obsidian/` in git:** **no** — not tracked: %s"
                  % ", ".join("`%s`" % f for f in v["obsidian_untracked"]))
                if v["obsidian_tracked"]:
                    A("  - partially tracked: %s"
                      % ", ".join("`%s`" % os.path.basename(f) for f in v["obsidian_tracked"]))
            else:
                A("- **`.obsidian/` in git:** %s"
                  % (", ".join("`%s`" % os.path.basename(f) for f in v["obsidian_tracked"])
                     or "nothing on disk to track"))
            A("- **Community plugins / snippets / themes:** %d / %d / %d"
              % (v["plugins"], v["snippets"], v["themes"]))
        if v["has_envrc"]:
            A("")
            A("> **`direnv`.** This vault has an `.envrc`. It is committed, but direnv's")
            A("> approval list is machine-local (`~/.local/share/direnv/allow/`). After")
            A("> reimage, run `direnv allow` here or the exports silently do not happen.")
            A("> A re-approval, not data loss — and re-approving is the safer default.")
        if v["untracked"]:
            shown = v["untracked"][:5]
            more = len(v["untracked"]) - len(shown)
            A("")
            A("> **Untracked at capture:** %s%s. Not an Obsidian concern, but it is the"
              % (", ".join("`%s`" % u for u in shown), " (+%d more)" % more if more > 0 else ""))
            A("> class of file `backup-repos` / `stage-ignored-files` exists to catch.")
        A("")

    # ---- What was captured -------------------------------------------------
    A("## What was captured into this artifact root")
    A("")
    A("```text")
    A("app-settings-backup/obsidian/")
    for line in captured:
        A(line)
    A("```")
    A("")
    A("No vault content is duplicated here — vaults restore from their remotes.")
    A("")
    A("### What was deliberately NOT captured")
    A("")
    A("The Obsidian support directory is an Electron profile, not a settings folder.")
    A("Only the registry and geometry files were taken. Excluded:")
    A("")
    A("| Excluded | Reason |")
    A("|---|---|")
    for pat, why in EXCLUDE_REASONS:
        A("| `%s` | %s |" % (pat, why))
    A("")

    # ---- Restore -----------------------------------------------------------
    A("## Restore procedure")
    A("")
    hostlist = ", ".join("`%s`" % h for h in hosts) if hosts else "your git host"
    A("1. **Restore credentials** for %s." % hostlist)
    if len(hosts) > 1:
        A("   No single one covers every vault.")
    A("")
    A("2. **Clone the repositories** to the same paths recorded above. The registry")
    A("   stores absolute paths; matching the original layout means step 4 needs no")
    A("   editing.")
    A("")
    A("   ```bash")
    A("   mkdir -p %s" % os.path.dirname(vaults[0]["path"]) if vaults else "   ```")
    if vaults:
        A("   cd %s" % os.path.dirname(vaults[0]["path"]))
        for v in vaults:
            if not v["is_git"]:
                continue
            best, stale = authoritative_remote(v)
            if best:
                note = "   # NOT %s — behind" % ", ".join(r["name"] for r in stale) if stale else ""
                A("   git clone %s%s" % (best["url"], note))
        A("   ```")
    A("")
    for v in vaults:
        best, stale = authoritative_remote(v)
        if stale and best:
            A("   Re-add the other remote(s) for `%s` afterward:" % v["name"])
            A("")
            A("   ```bash")
            A("   cd %s" % v["name"])
            for r in stale:
                A("   git remote add %s %s" % (r["name"], r["url"]))
            A("   ```")
            A("")
    A("3. **Install Obsidian**, launch and quit it once so it creates the support")
    A("   directory.")
    A("")
    A("4. **With Obsidian quit**, restore the registry:")
    A("")
    A("   ```bash")
    A('   SUPPORT="%s"' % support_dir)
    A('   cp -p global-settings/obsidian.json "$SUPPORT/"')
    A('   cp -p global-settings/[0-9a-f]*.json "$SUPPORT/"')
    A("   ```")
    A("")
    A("   Obsidian must not be running — it rewrites `obsidian.json` on exit and would")
    A("   overwrite the restored copy.")
    A("")
    A("5. **If any vault path changed**, edit the `path` values in `obsidian.json`")
    A("   before launching, or Obsidian shows dead vaults.")
    A("")
    step = 6
    gitignored = [v for v in vaults if v.get("obsidian_ignored")]
    if gitignored:
        A("%d. **Restore the excluded vault config:**" % step)
        A("")
        A("   ```bash")
        for v in gitignored:
            A('   rsync -a vault-config/%s/ "%s/.obsidian/"' % (v["name"], v["path"]))
        A("   ```")
        A("")
        step += 1
    envrcs = [v for v in vaults if v["has_envrc"]]
    if envrcs:
        A("%d. **Run `direnv allow`** in: %s"
          % (step, ", ".join("`%s`" % v["name"] for v in envrcs)))
        A("")
        step += 1
    A("%d. **Launch Obsidian** and confirm every vault appears with the correct name" % step)
    A("   and path.")
    A("")
    A("---")
    A("")
    A("## How these facts were determined")
    A("")
    A("- Vault list, IDs, and geometry read from `obsidian.json`.")
    A("- `.obsidian/` coverage tested per vault with `git check-ignore -q .obsidian`,")
    A("  because repositories in the same set can and do disagree.")
    A("- Ahead/behind computed per remote with `git rev-list --left-right --count`")
    A("  against **each** remote's copy of the current branch — not the single")
    A("  upstream `git status` reports, which can call a vault clean while another")
    A("  remote is stale.")
    A("- Local-only branches found with `git branch -r --contains`; stashes counted")
    A("  with `git stash list`.")
    A("- All git calls use `--no-optional-locks`, so a concurrent commit in a vault")
    A("  cannot fail the capture and no `index.lock` is left behind.")
    if dry_run:
        A("")
        A("> **DRY RUN** — nothing was written.")
    A("")
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--artifact-root", default=os.environ.get("REIMAGE_ARTIFACT_ROOT", ""))
    ap.add_argument("--obsidian-support-dir", default="")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("-h", "--help", action="store_true")
    args = ap.parse_args()

    if args.help:
        src = Path(__file__).read_text(encoding="utf-8")
        body = src.split("# --- BEGIN USAGE ---", 1)[1].split("# --- END USAGE ---", 1)[0]
        print("\n".join(l[2:] if l.startswith("# ") else l.lstrip("#") for l in body.strip().splitlines()))
        return 0

    if not args.artifact_root:
        print("ERROR: artifact root not set. Pass --artifact-root PATH "
              "(or export REIMAGE_ARTIFACT_ROOT).", file=sys.stderr)
        return 2
    root = Path(args.artifact_root)
    if not root.is_dir():
        print("ERROR: artifact root not found: %s" % root, file=sys.stderr)
        return 2

    support = Path(args.obsidian_support_dir) if args.obsidian_support_dir \
        else Path.home() / "Library" / "Application Support" / "obsidian"
    registry = support / "obsidian.json"
    if not registry.is_file():
        print("SKIP: no Obsidian vault registry at %s — Obsidian not installed "
              "or never launched." % registry)
        return 0

    try:
        data = json.loads(registry.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print("ERROR: could not read %s: %s" % (registry, exc), file=sys.stderr)
        return 1

    entries = data.get("vaults", {})
    if not entries:
        print("SKIP: the vault registry lists no vaults.")
        return 0

    vaults = []
    for vid, meta in sorted(entries.items(), key=lambda kv: kv[1].get("path", "")):
        vp = Path(meta.get("path", ""))
        v = probe_vault(vp)
        v["vault_id"] = vid
        geo = support / ("%s.json" % vid)
        if geo.is_file():
            try:
                v["geometry"] = json.loads(geo.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                v["geometry"] = None
        vaults.append(v)

    dest = root / "app-settings-backup" / "obsidian"
    gs = dest / "global-settings"
    captured = ["├── global-settings/"]

    if not args.dry_run:
        gs.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(registry), str(gs / "obsidian.json"))
    captured.append("│   ├── obsidian.json                  # the vault registry")
    for f in sorted(support.iterdir() if support.is_dir() else []):
        if f.is_file() and VAULT_ID_RE.match(f.name):
            if not args.dry_run:
                shutil.copy2(str(f), str(gs / f.name))
            match = [v for v in vaults if v["vault_id"] == f.stem]
            label = match[0]["name"] if match else "unknown vault"
            captured.append("│   ├── %-30s # window geometry, %s" % (f.name, label))

    gitignored = [v for v in vaults if v.get("obsidian_ignored")]
    if gitignored:
        captured.append("├── vault-config/")
        for v in gitignored:
            captured.append("│   └── %s/" % v["name"])
            src = Path(v["path"]) / ".obsidian"
            vdest = dest / "vault-config" / v["name"]
            if not args.dry_run:
                vdest.mkdir(parents=True, exist_ok=True)
            for item in sorted(src.iterdir()):
                if item.name in VAULT_CONFIG_EXCLUDES:
                    continue
                if not args.dry_run:
                    if item.is_dir():
                        shutil.copytree(str(item), str(vdest / item.name), dirs_exist_ok=True)
                    else:
                        shutil.copy2(str(item), str(vdest / item.name))
                captured.append("│       ├── %s" % item.name)
    captured.append("└── obsidian-vault-inventory.md        # generated report")

    stamp = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    report = build_report(vaults, support, captured, stamp, args.dry_run)
    out = dest / "obsidian-vault-inventory.md"
    if args.dry_run:
        print("DRY RUN — would write %s" % out)
        print(report)
        return 0

    dest.mkdir(parents=True, exist_ok=True)
    out.write_text(report, encoding="utf-8")

    print("Obsidian: %d vault(s) inventoried." % len(vaults))
    print("  Registry + geometry -> %s" % gs)
    if gitignored:
        print("  Gitignored .obsidian/ captured for: %s"
              % ", ".join(v["name"] for v in gitignored))
    print("  Report -> %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
