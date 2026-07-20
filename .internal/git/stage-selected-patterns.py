#!/usr/bin/env python3
"""
stage-selected-patterns.py

Stage files that match checked [x] entries from a gitignore review template,
with a post-dry-run exclude list, for backup review. Normally invoked by
bin/backup-repos.sh (--selected-dry-run / --selected-filtered-dry-run /
--selected-copy), but can be run standalone.

Exclude matching handles cases like:
  .idea/httpRequests/*
  .idea/httpRequests/
  **/.idea/httpRequests/**

Workflow:
  1. Mark patterns to include with [x] in gitignore-review-template.txt.
  2. Run this script without --copy for a dry run.
  3. Review candidates.tsv.
  4. Create backup-exclude-list.txt.
  5. Run again with --exclude-list.
  6. Run with --copy.

Examples:

  REIMAGE_ARTIFACT_ROOT="/Volumes/Data/reimage-backup-YYYYMMDD"

  # Dry run
  python3 stage-selected-patterns.py \
    --include-template "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
    --root ~/Development/IdeaProjects \
    --root ~/Development/Documentation \
    --dest "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun"

  # Filtered dry run
  python3 stage-selected-patterns.py \
    --include-template "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
    --exclude-list "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt" \
    --root ~/Development/IdeaProjects \
    --root ~/Development/Documentation \
    --dest "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/dryrun-filtered"

  # Final copy
  python3 stage-selected-patterns.py \
    --include-template "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/gitignore-review-template.txt" \
    --exclude-list "$REIMAGE_ARTIFACT_ROOT/gitignore-superset/backup-exclude-list.txt" \
    --root ~/Development/IdeaProjects \
    --root ~/Development/Documentation \
    --dest "$REIMAGE_ARTIFACT_ROOT/staged-ignored-files/live" \
    --copy

Exclude list examples:
  # Exclude a directory under any repo
  .idea/httpRequests/
  **/.idea/httpRequests/**

  # Exclude specific file patterns under any repo
  .idea/httpRequests/*.json
  **/.idea/httpRequests/*.json

  # Exclude by repo/path
  ese-policy-listener:.idea/httpRequests/
  ingestion-listener-http:.idea/httpRequests/*.json

  # Exclude by backup-relative path
  ese-policy-listener/.idea/httpRequests/
"""

from __future__ import annotations

import argparse
import csv
import fnmatch
import hashlib
import os
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple


DEFAULT_PRUNE_DIRS = {
    ".git",
    "node_modules",
    ".gradle",
    "target",
    "build",
    "dist",
    "dist-ssr",
    "out",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
}


@dataclass(frozen=True)
class Pattern:
    raw: str
    effective: str
    source_line: Optional[int] = None


@dataclass
class Candidate:
    abs_path: Path
    backup_label: str
    backup_rel_path: str
    backup_path: Path
    matched_scope: Path
    matched_patterns: List[str] = field(default_factory=list)
    secret_pattern: str = ""


def expand_path(value: str | Path) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(str(value)))).resolve()


def posix_rel(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def strip_checkbox(line: str) -> str:
    s = line.strip()
    if len(s) >= 3 and s[0] == "[" and s[2] == "]" and s[1].lower() in {"x", " "}:
        return s[3:].strip()
    return s


def normalize_template_pattern(raw: str) -> str:
    p = strip_checkbox(raw).strip()

    if not p or p.startswith("#"):
        return ""

    # A checked gitignore negation means "include files matching the unignored pattern".
    if p.startswith("!"):
        p = p[1:].strip()

    if p.startswith(r"\!"):
        p = "!" + p[2:]

    if p.startswith("./"):
        p = p[2:]

    return p.strip()


def read_checked_patterns(template_path: Path) -> List[Pattern]:
    patterns: List[Pattern] = []

    with template_path.open("r", encoding="utf-8", errors="replace") as f:
        for line_number, line in enumerate(f, start=1):
            stripped = line.strip()
            if not stripped:
                continue

            if not (stripped.startswith("[x]") or stripped.startswith("[X]")):
                continue

            effective = normalize_template_pattern(stripped)
            if effective:
                patterns.append(Pattern(raw=strip_checkbox(stripped), effective=effective, source_line=line_number))

    return dedupe_patterns(patterns)


def read_exclude_patterns(exclude_path: Optional[Path]) -> List[Pattern]:
    if not exclude_path:
        return []

    patterns: List[Pattern] = []

    with exclude_path.open("r", encoding="utf-8", errors="replace") as f:
        for line_number, line in enumerate(f, start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue

            # Support copying candidate rows from candidates.tsv.
            if "\t" in stripped:
                parts = stripped.split("\t")
                if parts[0] in {"backup_label", "abs_path"}:
                    continue
                if len(parts) >= 2 and parts[0] and parts[1]:
                    patterns.append(Pattern(raw=stripped, effective=f"{parts[0]}:{parts[1]}", source_line=line_number))
                    continue

            effective = normalize_template_pattern(stripped)
            if effective:
                patterns.append(Pattern(raw=strip_checkbox(stripped), effective=effective, source_line=line_number))

    return dedupe_patterns(patterns)


def dedupe_patterns(patterns: Iterable[Pattern]) -> List[Pattern]:
    seen: Set[str] = set()
    result: List[Pattern] = []
    for p in patterns:
        key = p.effective
        if key in seen:
            continue
        seen.add(key)
        result.append(p)
    return result


def split_components(rel: str) -> List[str]:
    return [part for part in rel.split("/") if part]


def path_is_under(rel: str, directory: str) -> bool:
    rel = rel.strip("/")
    directory = directory.strip("/")
    return rel == directory or rel.startswith(directory + "/") or rel.endswith("/" + directory) or f"/{directory}/" in f"/{rel}/"


def matches_gitignore_style(rel: str, pattern: str) -> bool:
    """
    Approximate gitignore-style matching.

    This favors finding/excluding too many matches rather than silently missing
    important local files or noisy excludes.
    """
    rel = rel.replace(os.sep, "/")
    if rel.startswith("./"):
        rel = rel[2:]
    basename = rel.rsplit("/", 1)[-1]

    p = pattern.strip().replace(os.sep, "/")
    if not p:
        return False

    if p.startswith("./"):
        p = p[2:]

    anchored = p.startswith("/")
    if anchored:
        p = p.lstrip("/")

    if not p:
        return False

    # Directory pattern: .idea/httpRequests/
    if p.endswith("/"):
        directory = p.rstrip("/")
        if anchored:
            return rel == directory or rel.startswith(directory + "/")
        return path_is_under(rel, directory)

    # Pattern ending with /**: .idea/httpRequests/** or **/.idea/httpRequests/**
    if p.endswith("/**"):
        directory = p[:-3].strip("/")
        if directory.startswith("**/"):
            directory = directory[3:]
        if anchored:
            return rel == directory or rel.startswith(directory + "/")
        return path_is_under(rel, directory)

    # Pattern ending with /*: .idea/httpRequests/*
    # Treat this as matching direct files and as a useful directory-content exclude.
    if p.endswith("/*"):
        directory = p[:-2].strip("/")
        if directory.startswith("**/"):
            directory = directory[3:]
        if anchored:
            return rel.startswith(directory + "/")
        if path_is_under(rel, directory):
            return True

    # Root anchored exact or glob.
    if anchored:
        return (
                rel == p
                or rel.startswith(p + "/")
                or fnmatch.fnmatchcase(rel, p)
                or fnmatch.fnmatchcase(rel, p + "/*")
                or fnmatch.fnmatchcase(rel, p + "/**")
        )

    # No slash means match basename or any path component.
    if "/" not in p:
        if fnmatch.fnmatchcase(basename, p):
            return True
        for component in split_components(rel):
            if fnmatch.fnmatchcase(component, p):
                return True
        return False

    # Slash-containing unanchored pattern. Try root-relative and anywhere-under.
    return (
            rel == p
            or rel.endswith("/" + p)
            or fnmatch.fnmatchcase(rel, p)
            or fnmatch.fnmatchcase(rel, "**/" + p)
            or fnmatch.fnmatchcase(rel, p + "/*")
            or fnmatch.fnmatchcase(rel, "**/" + p + "/*")
            or fnmatch.fnmatchcase(rel, p + "/**")
            or fnmatch.fnmatchcase(rel, "**/" + p + "/**")
    )


def matches_any(rel: str, patterns: List[Pattern]) -> List[Pattern]:
    return [p for p in patterns if matches_gitignore_style(rel, p.effective)]


def should_prune_dir(dirname: str, include_patterns: List[Pattern], include_heavy: bool) -> bool:
    if dirname == ".git":
        return True

    if include_heavy:
        return False

    if dirname not in DEFAULT_PRUNE_DIRS:
        return False

    # Do not prune a heavy/generated directory if explicitly selected.
    for p in include_patterns:
        effective = p.effective.strip("/")
        if effective == dirname:
            return False
        if effective.startswith(dirname + "/"):
            return False
        if f"/{dirname}/" in f"/{effective}/":
            return False
        if fnmatch.fnmatchcase(dirname, effective):
            return False

    return True


def find_git_roots(root: Path) -> List[Path]:
    git_roots: List[Path] = []

    for current, dirs, _files in os.walk(root):
        current_path = Path(current)

        if ".git" in dirs:
            git_roots.append(current_path.resolve())
            dirs.remove(".git")

    return sorted(set(git_roots), key=lambda p: str(p))


def idea_workspace_for_path(path: Path) -> Optional[Path]:
    parts = path.resolve().parts
    if "IdeaProjects" not in parts:
        return None

    idx = parts.index("IdeaProjects")
    if idx + 1 < len(parts):
        return Path(*parts[: idx + 2])

    return None


def discover_scopes(roots: List[Path]) -> List[Path]:
    scopes: Set[Path] = set()

    for root in roots:
        if not root.exists():
            continue

        root = root.resolve()
        scopes.add(root)

        if root.name == "IdeaProjects":
            for child in root.iterdir():
                if child.is_dir() and child.name != ".git":
                    scopes.add(child.resolve())

        workspace = idea_workspace_for_path(root)
        if workspace and workspace.exists():
            scopes.add(workspace.resolve())

        for git_root in find_git_roots(root):
            scopes.add(git_root.resolve())

            workspace = idea_workspace_for_path(git_root)
            if workspace and workspace.exists():
                scopes.add(workspace.resolve())

    return sorted(scopes, key=lambda p: (len(p.parts), str(p)))


def nearest_git_root_for_file(path: Path, git_roots: List[Path]) -> Optional[Path]:
    path = path.resolve()
    best: Optional[Path] = None

    for root in git_roots:
        try:
            path.relative_to(root)
        except ValueError:
            continue

        if best is None or len(root.parts) > len(best.parts):
            best = root

    return best


def make_label_map(scope_roots: List[Path]) -> Dict[Path, str]:
    by_name: Dict[str, List[Path]] = {}
    for root in scope_roots:
        by_name.setdefault(root.name, []).append(root)

    labels: Dict[Path, str] = {}
    used: Set[str] = set()

    for name, roots in by_name.items():
        if len(roots) == 1 and name not in used:
            labels[roots[0]] = name
            used.add(name)
            continue

        for root in roots:
            parent = root.parent.name or "root"
            digest = hashlib.sha1(str(root).encode("utf-8")).hexdigest()[:8]
            label = f"{root.name}__from__{parent}__{digest}"
            labels[root] = label
            used.add(label)

    return labels


def _pattern_matches_candidate(candidate: Candidate, ex: str) -> bool:
    """
    Single-pattern match against a candidate, checked in the same forms used
    throughout this script: exact match against label/rel/backup-rel/repo:rel/
    abs-path strings, repo:path form, backup-label/path form, absolute path
    glob, direct glob against the same string forms, and gitignore-style
    relative matches against both the scope-relative and backup-label-relative
    paths. Shared by candidate_excluded and candidate_matches_secrets so the
    matching rules only exist in one place.
    """
    abs_posix = candidate.abs_path.as_posix()
    rel = candidate.backup_rel_path.replace(os.sep, "/")
    label = candidate.backup_label
    backup_rel = f"{label}/{rel}"
    repo_colon = f"{label}:{rel}"
    test_paths = [rel, backup_rel, repo_colon, abs_posix]

    ex = ex.replace(os.sep, "/").strip()
    if not ex:
        return False

    if ex in {label, rel, backup_rel, repo_colon, abs_posix}:
        return True

    # repo:path form.
    if ":" in ex and not ex.startswith("/"):
        ex_label, ex_rel = ex.split(":", 1)
        if fnmatch.fnmatchcase(label, ex_label) and matches_gitignore_style(rel, ex_rel):
            return True

    # backup-label/path form.
    if "/" in ex:
        maybe_label, maybe_rel = ex.split("/", 1)
        if maybe_label == label and matches_gitignore_style(rel, maybe_rel):
            return True

    # Absolute path glob.
    if ex.startswith("/") and fnmatch.fnmatchcase(abs_posix, ex):
        return True

    # Direct glob against useful string forms.
    for value in test_paths:
        if fnmatch.fnmatchcase(value, ex):
            return True

    # Gitignore-style relative match against repo-relative path.
    if matches_gitignore_style(rel, ex):
        return True

    # Gitignore-style match against backup-label-relative path.
    if matches_gitignore_style(backup_rel, ex):
        return True

    return False


def candidate_matches_pattern_list(candidate: Candidate, patterns: List[Pattern]) -> Tuple[bool, str]:
    if not patterns:
        return False, ""

    for p in patterns:
        if _pattern_matches_candidate(candidate, p.effective):
            return True, p.raw

    return False, ""


def candidate_excluded(candidate: Candidate, exclude_patterns: List[Pattern]) -> Tuple[bool, str]:
    return candidate_matches_pattern_list(candidate, exclude_patterns)


def candidate_matches_secrets(candidate: Candidate, secrets_patterns: List[Pattern]) -> Tuple[bool, str]:
    """
    Checks a candidate against secrets-patterns.txt using the exact same
    matching forms as candidate_excluded. Returns (True, matched_pattern_raw)
    when the candidate looks secret-shaped, so it can be routed to the
    secrets-candidates/ bucket instead of the ordinary output tree.
    """
    return candidate_matches_pattern_list(candidate, secrets_patterns)


def write_tsv(path: Path, rows: List[Dict[str, str]], fieldnames: List[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage files matching checked [x] entries from a gitignore review template."
    )
    parser.add_argument("--include-template", required=True, help="Path to gitignore-review-template.txt.")
    parser.add_argument("--exclude-list", help="Optional list of patterns/paths to exclude after dry run review.")
    parser.add_argument("--secrets-patterns", help="Optional list of credential-shaped patterns. Matching files are routed to secrets-candidates/ instead of the ordinary output tree.")
    parser.add_argument("--root", action="append", required=True, help="Root directory to crawl. Can be passed multiple times.")
    parser.add_argument("--dest", required=True, help="Destination directory for dry-run reports or copied backup files.")
    parser.add_argument("--copy", action="store_true", help="Actually copy files. Without this, dry run only.")
    parser.add_argument("--include-heavy", action="store_true", help="Do not prune common heavy/generated folders.")
    parser.add_argument("--max-file-size-mb", type=float, default=0.0, help="Skip files larger than this many MB. 0 means no size limit.")
    args = parser.parse_args()

    include_template = expand_path(args.include_template)
    exclude_list = expand_path(args.exclude_list) if args.exclude_list else None
    secrets_patterns_path = expand_path(args.secrets_patterns) if args.secrets_patterns else None
    roots = [expand_path(r) for r in args.root]
    dest = expand_path(args.dest)

    if not include_template.is_file():
        print(f"ERROR: include template not found: {include_template}", file=sys.stderr)
        return 2

    if exclude_list and not exclude_list.is_file():
        print(f"ERROR: exclude list not found: {exclude_list}", file=sys.stderr)
        return 2

    if secrets_patterns_path and not secrets_patterns_path.is_file():
        print(f"ERROR: secrets patterns list not found: {secrets_patterns_path}", file=sys.stderr)
        return 2

    include_patterns = read_checked_patterns(include_template)
    exclude_patterns = read_exclude_patterns(exclude_list)
    secrets_patterns = read_exclude_patterns(secrets_patterns_path)

    if not include_patterns:
        print(f"ERROR: no checked [x] patterns found in {include_template}", file=sys.stderr)
        return 2

    dest.mkdir(parents=True, exist_ok=True)

    scopes = discover_scopes(roots)
    all_git_roots = sorted({g for root in roots for g in find_git_roots(root)}, key=lambda p: str(p))

    backup_roots = sorted(set(scopes + all_git_roots), key=lambda p: str(p))
    labels = make_label_map(backup_roots)

    candidates_by_abs: Dict[Path, Candidate] = {}
    secrets_candidates_by_abs: Dict[Path, Candidate] = {}
    excluded_rows: List[Dict[str, str]] = []
    skipped_rows: List[Dict[str, str]] = []

    max_bytes = int(args.max_file_size_mb * 1024 * 1024) if args.max_file_size_mb and args.max_file_size_mb > 0 else 0

    for scope in scopes:
        if not scope.exists():
            continue

        for current, dirs, files in os.walk(scope):
            current_path = Path(current).resolve()

            keep_dirs = []
            for d in dirs:
                d_path = current_path / d

                try:
                    d_path.resolve().relative_to(dest)
                    continue
                except ValueError:
                    pass

                if should_prune_dir(d, include_patterns, args.include_heavy):
                    continue

                keep_dirs.append(d)

            dirs[:] = keep_dirs

            for filename in files:
                abs_path = (current_path / filename).resolve()

                try:
                    rel_to_scope = posix_rel(abs_path, scope)
                except ValueError:
                    continue

                matched = matches_any(rel_to_scope, include_patterns)
                if not matched:
                    continue

                if not abs_path.exists() and not abs_path.is_symlink():
                    skipped_rows.append({
                        "reason": "missing",
                        "abs_path": abs_path.as_posix(),
                        "matched_scope": scope.as_posix(),
                        "matched_patterns": "; ".join(p.raw for p in matched),
                    })
                    continue

                if not abs_path.is_file() and not abs_path.is_symlink():
                    continue

                if max_bytes:
                    try:
                        size = abs_path.stat().st_size
                    except FileNotFoundError:
                        skipped_rows.append({
                            "reason": "missing_on_stat",
                            "abs_path": abs_path.as_posix(),
                            "matched_scope": scope.as_posix(),
                            "matched_patterns": "; ".join(p.raw for p in matched),
                        })
                        continue

                    if size > max_bytes:
                        skipped_rows.append({
                            "reason": f"larger_than_{args.max_file_size_mb}_mb",
                            "abs_path": abs_path.as_posix(),
                            "matched_scope": scope.as_posix(),
                            "matched_patterns": "; ".join(p.raw for p in matched),
                        })
                        continue

                nearest_repo = nearest_git_root_for_file(abs_path, all_git_roots)
                backup_root = nearest_repo or scope
                backup_label = labels.get(backup_root, backup_root.name)

                try:
                    backup_rel_path = posix_rel(abs_path, backup_root)
                except ValueError:
                    backup_rel_path = rel_to_scope

                backup_path = dest / backup_label / backup_rel_path

                existing = candidates_by_abs.get(abs_path) or secrets_candidates_by_abs.get(abs_path)
                if existing:
                    existing.matched_patterns.extend(p.raw for p in matched if p.raw not in existing.matched_patterns)
                    continue

                candidate = Candidate(
                    abs_path=abs_path,
                    backup_label=backup_label,
                    backup_rel_path=backup_rel_path,
                    backup_path=backup_path,
                    matched_scope=scope,
                    matched_patterns=[p.raw for p in matched],
                )

                is_excluded, exclude_reason = candidate_excluded(candidate, exclude_patterns)
                if is_excluded:
                    excluded_rows.append({
                        "backup_label": candidate.backup_label,
                        "backup_rel_path": candidate.backup_rel_path,
                        "abs_path": candidate.abs_path.as_posix(),
                        "exclude_pattern": exclude_reason,
                        "matched_patterns": "; ".join(candidate.matched_patterns),
                    })
                    continue

                is_secret, secret_pattern = candidate_matches_secrets(candidate, secrets_patterns)
                if is_secret:
                    # Route secret-shaped candidates apart from the ordinary
                    # output tree instead of adding them to candidates_by_abs,
                    # so a secret-shaped file never lands next to regular
                    # staged files in dryrun/dryrun-filtered/live output.
                    candidate.backup_path = dest / "secrets-candidates" / backup_label / backup_rel_path
                    candidate.secret_pattern = secret_pattern
                    secrets_candidates_by_abs[abs_path] = candidate
                    continue

                candidates_by_abs[abs_path] = candidate

    candidates = sorted(candidates_by_abs.values(), key=lambda c: (c.backup_label, c.backup_rel_path))
    secrets_candidates = sorted(secrets_candidates_by_abs.values(), key=lambda c: (c.backup_label, c.backup_rel_path))

    candidate_rows: List[Dict[str, str]] = []
    copied_rows: List[Dict[str, str]] = []
    copy_failed_rows: List[Dict[str, str]] = []

    secrets_candidate_rows: List[Dict[str, str]] = []
    secrets_copied_rows: List[Dict[str, str]] = []
    secrets_copy_failed_rows: List[Dict[str, str]] = []

    for c in candidates:
        try:
            size = c.abs_path.stat().st_size if c.abs_path.exists() else 0
        except OSError:
            size = 0

        row = {
            "backup_label": c.backup_label,
            "backup_rel_path": c.backup_rel_path,
            "abs_path": c.abs_path.as_posix(),
            "backup_path": c.backup_path.as_posix(),
            "size_bytes": str(size),
            "matched_scope": c.matched_scope.as_posix(),
            "matched_patterns": "; ".join(c.matched_patterns),
        }
        candidate_rows.append(row)

        if args.copy:
            try:
                c.backup_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(c.abs_path, c.backup_path, follow_symlinks=False)
                copied_rows.append(row)
            except FileNotFoundError:
                copy_failed_rows.append({**row, "reason": "missing_during_copy"})
            except OSError as e:
                copy_failed_rows.append({**row, "reason": f"copy_failed: {e}"})

    # Same shape as the loop above, kept separate rather than merged with a
    # branch inside it: secrets candidates carry an extra secret_pattern
    # column and write to their own TSVs, so the ordinary candidates.tsv
    # schema and copy behavior stay unchanged for callers that never pass
    # --secrets-patterns.
    for c in secrets_candidates:
        try:
            size = c.abs_path.stat().st_size if c.abs_path.exists() else 0
        except OSError:
            size = 0

        row = {
            "backup_label": c.backup_label,
            "backup_rel_path": c.backup_rel_path,
            "abs_path": c.abs_path.as_posix(),
            "backup_path": c.backup_path.as_posix(),
            "size_bytes": str(size),
            "matched_scope": c.matched_scope.as_posix(),
            "matched_patterns": "; ".join(c.matched_patterns),
            "secret_pattern": c.secret_pattern,
        }
        secrets_candidate_rows.append(row)

        if args.copy:
            try:
                c.backup_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(c.abs_path, c.backup_path, follow_symlinks=False)
                secrets_copied_rows.append(row)
            except FileNotFoundError:
                secrets_copy_failed_rows.append({**row, "reason": "missing_during_copy"})
            except OSError as e:
                secrets_copy_failed_rows.append({**row, "reason": f"copy_failed: {e}"})

    write_tsv(
        dest / "candidates.tsv",
        candidate_rows,
        [
            "backup_label",
            "backup_rel_path",
            "abs_path",
            "backup_path",
            "size_bytes",
            "matched_scope",
            "matched_patterns",
        ],
        )

    write_tsv(
        dest / "excluded.tsv",
        excluded_rows,
        ["backup_label", "backup_rel_path", "abs_path", "exclude_pattern", "matched_patterns"],
        )

    write_tsv(
        dest / "skipped.tsv",
        skipped_rows,
        ["reason", "abs_path", "matched_scope", "matched_patterns"],
        )

    if secrets_patterns:
        write_tsv(
            dest / "secrets-candidates.tsv",
            secrets_candidate_rows,
            [
                "backup_label",
                "backup_rel_path",
                "abs_path",
                "backup_path",
                "size_bytes",
                "matched_scope",
                "matched_patterns",
                "secret_pattern",
            ],
            )

    # Record the parsed exclude patterns so it is easy to verify the script read them.
    with (dest / "parsed-exclude-patterns.txt").open("w", encoding="utf-8") as f:
        for p in exclude_patterns:
            line_info = f"line {p.source_line}" if p.source_line else "line ?"
            f.write(f"{line_info}\t{p.effective}\t(raw: {p.raw})\n")

    if secrets_patterns:
        with (dest / "parsed-secrets-patterns.txt").open("w", encoding="utf-8") as f:
            for p in secrets_patterns:
                line_info = f"line {p.source_line}" if p.source_line else "line ?"
                f.write(f"{line_info}\t{p.effective}\t(raw: {p.raw})\n")

    if args.copy:
        write_tsv(
            dest / "copied.tsv",
            copied_rows,
            [
                "backup_label",
                "backup_rel_path",
                "abs_path",
                "backup_path",
                "size_bytes",
                "matched_scope",
                "matched_patterns",
            ],
            )
        write_tsv(
            dest / "copy-failed.tsv",
            copy_failed_rows,
            [
                "backup_label",
                "backup_rel_path",
                "abs_path",
                "backup_path",
                "size_bytes",
                "matched_scope",
                "matched_patterns",
                "reason",
            ],
            )

        if secrets_patterns:
            write_tsv(
                dest / "secrets-copied.tsv",
                secrets_copied_rows,
                [
                    "backup_label",
                    "backup_rel_path",
                    "abs_path",
                    "backup_path",
                    "size_bytes",
                    "matched_scope",
                    "matched_patterns",
                    "secret_pattern",
                ],
                )
            write_tsv(
                dest / "secrets-copy-failed.tsv",
                secrets_copy_failed_rows,
                [
                    "backup_label",
                    "backup_rel_path",
                    "abs_path",
                    "backup_path",
                    "size_bytes",
                    "matched_scope",
                    "matched_patterns",
                    "secret_pattern",
                    "reason",
                ],
                )

    summary = [
        "Selected Gitignore Staging Summary",
        "===================================",
        "",
        f"Mode:                  {'COPY' if args.copy else 'DRY RUN'}",
        f"Include template:      {include_template}",
        f"Exclude list:          {exclude_list if exclude_list else '<none>'}",
        f"Secrets patterns:      {secrets_patterns_path if secrets_patterns_path else '<none>'}",
        f"Destination:           {dest}",
        "",
        "Roots:",
        *[f"  - {r}" for r in roots],
        "",
        f"Scopes scanned:        {len(scopes)}",
        f"Git repos discovered:  {len(all_git_roots)}",
        f"Include patterns:      {len(include_patterns)}",
        f"Exclude patterns:      {len(exclude_patterns)}",
        f"Candidate files:       {len(candidate_rows)}",
        f"Excluded files:        {len(excluded_rows)}",
        f"Skipped files:         {len(skipped_rows)}",
    ]

    if secrets_patterns:
        summary.append(f"Secrets candidates:    {len(secrets_candidate_rows)}")

    if args.copy:
        summary.extend([
            f"Copied files:          {len(copied_rows)}",
            f"Copy failures:         {len(copy_failed_rows)}",
        ])
        if secrets_patterns:
            summary.extend([
                f"Secrets copied:        {len(secrets_copied_rows)}",
                f"Secrets copy failures: {len(secrets_copy_failed_rows)}",
            ])

    summary.extend([
        "",
        "Reports:",
        f"  {dest / 'candidates.tsv'}",
        f"  {dest / 'excluded.tsv'}",
        f"  {dest / 'skipped.tsv'}",
        f"  {dest / 'parsed-exclude-patterns.txt'}",
    ])

    if secrets_patterns:
        summary.extend([
            f"  {dest / 'secrets-candidates.tsv'}",
            f"  {dest / 'parsed-secrets-patterns.txt'}",
        ])

    if args.copy:
        summary.extend([
            f"  {dest / 'copied.tsv'}",
            f"  {dest / 'copy-failed.tsv'}",
        ])
        if secrets_patterns:
            summary.extend([
                f"  {dest / 'secrets-copied.tsv'}",
                f"  {dest / 'secrets-copy-failed.tsv'}",
            ])

    summary_text = "\n".join(summary) + "\n"
    (dest / "summary.txt").write_text(summary_text, encoding="utf-8")

    print(summary_text)

    if not args.copy:
        print("Dry run only. Review candidates.tsv and excluded.tsv, then rerun with --copy when ready.")
        if secrets_patterns:
            print("Secret-shaped matches were routed to secrets-candidates.tsv, kept apart from the ordinary candidates.")

    return 0 if not copy_failed_rows and not secrets_copy_failed_rows else 1


if __name__ == "__main__":
    raise SystemExit(main())
