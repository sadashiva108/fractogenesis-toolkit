#!/usr/bin/env python3
"""Scan a set of git repos for ignored files and classify them into review feeds.

Reconstruction of the original (uncommitted) gitignore-review generator. For each
repo it runs:

    git -C <repo> ls-files --others --ignored --exclude-standard --directory

and buckets every ignored path using the SAME SECRET_RE / GENERATED_RE rules the
rest of this workflow uses (lifted from split-gitignore-review-template.py), then
writes the feed TSVs.

The Phase 3B cert/Keychain plan (prepare-certs-keychain-staging.py) consumes three
of these:
    gitignored-secret-candidates.tsv
    gitignored-secret-candidates-refined.tsv
    gitignored-selected-nonsecret-candidates.tsv

Fidelity notes:
  - secret / secret-refined / generated-or-bulk / possibly-important buckets are
    reproduced from the shared regexes.
  - exclude-candidates is a best-effort OS/editor-junk split.
  - selected-nonsecret: when --nonsecret-template is supplied, it is derived from
    the [x]-checked patterns in gitignore-review-template.direct-nonsecret-recommended.txt
    (the human-curated "keep these non-secret ignored files" list). Without a
    template it falls back to a possibly-important + exclude seed for you to prune.
  - generated-or-bulk paths are collapsed to their first generated directory
    segment (e.g. .../.venv/lib/python3.14/... -> .../.venv/) and de-duplicated,
    so bulk trees are not enumerated child-by-child.
  - ignored-files-current-directory-mode is the full flat list (best-effort
    interpretation of the original "current directory mode").

Usage:
  scan-gitignored-candidates.py --out-dir DIR (--repos-file FILE | --root DIR ...)
                                [--nonsecret-template FILE]
"""
from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
from pathlib import Path
from typing import List, Tuple

# --- Classification rules (from split-gitignore-review-template.py) -----------
# NOTE: the two former explicit `.env.json` alternations (http-client.env.json,
# elastic-creds.env.json) are folded into the single `(^|/)[^/]*\.env\.json$`
# rule below. That one authoritative pattern catches every *.env.json file --
# including http-client.private.env.json, which the old explicit list missed.
SECRET_RE = re.compile(
    r"("
    r"(^|/)\.env($|\.|/)|"
    r"(^|/)[^/]*\.env\.json$|"
    r"vault\.env$|"
    r"reimage\.env$|"
    r"credentials|"
    r"secret|token|password|passwd|"
    r"application-local|application-ncube-client|application-uaa|"
    r"gradle-local\.properties|"
    r"docker/\.env\.local|/docker/\.env\.local|"
    r"\.keystore$|"
    r"\.pem$|\.key$|"
    r"\.ssh/|"
    r"id_ed25519|id_rsa"
    r")",
    re.IGNORECASE,
)

GENERATED_RE = re.compile(
    r"("
    r"node_modules/|"
    r"(^|/)build/?$|(^|/)build/|"
    r"target/|"
    r"\.gradle/?$|\.gradle/|"
    r"\.cache/|"
    r"\.venv/?$|\.venv/|"
    r"\.venv313/|\.venv314/|"
    r"venv/?$|venv/|"
    r"__pycache__/|"
    r"\.pyc$|"
    r"site-packages/|"
    r"\.DS_Store|"
    r"\.idea/shelf/|"
    r"\.idea/httpRequests/"
    r")",
    re.IGNORECASE,
)

# OS/editor micro-junk that belongs on an exclude list rather than a backup.
EXCLUDE_RE = re.compile(r"(\.DS_Store$|(^|/)\._|Thumbs\.db$|\.Spotlight-|\.Trashes)", re.IGNORECASE)

# First path segment of a wholly-generated tree. Any ignored path whose Nth
# component matches one of these is collapsed to that component (see
# collapse_generated) so bulk directories are represented by a single row.
COLLAPSE_DIRS = frozenset(
    {"node_modules", "target", ".gradle", ".cache", "venv",
     "__pycache__", "site-packages", "build"}
)


def read_repos(repos_file: str | None, roots: List[str] | None) -> List[Path]:
    repos: List[Path] = []
    if repos_file:
        for line in Path(repos_file).read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if s and not s.startswith("#"):
                repos.append(Path(s).expanduser())
    for root in roots or []:
        base = Path(root).expanduser()
        for dotgit in base.rglob(".git"):
            if dotgit.is_dir():
                repos.append(dotgit.parent)
    # de-dup, keep order, keep only existing dirs
    seen: set[str] = set()
    out: List[Path] = []
    for r in repos:
        key = str(r)
        if key not in seen and r.is_dir():
            seen.add(key)
            out.append(r)
    return out


def load_selected_patterns(template: str | None) -> List[str]:
    """Return the [x]-checked, non-negated patterns from the direct-nonsecret template."""
    if not template:
        return []
    pats: List[str] = []
    for line in Path(template).expanduser().read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if s[:3].lower() == "[x]":
            pat = s[3:].strip()
            if pat and not pat.startswith("!"):
                pats.append(pat)
    return pats


def list_ignored(repo: Path) -> List[Tuple[str, str]]:
    """Return (ignored_path, kind) rows for one repo; kind is 'dir' or 'file'."""
    try:
        res = subprocess.run(
            ["git", "-C", str(repo), "ls-files", "--others", "--ignored",
             "--exclude-standard", "--directory"],
            capture_output=True, text=True, check=False,
        )
    except OSError:
        return []
    rows: List[Tuple[str, str]] = []
    for line in res.stdout.splitlines():
        p = line.strip()
        if not p:
            continue
        rows.append((p, "dir" if p.endswith("/") else "file"))
    return rows


def bucket(path: str) -> str:
    """secret | exclude | generated | important (checked in priority order)."""
    if SECRET_RE.search(path):
        return "secret"
    if EXCLUDE_RE.search(path):
        return "exclude"
    if GENERATED_RE.search(path):
        return "generated"
    return "important"


def collapse_generated(path: str) -> str:
    """Truncate a path to its first generated directory segment.

    .venv (and .venv313/.venv314) are matched by prefix so every virtualenv
    variant collapses; the rest match exactly against COLLAPSE_DIRS.
    """
    parts = path.split("/")
    for i, comp in enumerate(parts):
        c = comp.lower()
        if c in COLLAPSE_DIRS or c.startswith(".venv"):
            return "/".join(parts[: i + 1]) + "/"
    return path


def matches_selected(path: str, patterns: List[str]) -> bool:
    """True if an ignored path matches any [x]-checked non-secret pattern."""
    pn = path.rstrip("/")
    for pat in patterns:
        p = pat.rstrip("/")
        if not p:
            continue
        if fnmatch.fnmatch(pn, p):
            return True
        if pn == p or pn.startswith(p + "/"):
            return True
        if fnmatch.fnmatch(pn, "*/" + p):
            return True
        if p.endswith("/*"):
            base = p[:-2]
            if pn == base or pn.startswith(base + "/"):
                return True
    return False


def write_tsv(path: Path, rows: List[Tuple[str, str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        f.write("repo\tignored_path\tkind\n")
        for repo, p, kind in rows:
            f.write(f"{repo}\t{p}\t{kind}\n")


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Scan repos for ignored files and classify into review feeds.")
    ap.add_argument("--out-dir", required=True, help="Directory to write the feed TSVs into.")
    ap.add_argument("--repos-file", help="File with one repo root per line (repos-for-ignored-scan.txt).")
    ap.add_argument("--root", action="append", help="Discover git repos under this root (repeatable).")
    ap.add_argument("--nonsecret-template",
                    help="gitignore-review-template.direct-nonsecret-recommended.txt; its [x]-checked "
                         "patterns drive the selected-nonsecret feed.")
    args = ap.parse_args(argv)

    repos = read_repos(args.repos_file, args.root)
    if not repos:
        raise SystemExit("No git repos to scan. Pass --repos-file or --root.")

    selected_patterns = load_selected_patterns(args.nonsecret_template)

    out = Path(args.out_dir).expanduser()
    out.mkdir(parents=True, exist_ok=True)

    # collect: (repo, path, kind, bucket)
    scanned: List[Tuple[str, str, str, str]] = []
    for repo in repos:
        for p, kind in list_ignored(repo):
            scanned.append((str(repo), p, kind, bucket(p)))

    def rows(pred) -> List[Tuple[str, str, str]]:
        return [(r, p, k) for (r, p, k, b) in scanned if pred(b, p)]

    secret = rows(lambda b, p: b == "secret")
    # refined = secret candidates that are NOT generated noise (drops __pycache__/.pyc/venv secrets)
    refined = [(r, p, k) for (r, p, k, b) in scanned if b == "secret" and not GENERATED_RE.search(p)]
    exclude = rows(lambda b, p: b == "exclude")
    important = rows(lambda b, p: b == "important")

    # generated-or-bulk: collapse each path to its first generated dir segment,
    # then de-duplicate so bulk trees are one row, not thousands.
    generated: List[Tuple[str, str, str]] = []
    gen_seen: set[Tuple[str, str]] = set()
    for (r, p, k, b) in scanned:
        if b != "generated":
            continue
        cp = collapse_generated(p)
        key = (r, cp)
        if key in gen_seen:
            continue
        gen_seen.add(key)
        generated.append((r, cp, "dir" if cp.endswith("/") else k))

    # selected-nonsecret: derive from the direct-nonsecret template's checked
    # patterns when available; otherwise fall back to a review seed.
    if selected_patterns:
        selected_nonsecret = [
            (r, p, k) for (r, p, k, b) in scanned
            if b != "secret" and matches_selected(p, selected_patterns)
        ]
    else:
        selected_nonsecret = important + exclude

    current_dir_mode = [(r, p, k) for (r, p, k, b) in scanned]

    feeds = {
        "gitignored-secret-candidates.tsv": secret,
        "gitignored-secret-candidates-refined.tsv": refined,
        "gitignored-selected-nonsecret-candidates.tsv": selected_nonsecret,
        "generated-or-bulk-ignored-paths.tsv": generated,
        "gitignored-exclude-candidates.tsv": exclude,
        "possibly-important-ignored-paths.tsv": important,
        "ignored-files-current-directory-mode.tsv": current_dir_mode,
    }
    for name, data in feeds.items():
        write_tsv(out / name, data)

    (out / "repos-for-ignored-scan.txt").write_text(
        "\n".join(str(r) for r in repos) + "\n", encoding="utf-8"
    )

    src = args.nonsecret_template if selected_patterns else "(seed: possibly-important + exclude)"
    print(f"Scanned {len(repos)} repos, {len(scanned)} ignored paths. Output: {out}")
    for name, data in feeds.items():
        print(f"  {len(data):5d}  {name}")
    print(f"      -  repos-for-ignored-scan.txt")
    print(f"  selected-nonsecret source: {src}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
