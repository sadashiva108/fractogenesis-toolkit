#!/usr/bin/env python3
"""
update-references.py

CLI tool to update Markdown link targets across a tree of Markdown files using
an explicit mapping (old -> new). Intended for mechanical updates during
migration (e.g., moving runbooks into new names/locations) while preserving
human review.

Features
- Walk a target directory (default: references/) and find .md files
- Replace markdown link targets according to a mapping JSON file
  mapping.json format: {"old/path.md": "new/path.md", ...}
  Keys and values may be relative paths; script normalizes path tokens before matching.
- Shows unified diffs per-file and can output a combined patch file
- --dry-run (default) prints diffs without modifying files
- --apply writes changes in-place creating a .bak backup for each modified file
- Validates that mapped target exists (unless --force)

Usage examples

# Preview replacements under references/ using mapping.json
python3 .internal/scripts/update-references.py --dir references --mapping mapping.json

# Write a unified patch
python3 .internal/scripts/update-references.py --dir references --mapping mapping.json --patch out.patch

# Apply changes in-place (creates .bak files)
python3 .internal/scripts/update-references.py --dir references --mapping mapping.json --apply

Exit codes
- 0: ran successfully (no fatal errors). If no replacements found, still 0.
- non-zero: fatal error (bad mapping file, IO error)

Safety
- Dry-run by default. Use --apply only after reviewing diffs or patch output.

"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

LINK_RE = re.compile(r"(\[.*?\])\(([^)]+)\)")  # captures [text](target)


def load_mapping(path: Path) -> Dict[str, str]:
    text = path.read_text(encoding="utf-8")
    data = json.loads(text)
    norm: Dict[str, str] = {}
    for k, v in data.items():
        kk = Path(k).as_posix()
        vv = Path(v).as_posix()
        norm[kk] = vv
        # also add variants without leading ./
        if kk.startswith("./"):
            norm[kk[2:]] = vv
        if vv.startswith("./"):
            norm[kk] = vv[2:]
    return norm


def find_markdown_files(root: Path) -> List[Path]:
    return sorted([p for p in root.rglob("*.md") if p.is_file()])


def replace_links_in_text(text: str, mapping: Dict[str, str], file_path: Path) -> Tuple[str, List[Tuple[str, str, str]]]:
    """Return new_text and list of replacements as tuples (orig_target, new_target, link_snippet)"""
    replacements: List[Tuple[str, str, str]] = []

    def repl(m: re.Match) -> str:
        link_text = m.group(1)
        target = m.group(2)
        # split off optional anchor or title (e.g., path.md#anchor or path.md "title")
        # handle title in parentheses by looking for first space followed by quote - conservative
        target_only = target
        title_suffix = ""
        # If there's a space and then a quote, treat rest as title/attrs
        if ' "' in target or " '" in target:
            # conservative split: split at first space
            sp = target.find(" ")
            target_only = target[:sp]
            title_suffix = target[sp:]
        # split anchor
        if "#" in target_only:
            path_part, anchor = target_only.split("#", 1)
            anchor = "#" + anchor
        else:
            path_part = target_only
            anchor = ""

        norm_path = Path(path_part).as_posix()
        norm_path_nodot = norm_path[2:] if norm_path.startswith("./") else norm_path

        # if the mapping key matches either form, replace
        new_target = None
        if norm_path in mapping:
            new_target = mapping[norm_path]
        elif norm_path_nodot in mapping:
            new_target = mapping[norm_path_nodot]

        if new_target:
            # preserve anchor and title_suffix
            replaced = f"{link_text}({new_target}{anchor}{title_suffix})"
            replacements.append((path_part, new_target, m.group(0)))
            return replaced
        return m.group(0)

    new_text = LINK_RE.sub(repl, text)
    return new_text, replacements


def unified_diff(old: str, new: str, path: Path) -> str:
    old_lines = old.splitlines(keepends=True)
    new_lines = new.splitlines(keepends=True)
    diff = difflib.unified_diff(old_lines, new_lines, fromfile=str(path), tofile=str(path), lineterm="")
    return "\n".join(diff)


def validate_target_exists(repo_root: Path, target: str) -> bool:
    # target may be absolute, relative, or URL. If it starts with http:// or https:// or mailto:, skip validation.
    if target.startswith("http://") or target.startswith("https://") or target.startswith("mailto:"):
        return True
    # strip leading ./
    t = target[2:] if target.startswith("./") else target
    # ignore anchors
    t = t.split("#", 1)[0]
    p = (repo_root / t).resolve() if not Path(t).is_absolute() else Path(t)
    return p.exists()


def apply_changes(file_path: Path, new_text: str):
    backup = file_path.with_suffix(file_path.suffix + ".bak")
    shutil.copy2(file_path, backup)
    file_path.write_text(new_text, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Update Markdown link targets using an explicit mapping.")
    parser.add_argument("--dir", default="references", help="Target directory to scan for .md files (default: references)")
    parser.add_argument("--mapping", required=True, help="JSON file with mapping old->new paths")
    parser.add_argument("--repo-root", default=".", help="Repository root for existence checks (default: cwd)")
    parser.add_argument("--dry-run", action="store_true", help="Print diffs but do not modify files (default)")
    parser.add_argument("--apply", action="store_true", help="Apply changes in-place (creates .bak backups). Implies --dry-run false.")
    parser.add_argument("--patch", help="Write a combined unified diff patch to this file")
    parser.add_argument("--force", action="store_true", help="Apply replacements even if the new target does not exist")

    args = parser.parse_args()

    target_dir = Path(args.dir)
    repo_root = Path(args.repo_root)

    if not target_dir.exists():
        print(f"Error: target dir does not exist: {target_dir}")
        raise SystemExit(2)

    mapping = load_mapping(Path(args.mapping))
    if not mapping:
        print("Warning: mapping is empty.")

    files = find_markdown_files(target_dir)
    if not files:
        print("No markdown files found in target dir.")
        return

    all_diffs: List[str] = []
    any_replacements = False

    for f in files:
        src = f.read_text(encoding="utf-8")
        new_text, replacements = replace_links_in_text(src, mapping, f)
        if not replacements:
            continue

        # validate new targets
        bad_targets = []
        for old_t, new_t, snippet in replacements:
            # new_t may have anchor suffix in mapping value; check existence
            exists = validate_target_exists(repo_root, new_t)
            if not exists:
                bad_targets.append(new_t)

        if bad_targets and not args.force:
            print(f"Skipping {f} - mapped targets do not exist: {bad_targets} (use --force to override)")
            continue

        diff_text = unified_diff(src, new_text, f)
        if diff_text.strip() == "":
            continue

        any_replacements = True
        print(f"--- Diff for {f} ---")
        print(diff_text)
        all_diffs.append(diff_text)

        if args.apply:
            apply_changes(f, new_text)
            print(f"Applied changes to {f} (backup: {f.name}.bak)")

    if args.patch and all_diffs:
        patch_path = Path(args.patch)
        patch_path.write_text("\n\n".join(all_diffs), encoding="utf-8")
        print(f"Wrote patch to {patch_path}")

    if not any_replacements:
        print("No replacements performed.")


if __name__ == "__main__":
    main()
