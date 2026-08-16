#!/usr/bin/env python3
"""
scan-stale-ignore-entries.py

Flag single-file .gitignore entries that no longer match anything on disk.

A .gitignore line naming one exact file — `src/test/http_tests/elastic.http`
rather than `src/test/http_tests/*.http` — stops working the moment that file is
renamed or moved. Git does not warn: the rule silently covers nothing, the file
silently stops being ignored, and this workflow silently stops backing it up
because it only ever sees ignored files. When the guarded file held credentials,
the same rename makes the secret tracked on the next commit.

Reads gitignore-pattern-sources.tsv produced by collect-gitignore-superset.sh,
so it costs no extra repository scan.

Usage:
  scan-stale-ignore-entries.py --sources-tsv PATH --out PATH

Exit status:
  0  Scan completed (stale entries are reported, not an error).
  2  Usage error or the sources TSV is unreadable.
"""
from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

# Substrings that mark a guarded file as credential-bearing. A stale entry here
# is a different severity: the file stops being ignored, not merely unbacked-up.
SECRET_MARKERS = (
    "cred", "secret", "token", "vault", ".env", "env.json",
    "key", "passw", "uaa", "auth",
)


def is_single_file_entry(pattern: str) -> bool:
    # Directory rules, globs, and negations all survive a rename; only entries
    # naming one literal file are fragile.
    if not pattern or pattern[0] in "!#":
        return False
    if pattern.endswith("/"):
        return False
    if any(ch in pattern for ch in "*?["):
        return False
    basename = pattern.rstrip("/").rsplit("/", 1)[-1]
    return "." in basename.lstrip(".") or "/" in pattern


def repo_root_of(source_path: str) -> Path:
    for marker in ("/.gitignore", "/.git/info/exclude"):
        if marker in source_path:
            return Path(source_path.split(marker)[0])
    return Path(source_path).parent


def pattern_matches_on_disk(repo: Path, pattern: str) -> bool:
    relative = pattern.lstrip("/")
    if "/" in pattern:
        return (repo / relative).exists()
    result = subprocess.run(
        ["find", str(repo), "-name", relative, "-not", "-path", "*/.git/*"],
        capture_output=True, text=True, check=False,
    )
    return bool(result.stdout.strip())


def scan(sources_tsv: Path) -> List[Tuple[str, str, str, str, str, str]]:
    # An entry matching nothing is not automatically stale. Most are preventive:
    # "ignore this if it ever appears". Thumbs.db on a Mac, the JetBrains .idea/*
    # boilerplate, Spring's HELP.md -- those are copied into many repos at once
    # and are expected to match nothing. An entry declared in exactly one repo is
    # the opposite: somebody added it for a file that was actually there. That
    # count is the discriminator, so it travels with every row.
    findings: List[Tuple[str, str, str, str, str, str]] = []
    with sources_tsv.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            pattern = row["normalized_pattern"].strip()
            if not is_single_file_entry(pattern):
                continue
            kind = "anchored" if "/" in pattern else "bare"
            secret = "yes" if any(m in pattern.lower() for m in SECRET_MARKERS) else "no"
            declared_in = row["source_count"].strip()
            for source in (s.strip() for s in row["sources"].split(";") if s.strip()):
                repo = repo_root_of(source)
                if not repo.is_dir():
                    continue
                if not pattern_matches_on_disk(repo, pattern):
                    findings.append((pattern, kind, secret, declared_in, repo.name, str(repo)))
    # Highest signal first: guards a secret, then declared in fewest repos.
    return sorted(findings, key=lambda f: (f[2] != "yes", int(f[3]), f[0], f[4]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources-tsv", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    if not args.sources_tsv.is_file():
        print(f"ERROR: sources TSV not found: {args.sources_tsv}", file=sys.stderr)
        print("       Run the default refresh first so the superset exists.", file=sys.stderr)
        return 2

    findings = scan(args.sources_tsv)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["pattern", "kind", "guards_secret", "declared_in", "repo", "repo_path"])
        writer.writerows(findings)

    # Review-worthy: declared in a single repo, so it was written for a file that
    # existed there rather than copied in as boilerplate.
    review = [f for f in findings if int(f[3]) == 1]
    secrets = sum(1 for f in review if f[2] == "yes")
    print(f"Single-file ignore entries matching nothing: {len(findings)}")
    print(f"  Worth reviewing (declared in one repo only): {len(review)}"
          f" -- {secrets} guarding credential-shaped files")
    print(f"  The remainder are declared across several repos and are almost")
    print(f"  certainly preventive rules, not stale ones.")
    print(f"Report: {args.out}")
    for pattern, _kind, secret, _n, repo, _path in review[:12]:
        print(f"  {'!' if secret == 'yes' else ' '} {repo:30s} {pattern}")
    if len(review) > 12:
        print(f"  ... {len(review) - 12} more review-worthy rows in the report")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
