#!/usr/bin/env python3
"""
generate-mapping-template.py

Generate a small mapping JSON for update-references.py from a selected set of
source files. Intended for iterative migration: produce a mapping with only the
selected entries so you can review and run the updater in dry-run mode.

Usage example:

python3 .internal/scripts/generate-mapping-template.py \
  /path/to/reference-vault/workflows/mac/reimage/backup-apps.md \
  /path/to/reference-vault/workflows/mac/reimage/scripts/backup-apps.sh \
  --default-md-dir references \
  --out .internal/mappings/one-mapping.json

Options
- sources: one or more source file paths (posix or absolute)
- --default-md-dir: destination dir for Markdown files (default: references)
- --script-default-bin-dir: destination dir for non-helper scripts (default: bin)
- --script-helper-keyword: path segment indicating helper scripts (default: helpers)
- --out: output mapping JSON path (default: .internal/mappings/generated-mapping.json)
- --repo-root: repo root to use for proposed relative targets (default: current working dir)

Behavior
- For Markdown (.md): propose target as <default-md-dir>/<basename>
- For script files (.sh, .py): if the source path contains the helper keyword
  (e.g., scripts/helpers/) propose a target under .internal/ preserving subpath
  after the helper keyword; otherwise propose a target under bin/<basename>.
- Mapping keys are relative to the common parent of all provided sources when
  possible; otherwise mapping keys use basenames to avoid collisions.

"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import List


def common_parent(paths: List[Path]) -> Path:
    if not paths:
        return Path('.')
    parts = [p.resolve().parts for p in paths]
    # find common prefix
    prefix = []
    for items in zip(*parts):
        if all(x == items[0] for x in items):
            prefix.append(items[0])
        else:
            break
    if not prefix:
        return Path('.')
    return Path(*prefix)


def propose_target_for_source(src: Path, md_dir: str, bin_dir: str, helper_keyword: str, repo_root: Path) -> str:
    s = src
    suffix = s.name
    low = s.suffix.lower()
    if low == '.md':
        target = Path(md_dir) / suffix
        return target.as_posix()

    if low in {'.sh', '.py'}:
        parts = [p.lower() for p in s.parts]
        if helper_keyword.lower() in parts:
            # preserve subpath after the helper keyword under .internal
            try:
                idx = parts.index(helper_keyword.lower())
                after = Path(*s.parts[idx + 1:])
                target = Path('.internal') / after
                return target.as_posix()
            except ValueError:
                pass
        # default to bin/
        target = Path(bin_dir) / suffix
        return target.as_posix()

    # fallback: put under md_dir as file
    return (Path(md_dir) / suffix).as_posix()


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description='Generate a small mapping JSON for update-references.py')
    parser.add_argument('sources', nargs='+', help='Source files to include in the mapping')
    parser.add_argument('--default-md-dir', default='references', help='Destination dir for markdown files (default: references)')
    parser.add_argument('--script-default-bin-dir', default='bin', help='Destination dir for scripts (default: bin)')
    parser.add_argument('--script-helper-keyword', default='helpers', help='Path segment indicating helper scripts (default: helpers)')
    parser.add_argument('--out', default='.internal/mappings/generated-mapping.json', help='Output mapping JSON path')
    parser.add_argument('--repo-root', default='.', help='Repository root for relative target resolution')

    args = parser.parse_args(argv)

    src_paths = [Path(p) for p in args.sources]
    repo_root = Path(args.repo_root)

    parent = common_parent(src_paths)

    mapping = {}
    seen_targets = set()

    for src in src_paths:
        if not src.exists():
            print(f'Warning: source does not exist (will still include): {src}')
        # mapping key: path relative to common parent when possible, else basename
        try:
            key = src.resolve().relative_to(parent.resolve()).as_posix()
        except Exception:
            key = src.name
        target = propose_target_for_source(src, args.default_md_dir, args.script_default_bin_dir, args.script_helper_keyword, repo_root)

        # avoid collisions: if target already seen, append numeric suffix
        base = Path(target)
        final_target = base
        i = 1
        while final_target.as_posix() in seen_targets:
            final_target = base.with_name(f"{base.stem}-{i}{base.suffix}")
            i += 1
        mapping[key] = final_target.as_posix()
        seen_targets.add(final_target.as_posix())

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(mapping, indent=2), encoding='utf-8')

    print(f'Wrote mapping with {len(mapping)} entries to {out_path}')
    print('Run the updater in dry-run to preview changes:')
    print(f'python3 .internal/scripts/update-references.py --dir references --mapping {out_path} --repo-root .')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
