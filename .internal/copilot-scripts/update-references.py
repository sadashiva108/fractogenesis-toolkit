#!/usr/bin/env python3
"""
update-references.py

CLI tool to update Markdown link targets and prose across a tree of Markdown
files using explicit mappings (old -> new). Intended for mechanical updates
during migration (e.g., moving runbooks into new names/locations) while
preserving manual review via a structured report.

Behavior and heuristics
- Link targets are matched against a mapping key using, in order:
    1) exact match after normalizing leading './' or '/' prefixes
    2) parent-prefix variants ("../" prefixes up to a few levels)
    3) basename match (file name only)
    4) trailing-component match (longest sequence of trailing path components)

  Notes:
  - A link like '../backup-apps.md' in references/ may match a mapping key
    'backup-apps.md' by basename. The script, when proposing a replacement,
    computes the correct relative path from the referencing file to the
    mapped target so the link remains valid after files are moved.
  - Identity mappings (key == value) are valid and indicate the file was
    migrated without renaming. They produce no edit; prune them if you want
    quieter output.
  - Bare same-directory links (e.g., `[Backup Repos](backup-repos.md)`)
    receive a `./` prefix heuristic even when the target is unchanged.

Two mapping files (convention over configuration)
- Both mappings live in /tmp/mappings/ by default (override with
  `--mappings-dir <path>`) and are identified by filename prefix:
    * repo-root-mapping-<MM-DD-YYYY>.json         (primary repo renames)
    * external-data-root-mapping-<MM-DD-YYYY>.json (artifact folder renames)
  When neither `--mapping` nor `--external-mapping` is provided, the newest
  file matching the corresponding prefix is used (filenames sort descending
  so the embedded timestamp wins). Pass `--mapping <path>` or
  `--external-mapping <path>` to select an explicit file.
- Repo-root mapping: old->new repo file/path renames driving the "Renamed
  Links", "Linked File Location Heuristics Changes", "Stale Filenames…",
  and "Repo Root Tree Changes" sections.
- External data-root mapping: folder/token renames applied to the
  destination artifact layout (e.g., `$BACKUP_ROOT` -> `$REIMAGE_ARTIFACT_ROOT`,
  `app-backups` -> `app-settings-backup`). Drives the "External Data Root
  Tree Changes" section and contributes to prose findings.

Report categories (written to /tmp/reports/update-references-report-<ts>.md)
- Renamed Links or Those with Missing Targets
- Linked File Location Heuristics Changes
- Stale Filenames and Their Derivatives in Prose (includes matches from the
  external-data-root mapping, with `$`-prefix awareness)
- Repo Root Tree Changes (fenced ASCII directory trees rebuilt against the
  primary mapping; unmigrated entries preserve their original paths)
- External Data Root Tree Changes (same, but driven by the external mapping)

Terminal output is limited to a totals table (Grand total plus one row per
category) and the path to the generated report file.

Rendering notes
- Directory trees use `<pre>` blocks with `<span style="color:#888;">`
  annotations so `← was <old>` markers render as muted grey in Obsidian and
  GitHub. Fenced ``` blocks would suppress inline HTML, so `<pre>` is used.
- Prose table cells HTML-encode every markdown-active character
  (`&`, `<`, `>`, `|`, `[`, `]`, `` ` ``, `*`) and wrap the changed token in
  `<strong>` so the literal snippet renders faithfully without triggering
  bold/italic/link parsing.
- Link table cells wrap the raw link syntax in `<code>` with `&#91; &#93;
  &#124;` encoded so Markdown parsers do not re-render inline links.

Diffs and patches (independent of --dry-run and of the report)
- `--patch <path>` writes a single combined unified diff to the given file.
- `--diffs` (bool) writes per-file unified diffs to /tmp/diffs/<timestamp>/
  (override with `--diffs-dir <path>`).
- Both flags may be combined; neither is required for the categorized report.

Usage examples

# Auto-discover both mappings from /tmp/mappings/ by prefix + newest timestamp
python3 .internal/copilot-scripts/update-references.py

# Pin explicit mapping files
python3 .internal/copilot-scripts/update-references.py \\
    --mapping /tmp/mappings/repo-root-mapping-07-16-2026.json \\
    --external-mapping /tmp/mappings/external-data-root-mapping-07-18-2026.json

# Generate the report AND per-file diffs under /tmp/diffs/<timestamp>/
python3 .internal/copilot-scripts/update-references.py --diffs

# Generate the report AND a single combined patch file
python3 .internal/copilot-scripts/update-references.py \\
    --patch /tmp/reports/update-references.patch

# Apply changes in-place after reviewing a patch (creates .bak backups)
python3 .internal/copilot-scripts/update-references.py \\
    --patch /tmp/reports/update-references.patch --apply

Exit codes
- 0: ran successfully (no fatal errors). If no replacements found, still 0.
- non-zero: fatal error (bad mapping file, IO error, --apply without --patch).

Safety
- Dry-run by default. Use --apply only after reviewing the patch output.

"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple

LINK_RE = re.compile(r"(\[.*?\])\(([^)]+)\)")  # captures [text](target)
# Obsidian-style wiki links: [[display|target]] or [[target]]
LINK_WIKI = re.compile(r"(\[\[([^\]]+)\]\])")
# Fenced code blocks that may contain ASCII directory trees
CODE_FENCE_RE = re.compile(r"(?:^|\n)```([\w-]*)\n(.*?)\n```", re.DOTALL)


def parse_tree_block(block_text: str) -> Tuple[str, List[Dict[str, object]]]:
    """Parse an ASCII directory tree block.

    Returns (root_line, entries). Each entry is a dict with keys:
      depth, name, is_dir, full_path, orig_line, trailing.
    Non-tree lines are ignored. The root_line is the first non-tree line
    that looks like a directory header (ends with '/'), or None.
    """
    lines = block_text.split('\n')
    root_line = None
    root_prefix = ''
    entries: List[Dict[str, object]] = []
    stack: List[Tuple[int, str]] = []  # (depth, name)
    for line in lines:
        if '├──' not in line and '└──' not in line:
            if root_line is None and line.strip().endswith('/'):
                root_line = line.rstrip()
                root_prefix = root_line.strip().rstrip('/')
            continue
        idx = line.index('├──') if '├──' in line else line.index('└──')
        prefix = line[:idx]
        depth = 0
        i = 0
        while i < len(prefix):
            if prefix[i:i + 4] in ('│   ', '    '):
                depth += 1
                i += 4
            else:
                break
        rest = line[idx + 3:]
        # Split leading whitespace-only chars; then split name from trailing content
        rest_stripped = rest.lstrip()
        parts = rest_stripped.split(None, 1)
        name_part = parts[0] if parts else ''
        trailing = ' ' + parts[1] if len(parts) > 1 else ''
        is_dir = name_part.endswith('/')
        name = name_part.rstrip('/')
        stack = stack[:depth]
        parent_bits = [n for _, n in stack]
        full_parts = ([root_prefix] if root_prefix else []) + parent_bits + [name]
        full_path = '/'.join(p for p in full_parts if p)
        entries.append({
            'depth': depth, 'name': name, 'is_dir': is_dir,
            'full_path': full_path, 'orig_line': line, 'trailing': trailing,
        })
        if is_dir:
            stack.append((depth, name))
    return root_line, entries


def _render_tree(node: Dict[str, dict], annotations: Dict[str, str],
                 path_prefix: str = '', line_prefix: str = '',
                 dir_paths: Optional[set] = None) -> List[Tuple[str, str]]:
    """Return a list of (main_line, annotation_or_empty) pairs. The annotation
    is kept separate so callers can style it (e.g. muted grey in HTML) while
    still producing a plain-text fallback.

    ``dir_paths`` carries the set of full paths that were originally listed
    as directories so leaf directories (empty subtrees) still render with a
    trailing ``/``.
    """
    if dir_paths is None:
        dir_paths = set()
    out: List[Tuple[str, str]] = []
    items = list(node.items())
    for i, (name, child) in enumerate(items):
        last = (i == len(items) - 1)
        connector = '└── ' if last else '├── '
        full_path = f"{path_prefix}/{name}" if path_prefix else name
        is_dir = bool(child) or (full_path in dir_paths)
        display = name + ('/' if is_dir else '')
        note = annotations.get(full_path, '')
        out.append((f"{line_prefix}{connector}{display}", note))
        if child:
            ext = '    ' if last else '│   '
            out.extend(_render_tree(child, annotations, full_path,
                                    line_prefix + ext, dir_paths))
    return out


def strict_tree_match(old_full: str, mapping: Dict[str, str]) -> Tuple[str, str] | Tuple[None, None]:
    """Return (mk, mv) for a tree entry when the entire mapping key equals a
    trailing suffix of the entry's full path. Prefers the longest matching key.
    Returns (None, None) when no full-suffix match exists.
    """
    t_parts = old_full.split('/')
    best: Tuple[str, str, int] | None = None
    for k, v in mapping.items():
        k_parts = k.split('/')
        if len(t_parts) < len(k_parts):
            continue
        if t_parts[-len(k_parts):] == k_parts:
            score = len(k_parts)
            if best is None or score > best[2]:
                best = (k, v, score)
    if best:
        return best[0], best[1]
    return None, None


def build_updated_tree(root_line: str, entries: List[Dict[str, object]],
                       mapping: Dict[str, str]) -> Tuple[List[Tuple[str, str]], int]:
    """Given parsed tree entries, produce an updated tree with mapped
    files at their new locations. Unmapped files keep their old paths.
    Changed leaves are annotated with `← was <old-path>` (kept in a
    separate field so callers can style it muted).

    Returns (lines, num_changed_entries) where each line is a
    (main_text, annotation_or_empty) pair.
    """
    changed = 0
    new_paths: List[str] = []
    dir_paths: List[str] = []
    annotations: Dict[str, str] = {}
    for e in entries:
        old_full = str(e['full_path'])
        if e['is_dir']:
            dir_paths.append(old_full)
            continue
        mk, mv = strict_tree_match(old_full, mapping)
        if mk and mv and mv != mk:
            new_full = mv
            changed += 1
            annotations[new_full] = f"← was {old_full}"
        else:
            new_full = old_full
        new_paths.append(new_full)

    tree_root: Dict[str, dict] = {}
    for p in new_paths:
        node = tree_root
        for part in p.split('/'):
            node = node.setdefault(part, {})
    # Preserve directory entries that had no listed children so `_render_tree`
    # can still emit them with a trailing '/'.
    for p in dir_paths:
        node = tree_root
        for part in p.split('/'):
            node = node.setdefault(part, {})

    dir_set = set(dir_paths)

    lines: List[Tuple[str, str]] = []
    header_prefix = ''
    if root_line:
        header = root_line.strip().rstrip('/')
        if header and header in tree_root and all(
            p.startswith(header + '/') or p == header for p in new_paths + dir_paths
        ):
            lines.append((root_line, ''))
            tree_root = tree_root[header]
            header_prefix = header
        else:
            lines.append(('<repo-root>/', ''))
    lines.extend(_render_tree(tree_root, annotations, header_prefix, '', dir_set))
    return lines, changed


def build_external_tree(root_line: str, entries: List[Dict[str, object]],
                        ext_mapping: Dict[str, str]) -> Tuple[List[Tuple[str, str]], int]:
    """Rebuild a directory tree with the external data-root mapping applied
    to every path segment (folder and file names). Segments not in the
    mapping are preserved. Renamed leaves get a muted annotation with
    their previous name.

    Returns (lines, num_changed_entries) — the same shape as
    ``build_updated_tree`` so the emitter can reuse its renderer.
    """
    def rewrite_segment(seg: str) -> str:
        # Support tokens like `$BACKUP_ROOT` where the mapping key is
        # `BACKUP_ROOT` and the value already carries its own `$` prefix.
        if seg in ext_mapping:
            return ext_mapping[seg]
        if seg.startswith('$') and seg[1:] in ext_mapping:
            val = ext_mapping[seg[1:]]
            return val if val.startswith('$') else '$' + val
        return seg

    def rewrite(path: str) -> Tuple[str, bool]:
        parts = path.split('/')
        new_parts = [rewrite_segment(p) for p in parts]
        # Only count / annotate entries whose non-root segments actually
        # changed. Pure root renames are annotated on the tree header, not
        # repeated on every leaf.
        non_root_changed = any(
            np != op for np, op in zip(new_parts[1:], parts[1:])
        )
        new_path = '/'.join(new_parts)
        return new_path, non_root_changed

    changed = 0
    new_paths: List[str] = []
    dir_paths: List[str] = []
    annotations: Dict[str, str] = {}
    for e in entries:
        old_full = str(e['full_path'])
        new_full, was_changed = rewrite(old_full)
        if e['is_dir']:
            dir_paths.append(new_full)
        else:
            new_paths.append(new_full)
        if was_changed:
            changed += 1
            annotations[new_full] = f"← was {old_full}"

    tree_root: Dict[str, dict] = {}
    for p in new_paths:
        node = tree_root
        for part in p.split('/'):
            node = node.setdefault(part, {})
    # Ensure directory entries that had no listed children are still present.
    for p in dir_paths:
        node = tree_root
        for part in p.split('/'):
            node = node.setdefault(part, {})

    lines: List[Tuple[str, str]] = []
    header_prefix = ''
    if root_line:
        original_header = root_line.strip().rstrip('/')
        new_header, _ = rewrite(original_header)
        header_changed = new_header != original_header
        if header_changed:
            changed += 1
        # Preserve the original leading whitespace of the header line.
        indent = root_line[:len(root_line) - len(root_line.lstrip())]
        display_header = f"{indent}{new_header}/"
        note = f"← was {original_header}/" if header_changed else ''
        all_under = all(p.startswith(new_header + '/') or p == new_header for p in new_paths + dir_paths)
        if new_header and new_header in tree_root and all_under:
            lines.append((display_header, note))
            tree_root = tree_root[new_header]
            header_prefix = new_header
        else:
            lines.append((display_header, note))
    lines.extend(_render_tree(tree_root, annotations, header_prefix, '', set(dir_paths)))
    return lines, changed


LINK_RE_ORIGINAL_MARKER = True  # placeholder to keep grep happy


def load_mapping(path: Path) -> Dict[str, str]:
    text = path.read_text(encoding="utf-8")
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        # attempt a lenient cleanup for common case: trailing commas before closing } or ]
        cleaned = re.sub(r",\s*(\}|\])", r"\1", text)
        try:
            data = json.loads(cleaned)
            print(f"Warning: mapping file {path} contained JSON syntax issues; attempted lenient cleanup and parsed successfully.")
        except json.JSONDecodeError:
            # re-raise original error with context
            raise
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


def match_mapping_for_target(target: str, mapping: Dict[str, str]) -> Tuple[str, str, str] | Tuple[None, None, None]:
    """Given a link target from a markdown file, attempt to find the best matching mapping key.
    Returns (mapping_key, mapping_value, match_type) or (None, None, None) if no match.
    match_type is one of: 'exact', 'dot', 'parent', 'basename', 'trailing'
    Uses heuristics in this priority order so callers can distinguish 'trailing' matches
    (which may require path adjustment) from exact matches.
    """
    t = target
    # strip leading ./
    if t.startswith("./"):
        t = t[2:]
    # strip any leading / (treat as repo-root relative)
    if t.startswith("/"):
        t = t[1:]
    # strip trailing anchor/title if present - caller should handle anchors; here assume stripped

    # direct matches
    if t in mapping:
        return t, mapping[t], 'exact'
    if "./" + t in mapping:
        return "./" + t, mapping["./" + t], 'dot'

    # try removing leading ../ segments up to 4 levels
    for i in range(1, 5):
        prefix = "../" * i
        if prefix + t in mapping:
            return prefix + t, mapping[prefix + t], 'parent'

    # basename match
    base = Path(t).name
    if base in mapping:
        return base, mapping[base], 'basename'

    # suffix/component match: prefer longest trailing component sequence match
    t_parts = t.split("/")
    best_key = None
    best_score = 0
    for k in mapping.keys():
        k_parts = k.split("/")
        # compute trailing match length
        score = 0
        for a, b in zip(reversed(t_parts), reversed(k_parts)):
            if a == b:
                score += 1
            else:
                break
        if score > best_score:
            best_score = score
            best_key = k
    if best_key and best_score >= 1:
        return best_key, mapping[best_key], 'trailing'

    return None, None, None


def compute_relative_link(repo_root: Path, file_path: Path, mapped_value: str) -> str:
    """Compute a repo-relative link from file_path to mapped_value preserving ./ or ../ where appropriate."""
    new_target = mapped_value
    if new_target.startswith("http://") or new_target.startswith("https://") or new_target.startswith("mailto:"):
        return new_target
    candidate = Path(new_target)
    if candidate.is_absolute() or str(candidate).startswith('/'):
        abs_target = candidate
    else:
        abs_target = (repo_root / candidate).resolve()
    try:
        rel = Path(abs_target).relative_to(file_path.parent.resolve())
        final_rel = rel.as_posix()
        if not final_rel.startswith('.'):
            return './' + final_rel
        return final_rel
    except Exception:
        import os
        final_rel = os.path.relpath(str(abs_target), start=str(file_path.parent.resolve()))
        return Path(final_rel).as_posix()


def replace_links_in_text(text: str, mapping: Dict[str, str], file_path: Path, repo_root: Path) -> Tuple[str, List[Tuple[str, str, str, str, str]]]:
    """Return new_text and list of replacements as tuples (orig_target, mapping_key, new_target, link_snippet, match_type)"""
    replacements: List[Tuple[str, str, str, str, str]] = []

    def repl(m: re.Match) -> str:
        link_text = m.group(1)
        target = m.group(2)
        # split off optional anchor or title (e.g., path.md#anchor or path.md "title")
        target_only = target
        title_suffix = ""
        # If there's a space and then a quote, treat rest as title/attrs
        if ' "' in target or " '" in target:
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

        norm = path_part
        # preserve the original form for reporting
        mapping_key, mapped_value, match_type = match_mapping_for_target(norm, mapping)

        if mapping_key and mapped_value:
            # compute replacement path relative to the referencing file
            new_target = mapped_value
            # if new_target is an absolute URL or mailto, leave as-is
            if new_target.startswith("http://") or new_target.startswith("https://") or new_target.startswith("mailto:"):
                final_target = new_target
            else:
                # compute absolute path of the mapped target relative to repo_root
                # mapping values may be repo-root relative or already include ./
                candidate = Path(new_target)
                if candidate.is_absolute() or str(candidate).startswith('/'):
                    abs_target = candidate
                else:
                    abs_target = (repo_root / candidate).resolve()
                try:
                    rel = Path(abs_target).relative_to(file_path.parent.resolve())
                    final_rel = rel.as_posix()
                    # if relative_to succeeded and final_rel does not start with '.', prefix './' if same directory
                    if not final_rel.startswith('.'):
                        final_target = './' + final_rel
                    else:
                        final_target = final_rel
                except Exception:
                    # fallback to os.path.relpath
                    import os
                    final_rel = os.path.relpath(str(abs_target), start=str(file_path.parent.resolve()))
                    final_target = Path(final_rel).as_posix()

            # Rewrite the visible label when it embeds the stale path or
            # basename verbatim so the link doesn't lag its target.
            new_link_text = link_text
            old_basename = Path(mapping_key).name
            new_basename = Path(mapped_value).name
            if mapping_key and mapping_key in link_text:
                new_link_text = link_text.replace(mapping_key, mapped_value)
            elif old_basename and old_basename in link_text and old_basename != new_basename:
                new_link_text = link_text.replace(old_basename, new_basename)

            replaced = f"{new_link_text}({final_target}{anchor}{title_suffix})"
            replacements.append((path_part, mapping_key, mapped_value, m.group(0), match_type))
            return replaced
        return m.group(0)

    new_text = LINK_RE.sub(repl, text)
    return new_text, replacements


def unified_diff(old: str, new: str, path: Path) -> str:
    # Preserve whatever line endings the source used (many docs here are
    # CRLF). Feed keepends-True lines to difflib and join with "" so the
    # generated diff is consistent with the working-tree file and applies
    # cleanly via `git apply` / `patch`.
    old_lines = old.splitlines(keepends=True)
    new_lines = new.splitlines(keepends=True)
    diff = difflib.unified_diff(old_lines, new_lines,
                                fromfile=str(path), tofile=str(path))
    return "".join(diff)


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


def build_new_link(current_link: str, new_rel: str, new_stem: str, old_stem: str,
                   old_full: str = '', new_full: str = '') -> str:
    """Given the original link snippet and the computed new relative target,
    produce the replacement link string preserving inline vs Obsidian wiki syntax.

    - Inline ``[text](old)`` -> ``[text](new_rel)``. When ``text`` embeds the
      old path or old basename literally, it is rewritten to the new one so
      the visible label doesn't stay stale.
    - Wiki ``[[display|old]]`` -> ``[[display|new_rel]]`` (display swapped to
      ``new_stem`` when it matches ``old_stem``).
    - Wiki ``[[old]]`` -> ``[[new_stem|new_rel]]``.
    """
    stripped = current_link.strip()
    old_basename = Path(old_full).name if old_full else ''
    new_basename = Path(new_full).name if new_full else ''

    if stripped.startswith('[['):
        inner = stripped[2:-2]
        if '|' in inner:
            display, _ = inner.split('|', 1)
            display_stripped = display.strip()
            if display_stripped.lower() == old_stem.lower():
                display = new_stem
            elif old_full and old_full in display:
                display = display.replace(old_full, new_full)
            elif old_basename and old_basename in display:
                display = display.replace(old_basename, new_basename)
            return f"[[{display}|{new_rel}]]"
        return f"[[{new_stem}|{new_rel}]]"

    m = re.match(r"(\[)(.*?)(\])\(([^)]+)\)", current_link)
    if m:
        text = m.group(2)
        # Rewrite label if it embeds the stale path/basename verbatim so the
        # visible link doesn't lag its target.
        if old_full and old_full in text:
            text = text.replace(old_full, new_full)
        elif old_basename and old_basename in text and old_basename != new_basename:
            text = text.replace(old_basename, new_basename)
        return f"[{text}]({new_rel})"
    return current_link


def classify_link(mk: str, mv: str, current_link: str, original_target: str,
                  ref_file: Path, repo_root: Path) -> Tuple[str, str, bool]:
    """Classify a link that matched a mapping entry.

    Returns (category, new_link, flag) where:
      - category is 'renamed' or 'location' or 'skip'
      - new_link is the constructed replacement link string
      - flag is target_missing (renamed) or location_changed (location)
    """
    target_missing = not validate_target_exists(repo_root, mv) if mv else True
    old_basename = Path(mk).name
    new_basename = Path(mv).name
    new_rel = compute_relative_link(repo_root, ref_file, mv)
    new_link = build_new_link(current_link, new_rel, Path(mv).stem, Path(mk).stem,
                              old_full=mk, new_full=mv)

    if old_basename != new_basename or target_missing:
        return 'renamed', new_link, target_missing

    # Same basename: either the path changed, or it's an identity mapping where
    # only the heuristic (leading `./`) needs to be applied.
    location_changed = (mk != mv)
    if new_link == current_link:
        return 'skip', new_link, False
    return 'location', new_link, location_changed


def main():
    parser = argparse.ArgumentParser(description="Update Markdown link targets using an explicit mapping.")
    parser.add_argument("--dir", default=".", help="Target directory to scan for .md files (default: cwd)")
    parser.add_argument("--mapping",
                        help="Repo-root mapping JSON (old->new paths). If omitted, "
                             "the newest file matching /tmp/mappings/repo-root-mapping-*.json is used.")
    parser.add_argument("--external-mapping",
                        help="External data-root mapping JSON (folder/token renames). "
                             "If omitted, the newest file matching "
                             "/tmp/mappings/external-data-root-mapping-*.json is used, when present.")
    parser.add_argument("--mappings-dir", default="/tmp/mappings",
                        help="Directory searched for mapping files by prefix convention "
                             "(default: /tmp/mappings).")
    parser.add_argument("--repo-root", default=".", help="Repository root for existence checks (default: cwd)")
    parser.add_argument("--dry-run", action="store_true", help="Print diffs but do not modify files (default)")
    parser.add_argument("--patch", help="Write a combined unified diff patch to this file")
    parser.add_argument("--diffs", action="store_true",
                        help="Write per-file unified diffs to a directory "
                             "(default: /tmp/diffs/<timestamp>). Independent of --dry-run.")
    parser.add_argument("--diffs-dir",
                        help="Override the output directory used by --diffs.")
    parser.add_argument("--force", action="store_true", help="Apply replacements even if the new target does not exist")
    # applying changes should be gated: require a patch file to be provided so users can review before apply
    parser.add_argument("--apply", action="store_true", help="Apply changes in-place (creates .bak backups). Requires --patch to be provided for safety.")
    # keep backward compatibility for --dry-run behavior
    # note: --dry-run is a flag; when not present and not --apply, script still runs in preview mode but will not write patches/diffs unless requested

    args = parser.parse_args()

    target_dir = Path(args.dir)
    repo_root = Path(args.repo_root)

    if not target_dir.exists():
        print(f"Error: target dir does not exist: {target_dir}")
        raise SystemExit(2)

    # if user asked to apply, ensure they also provided a patch path (safety)
    if args.apply and not args.patch:
        print("Error: --apply requires --patch to be provided. Create and review a patch first using --patch, then re-run with --apply to apply changes.")
        raise SystemExit(2)

    def discover_latest(mappings_dir: Path, prefix: str) -> Optional[Path]:
        """Return the newest mapping file in ``mappings_dir`` whose name starts
        with ``prefix``. Sorted by filename descending so embedded timestamps
        (MM-DD-YYYY) win consistently regardless of filesystem mtime.
        """
        if not mappings_dir.is_dir():
            return None
        candidates = sorted(mappings_dir.glob(f"{prefix}-*.json"), reverse=True)
        return candidates[0] if candidates else None

    mappings_dir = Path(args.mappings_dir)

    if args.mapping:
        mapping_path = Path(args.mapping)
    else:
        found = discover_latest(mappings_dir, "repo-root-mapping")
        if not found:
            print(f"Error: no --mapping supplied and no repo-root-mapping-*.json "
                  f"found in {mappings_dir}.")
            raise SystemExit(2)
        mapping_path = found
        print(f"Using repo-root mapping: {mapping_path}")

    if not mapping_path.exists():
        print(f"Error: mapping file does not exist: {mapping_path!r}")
        raise SystemExit(2)
    try:
        mapping = load_mapping(mapping_path)
    except Exception as e:
        print(f"Error: failed to load mapping file {mapping_path!r}: {e}")
        raise
    if not mapping:
        print("Warning: mapping is empty.")

    # External data-root mapping (folder/token renames). Optional; when the
    # file is missing we simply skip that section.
    external_mapping: Dict[str, str] = {}
    if args.external_mapping:
        external_mapping_path: Optional[Path] = Path(args.external_mapping)
    else:
        external_mapping_path = discover_latest(mappings_dir, "external-data-root-mapping")
        if external_mapping_path:
            print(f"Using external data-root mapping: {external_mapping_path}")
    if external_mapping_path and external_mapping_path.exists():
        try:
            external_mapping = json.loads(external_mapping_path.read_text(encoding='utf-8'))
        except Exception as e:
            print(f"Warning: failed to load external mapping {external_mapping_path!r}: {e}")
            external_mapping = {}


    # If no explicit dir given (default '.'), prefer scanning repo_root/references if it exists
    if args.dir == '.' or str(target_dir) == '.':
        candidate = repo_root / 'references'
        if candidate.exists() and candidate.is_dir():
            target_dir = candidate

    # Collect markdown files under the target_dir
    files = find_markdown_files(target_dir)

    # Always include top-level runbooks and guides that are commonly referenced
    extra_paths = [repo_root / 'reimaging-guide.md', repo_root / 'reimaging-scripts-guide.md', repo_root / 'README.md']
    for p in extra_paths:
        if p.exists() and p.is_file() and p not in files:
            files.append(p)

    # Sort and dedupe
    files = sorted({str(f): f for f in files}.values())

    if not files:
        print("No markdown files found in target dir.")
        return

    all_diffs: List[str] = []
    any_replacements = False

    # Per-file classified findings.
    # Each entry in these lists is a dict with the fields needed for the report tables.
    #
    # renamed_by_file:   file -> [{mk, mv, current_link, new_link, target_missing}]
    # location_by_file:  file -> [{mk, mv, current_link, new_link, location_changed}]
    # prose_by_file:     file -> [{mk, mv, current_prose, new_prose}]
    renamed_by_file: Dict[str, List[Dict[str, object]]] = {}
    location_by_file: Dict[str, List[Dict[str, object]]] = {}
    prose_by_file: Dict[str, List[Dict[str, object]]] = {}
    trees_by_file: Dict[str, List[Dict[str, object]]] = {}
    # external_by_file: file -> {'count': int, 'trees': [{line, lines, count}]}
    external_by_file: Dict[str, Dict[str, object]] = {}

    def normalize_target(raw: str) -> str:
        t = raw.split(' ', 1)[0].split('#', 1)[0]
        if t.startswith('./'):
            t = t[2:]
        if t.startswith('/'):
            t = t[1:]
        return t

    def build_new_prose(snippet: str, orig: str, new_token: str) -> str:
        return re.sub(re.escape(orig), new_token, snippet, flags=re.IGNORECASE)

    def rewrite_prose_capture(snippet: str) -> Tuple[str, List[Tuple[str, str]]]:
        """Apply every prose-mapping rewrite (repo + external) to ``snippet``
        and return ``(new_snippet, changes)`` where ``changes`` is the list
        of ``(orig_span, new_span)`` pairs. Used by the report to render a
        row that reflects *all* mappings affecting the same context, not
        just the single entry the row was recorded for.
        """
        changes: List[Tuple[str, str]] = []
        text = snippet
        for mk, mv in mapping.items():
            if mk == mv:
                continue
            bname = Path(mk).name
            new_bname = Path(mv).name
            stem = Path(mk).stem
            new_stem = Path(mv).stem
            # (a) literal path
            def _repl_a(m: re.Match, _mv: str = mv) -> str:
                changes.append((m.group(0), _mv))
                return _mv
            text = re.sub(re.escape(mk), _repl_a, text)
            # (b) basename (not embedded in a longer path)
            if bname and bname != new_bname:
                def _repl_b(m: re.Match, _nb: str = new_bname) -> str:
                    changes.append((m.group(0), _nb))
                    return _nb
                text = re.sub(r'(?<![\w/\-.])' + re.escape(bname) + r'\b',
                              _repl_b, text)
            # (c) tokenized derivative (e.g. "Restore Git" -> "Restore Repos")
            token = re.sub(r'[-_]+', ' ', stem)
            words = token.split()
            if words and stem.lower() != new_stem.lower():
                if len(words) == 1:
                    pattern = r'(?<![\w./\-])' + re.escape(words[0]) + r'(?![\w./\-])'
                else:
                    pattern = r'\b' + r'\s+'.join(re.escape(w) for w in words) + r'\b'
                new_display = re.sub(r'[-_]+', ' ', new_stem)
                def _repl_c(m: re.Match, _nd: str = new_display) -> str:
                    new_tok = match_case(m.group(0), _nd)
                    changes.append((m.group(0), new_tok))
                    return new_tok
                text = re.sub(pattern, _repl_c, text, flags=re.IGNORECASE)
        for ek, ev in external_mapping.items():
            pattern = r'(?<![\w\-])(\$?)' + re.escape(ek) + r'(\*/)?(?![\w\-])'
            def _repl_e(m: re.Match, _ev: str = ev) -> str:
                orig = m.group(0)
                dollar = m.group(1)
                trailing = m.group(2) or ''
                had = dollar == '$'
                val_dollar = _ev.startswith('$')
                if had and val_dollar:
                    new_val = _ev
                elif had and not val_dollar:
                    new_val = '$' + _ev
                elif not had and val_dollar:
                    new_val = _ev[1:]
                else:
                    new_val = _ev
                if trailing:
                    new_val = new_val + ('/*' if '/' in new_val else '*/')
                changes.append((orig, new_val))
                return new_val
            text = re.sub(pattern, _repl_e, text)
        return text, changes

    def match_case(orig: str, repl: str) -> str:
        if orig and orig.isupper():
            return repl.upper()
        stripped = (orig or '').strip()
        # Preserve all-lowercase tokens (e.g. inline `bootstrap` in prose).
        if stripped and stripped == stripped.lower():
            return repl.lower()
        words = re.findall(r"\w+", orig or "")
        if words and all(w[0].isupper() for w in words if w):
            return ' '.join(w.capitalize() for w in repl.split())
        if stripped and stripped[0].isupper():
            return repl.capitalize()
        return repl

    def build_updated_text(src: str, file_path: Path) -> str:
        """Apply every mechanical rewrite the report describes: link
        rewrites (inline + wiki + heuristic ``./`` prefix), fenced tree
        rebuilds (primary + external mapping), and prose token
        substitutions outside links and fences.
        """
        # Pass 1: rebuild fenced tree blocks with primary then external mappings.
        def _serialize(lines: List[Tuple[str, str]]) -> str:
            return '\n'.join(main for main, _ in lines)

        def rebuild_fence(m: re.Match) -> str:
            raw = m.group(0)
            lang = m.group(1)
            body = m.group(2)
            # CODE_FENCE_RE optionally captures the newline before the opening
            # ``` (via `(?:^|\n)`). Preserve it so the replacement plugs back
            # into the source without dropping the fence opener.
            prefix_nl = '\n' if raw.startswith('\n') else ''
            if '├──' not in body and '└──' not in body:
                return raw
            root_line, entries = parse_tree_block(body)
            if not entries:
                return raw
            new_body = body
            new_lines_1, changed_1 = build_updated_tree(root_line, entries, mapping)
            if changed_1:
                new_body = _serialize(new_lines_1)
            if external_mapping:
                root2, entries2 = parse_tree_block(new_body)
                if entries2:
                    new_lines_2, changed_2 = build_external_tree(root2, entries2, external_mapping)
                    if changed_2:
                        new_body = _serialize(new_lines_2)
            if new_body == body:
                return raw
            return f"{prefix_nl}```{lang}\n{new_body}\n```"

        src = CODE_FENCE_RE.sub(rebuild_fence, src)

        # Pass 2: inline `[text](url)` links.
        def rewrite_inline(m: re.Match) -> str:
            current_link = m.group(0)
            raw_target = m.group(2)
            target = raw_target.split(' ', 1)[0].split('#', 1)[0]
            if not target or target.startswith(('http://', 'https://', 'mailto:')):
                return current_link
            tn = normalize_target(target)
            mk, mv, _ = match_mapping_for_target(tn, mapping)
            if mk and mv:
                category, new_link, _ = classify_link(mk, mv, current_link, tn, file_path, repo_root)
                return new_link if category != 'skip' else current_link
            raw = target
            if not raw or '/' in raw or raw.startswith('.'):
                return current_link
            candidate = (file_path.parent / raw).resolve()
            if not candidate.exists() or not candidate.is_file():
                return current_link
            new_rel = './' + raw
            candidate_link = build_new_link(current_link, new_rel,
                                            Path(raw).stem, Path(raw).stem)
            return candidate_link

        src = LINK_RE.sub(rewrite_inline, src)

        # Pass 3: Obsidian wiki links `[[...]]`.
        def rewrite_wiki(m: re.Match) -> str:
            full = m.group(1)
            inner = m.group(2)
            target = inner.split('|', 1)[1] if '|' in inner else inner
            tn = normalize_target(target)
            mk, mv, _ = match_mapping_for_target(tn, mapping)
            if mk and mv:
                category, new_link, _ = classify_link(mk, mv, full, tn, file_path, repo_root)
                return new_link if category != 'skip' else full
            return full

        src = LINK_WIKI.sub(rewrite_wiki, src)

        # Pass 4: prose token substitutions in regions outside fences and links.
        def rewrite_prose_chunk(chunk: str) -> str:
            # Primary mapping: literal path, standalone basename, tokenized derivative.
            for mk, mv in mapping.items():
                if mk == mv:
                    continue
                bname = Path(mk).name
                new_bname = Path(mv).name
                if mk in chunk:
                    chunk = chunk.replace(mk, mv)
                if bname and bname != new_bname:
                    chunk = re.sub(r'(?<![\w/\-.])' + re.escape(bname) + r'\b',
                                   new_bname, chunk)
                stem = Path(mk).stem
                new_stem = Path(mv).stem
                token = re.sub(r'[-_]+', ' ', stem)
                words = token.split()
                if words and stem.lower() != new_stem.lower():
                    if len(words) == 1:
                        pattern = r'(?<![\w./\-])' + re.escape(words[0]) + r'(?![\w./\-])'
                    else:
                        pattern = r'\b' + r'\s+'.join(re.escape(w) for w in words) + r'\b'
                    new_display = re.sub(r'[-_]+', ' ', new_stem)
                    def _case_repl(mm: re.Match) -> str:
                        return match_case(mm.group(0), new_display)
                    chunk = re.sub(pattern, _case_repl, chunk, flags=re.IGNORECASE)
            # External mapping tokens. When the source path is followed by
            # ``*/`` and the mapping value introduces a new sub-directory
            # (contains ``/``), reposition the star as ``/*`` so a directory
            # glob keeps its "contents of" meaning after the rename.
            for ek, ev in external_mapping.items():
                pattern = r'(?<![\w\-])(\$?)' + re.escape(ek) + r'(\*/)?(?![\w\-])'
                def _ext_repl(mm: re.Match) -> str:
                    dollar = mm.group(1)
                    trailing = mm.group(2) or ''
                    had = dollar == '$'
                    val_dollar = ev.startswith('$')
                    if had and val_dollar:
                        new_val = ev
                    elif had and not val_dollar:
                        new_val = '$' + ev
                    elif not had and val_dollar:
                        new_val = ev[1:]
                    else:
                        new_val = ev
                    if trailing:
                        return new_val + ('/*' if '/' in new_val else '*/')
                    return new_val
                chunk = re.sub(pattern, _ext_repl, chunk)
            return chunk

        boundaries: List[Tuple[int, int]] = []
        for cm in CODE_FENCE_RE.finditer(src):
            boundaries.append((cm.start(), cm.end()))
        for cm in LINK_RE.finditer(src):
            boundaries.append((cm.start(), cm.end()))
        for cm in LINK_WIKI.finditer(src):
            boundaries.append((cm.start(), cm.end()))
        boundaries.sort()
        # Merge overlaps so we don't re-process spliced regions.
        merged: List[Tuple[int, int]] = []
        for s, e in boundaries:
            if merged and s <= merged[-1][1]:
                merged[-1] = (merged[-1][0], max(merged[-1][1], e))
            else:
                merged.append((s, e))

        out: List[str] = []
        cursor = 0
        for s, e in merged:
            if cursor < s:
                out.append(rewrite_prose_chunk(src[cursor:s]))
            out.append(src[s:e])
            cursor = e
        if cursor < len(src):
            out.append(rewrite_prose_chunk(src[cursor:]))
        return ''.join(out)

    for f in files:
        src = f.read_text(encoding="utf-8")
        fkey = str(f)

        # Combined pass over inline `[text](target)` and Obsidian `[[...]]` link syntaxes.
        # We record every link that matches a mapping entry and classify it as
        # 'renamed' (filename changed or target missing) or 'location' (path/heuristic change).
        seen_links: set = set()

        def record_link(current_link: str, raw_target: str) -> None:
            t = normalize_target(raw_target)
            if not t or t.startswith('http://') or t.startswith('https://') or t.startswith('mailto:'):
                return
            mk, mv, _mt = match_mapping_for_target(t, mapping)
            if mk and mv:
                category, new_link, flag = classify_link(mk, mv, current_link, t, f, repo_root)
                if category == 'skip':
                    return
                key = (current_link, mk, mv)
                if key in seen_links:
                    return
                seen_links.add(key)
                entry = {
                    'mk': mk,
                    'mv': mv,
                    'current_link': current_link,
                    'new_link': new_link,
                }
                if category == 'renamed':
                    entry['target_missing'] = flag
                    renamed_by_file.setdefault(fkey, []).append(entry)
                else:
                    entry['location_changed'] = flag
                    location_by_file.setdefault(fkey, []).append(entry)
                return

            # Heuristic-only path: no mapping match. Suggest a leading './' when
            # the referenced file is a bare filename that lives in the same
            # directory as the referencing file and exists on disk.
            raw = raw_target.split(' ', 1)[0].split('#', 1)[0]
            if not raw or '/' in raw or raw.startswith('.'):
                return
            candidate = (f.parent / raw).resolve()
            if not candidate.exists() or not candidate.is_file():
                return
            new_rel = './' + raw
            new_link = build_new_link(current_link, new_rel, Path(raw).stem, Path(raw).stem)
            if new_link == current_link:
                return
            key = (current_link, raw, raw)
            if key in seen_links:
                return
            seen_links.add(key)
            location_by_file.setdefault(fkey, []).append({
                'mk': raw,
                'mv': raw,
                'current_link': current_link,
                'new_link': new_link,
                'location_changed': False,
            })

        for m in LINK_RE.finditer(src):
            record_link(m.group(0), m.group(2))
        for wm in LINK_WIKI.finditer(src):
            inner = wm.group(2)
            target = inner.split('|', 1)[1] if '|' in inner else inner
            record_link(wm.group(1), target)

        # Prose occurrences: scan text with fenced code blocks AND link syntaxes
        # stripped, so we only match literal filenames, basenames, or
        # human-readable derivatives outside code and outside link syntax.
        # (Fenced code blocks are covered by the directory-tree section instead.)
        fence_stripped = re.sub(r'```[\w-]*.*?```', '', src, flags=re.DOTALL)
        cleaned_src = LINK_RE.sub('', LINK_WIKI.sub('', fence_stripped))
        seen_prose: set = set()

        def record_prose(snippet: str, orig_token: str, new_token: str, mk: str, mv: str, allow_code: bool = False) -> None:
            snippet = snippet.replace('\n', ' ')
            if '[' in snippet or ']' in snippet:
                return
            if not allow_code and '`' in snippet:
                return
            if new_token.lower() == orig_token.lower():
                return
            new_snippet = build_new_prose(snippet, orig_token, new_token)
            if new_snippet == snippet:
                return
            key = (snippet, orig_token, new_token)
            if key in seen_prose:
                return
            seen_prose.add(key)
            prose_by_file.setdefault(fkey, []).append({
                'mk': mk,
                'mv': mv,
                'current_prose': snippet,
                'new_prose': new_snippet,
                'orig_token': orig_token,
                'new_token': new_token,
            })

        for mk, mv in mapping.items():
            if mk == mv:
                continue
            bname = Path(mk).name
            stem = Path(mk).stem
            token = re.sub(r"[-_]+", " ", stem)
            words = token.split()

            # (a) literal path occurrence e.g. `scripts/backup-apps.sh`
            for it in re.finditer(re.escape(mk), cleaned_src):
                s, e = it.span()
                snippet = cleaned_src[max(0, s-40):min(len(cleaned_src), e+40)]
                record_prose(snippet, mk, mv, mk, mv)

            # (b) basename occurrence e.g. `backup-apps.sh`
            new_basename = Path(mv).name
            for it in re.finditer(r"\b" + re.escape(bname) + r"\b", cleaned_src):
                s, e = it.span()
                # Skip when this basename is embedded inside a longer path — the
                # literal-path pass (a) already covered it (or will).
                if s > 0 and cleaned_src[s - 1] == '/':
                    continue
                snippet = cleaned_src[max(0, s-40):min(len(cleaned_src), e+40)]
                record_prose(snippet, bname, new_basename, mk, mv)

            # (c) tokenized derivative e.g. `Restore Git` -> `Restore Repos`.
            # Skip when the stem is unchanged (identity in the derivative)
            # so we never trigger a spurious case rewrite. For single-word
            # stems, tighten the boundary so we don't match inside filenames
            # like `bootstrap.sh` or `bootstrap-cheatsheet.md`.
            new_stem = Path(mv).stem
            if words and stem.lower() != new_stem.lower():
                if len(words) == 1:
                    pattern = r"(?<![\w./\-])" + re.escape(words[0]) + r"(?![\w./\-])"
                else:
                    pattern = r"\b" + r"\s+".join(re.escape(w) for w in words) + r"\b"
                for it in re.finditer(pattern, cleaned_src, flags=re.IGNORECASE):
                    s, e = it.span()
                    snippet = cleaned_src[max(0, s-40):min(len(cleaned_src), e+40)]
                    orig_token = it.group(0)
                    repl_display = re.sub(r"[-_]+", " ", new_stem)
                    new_token = match_case(orig_token, repl_display)
                    record_prose(snippet, orig_token, new_token, mk, mv)

        # Directory-tree code blocks: parse each fenced block that contains tree
        # characters and compute an updated tree, moving mapped files to their
        # new locations while leaving unmigrated files at their old paths.
        for cm in CODE_FENCE_RE.finditer(src):
            block_text = cm.group(2)
            if '├──' not in block_text and '└──' not in block_text:
                continue
            root_line, tree_entries = parse_tree_block(block_text)
            if not tree_entries:
                continue
            new_tree_text, changed = build_updated_tree(root_line, tree_entries, mapping)
            if changed == 0:
                continue
            line_no = src[:cm.start()].count('\n') + 1
            trees_by_file.setdefault(fkey, []).append({
                'line': line_no,
                'root': root_line or '(no root header)',
                'old_tree': block_text,
                'new_tree': new_tree_text,
                'count': changed,
            })

        # External data-root mapping:
        #  - Directory trees: rebuild each fenced tree that contains renames.
        #  - Prose occurrences (outside links, fenced blocks): feed into the
        #    primary `prose_by_file` bucket so they render in the "Stale
        #    Filenames and Their Derivatives in Prose" section.
        # The count shown next to each file in the external section reflects
        # only tree-entry changes.
        if external_mapping:
            ext_trees: List[Dict[str, object]] = []
            for cm in CODE_FENCE_RE.finditer(src):
                block_text = cm.group(2)
                if '├──' not in block_text and '└──' not in block_text:
                    continue
                root_line, tree_entries = parse_tree_block(block_text)
                if not tree_entries:
                    continue
                ext_lines, ext_changed = build_external_tree(root_line, tree_entries, external_mapping)
                if ext_changed == 0:
                    continue
                line_no = src[:cm.start()].count('\n') + 1
                ext_trees.append({'line': line_no, 'lines': ext_lines, 'count': ext_changed})
            ext_count = sum(int(t['count']) for t in ext_trees)
            if ext_trees:
                external_by_file[fkey] = {'count': ext_count, 'trees': ext_trees}

            # Prose scan for external tokens. Support optional `$` prefix so
            # both `BACKUP_ROOT` and `$BACKUP_ROOT` are detected; adjust the
            # replacement so we never emit `$$REIMAGE_ARTIFACT_ROOT`.
            for ek, ev in external_mapping.items():
                pattern = r'(?<![\w\-])\$?' + re.escape(ek) + r'(?![\w\-])'
                for it in re.finditer(pattern, cleaned_src):
                    s, e = it.span()
                    orig_tok = cleaned_src[s:e]
                    had_dollar = orig_tok.startswith('$')
                    val_dollar = ev.startswith('$')
                    if had_dollar and val_dollar:
                        new_tok = ev
                    elif had_dollar and not val_dollar:
                        new_tok = '$' + ev
                    elif not had_dollar and val_dollar:
                        new_tok = ev[1:]
                    else:
                        new_tok = ev
                    snippet = cleaned_src[max(0, s-40):min(len(cleaned_src), e+40)]
                    record_prose(snippet, orig_tok, new_tok, orig_tok, new_tok, allow_code=True)

        # Build the unified diff for --patch/--diffs output using the full
        # apply pipeline so every category the report describes is included.
        new_text = build_updated_text(src, f)
        diff_text = unified_diff(src, new_text, f)
        has_findings = bool(
            renamed_by_file.get(fkey)
            or location_by_file.get(fkey)
            or prose_by_file.get(fkey)
            or trees_by_file.get(fkey)
            or external_by_file.get(fkey)
        )
        if diff_text.strip():
            any_replacements = True
            all_diffs.append((fkey, diff_text))
        elif has_findings:
            any_replacements = True

        if args.apply:
            print("Apply requested, but --apply currently only supports applying a reviewed patch. Create a patch with --patch and re-run with --apply.")
            raise SystemExit(2)

    # ------------------------------------------------------------------
    # Report
    # ------------------------------------------------------------------
    renamed_total = sum(len(v) for v in renamed_by_file.values())
    location_total = sum(len(v) for v in location_by_file.values())
    prose_total = sum(len(v) for v in prose_by_file.values())
    tree_total = sum(int(t['count']) for v in trees_by_file.values() for t in v)
    external_total = sum(int(v['count']) for v in external_by_file.values())
    grand_total = renamed_total + location_total + prose_total + tree_total + external_total

    # Compose report as a list of markdown lines; only totals + report path go to stdout.
    report: List[str] = []
    def w(line: str = '') -> None:
        report.append(line)

    # Timestamp filename in EST (UTC-5). Use a fixed offset rather than a tz db lookup.
    from datetime import datetime, timezone, timedelta
    est = timezone(timedelta(hours=-5), name='EST')
    now_est = datetime.now(est)
    filename_ts = now_est.strftime('%m-%d-%Y-%H%M%S-EST')
    header_ts = now_est.strftime('%Y-%m-%d %H:%M:%S %Z')

    reports_dir = Path('/tmp/reports')
    reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = reports_dir / f"update-references-report-{filename_ts}.md"

    w(f"# Update References Report")
    w()
    w(f"- Generated: {header_ts}")
    w(f"- Mapping file: {mapping_path}")
    w(f"- Mapping entries: {len(mapping)}")
    w(f"- Files scanned: {len(files)}")
    for p in files:
        w(f"  - {p}")
    w()
    w("| Category                                              | Count |")
    w("|-------------------------------------------------------|------:|")
    w(f"| Total occurrences of stale file references            | {grand_total:>5} |")
    w(f"|   Renamed links or those with missing targets         | {renamed_total:>5} |")
    w(f"|   Linked file location or heuristics changes          | {location_total:>5} |")
    w(f"|   Stale filenames and their derivatives in prose      | {prose_total:>5} |")
    w(f"|   Repo root tree changes                              | {tree_total:>5} |")
    w(f"|   External data root tree changes                     | {external_total:>5} |")
    w()

    def truncate(text: str, width: int = 80) -> str:
        text = text.replace('\n', ' ')
        if len(text) <= width:
            return text
        return text[: width - 1] + '…'

    def link_cell(text: str) -> str:
        """Render a link snippet as inline code inside a table cell.

        Uses HTML `<code>` with HTML-entity-encoded punctuation so that
        neither Obsidian nor GitHub-flavored markdown parse the snippet
        as an active link. In particular `[` and `]` are encoded so
        `[text](url)` cannot be reparsed as a markdown link, and `|` is
        encoded so wiki links `[[display|target]]` do not terminate the
        surrounding table cell.
        """
        text = truncate(text)
        text = (text.replace('&', '&amp;')
                    .replace('<', '&lt;')
                    .replace('>', '&gt;')
                    .replace('[', '&#91;')
                    .replace(']', '&#93;')
                    .replace('|', '&#124;'))
        return f"<code>{text}</code>"

    def bold_cell(snippet: str, tokens) -> str:
        """Render a prose snippet inside a Markdown table cell. HTML-escapes
        every markdown-active character (``|``, ``[``, ``]``, ``` ` ```,
        ``*``, ``<``, ``>``) so the cell renders as literal text, then wraps
        the first case-insensitive occurrence of each token in ``tokens``
        with ``<strong>``. ``tokens`` may be a single string or a list of
        strings; each unique token is bolded once (first occurrence).
        """
        snippet = snippet.replace('\n', ' ').strip()
        # Also drop tree drawing characters that leak in from adjacent
        # fenced or blockquoted trees — they were meant to be stripped upstream.
        snippet = re.sub(r'[├└│─]+', ' ', snippet)
        snippet = re.sub(r'\s+', ' ', snippet)
        if len(snippet) > 200:
            snippet = snippet[:199] + '…'
        marker_open, marker_close = '\x00OPEN\x00', '\x00CLOSE\x00'
        if isinstance(tokens, str):
            token_list = [tokens] if tokens else []
        else:
            token_list = [t for t in tokens if t]
        # Bold longest first so a short token can't gobble part of a longer one.
        seen: set = set()
        for token in sorted(token_list, key=len, reverse=True):
            if not token or token in seen:
                continue
            seen.add(token)
            snippet = re.sub(re.escape(token),
                             lambda m: f"{marker_open}{m.group(0)}{marker_close}",
                             snippet, count=1, flags=re.IGNORECASE)
        snippet = (snippet
                   .replace('&', '&amp;')
                   .replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('|', '&#124;')
                   .replace('[', '&#91;')
                   .replace(']', '&#93;')
                   .replace('`', '&#96;')
                   .replace('*', '&#42;'))
        snippet = snippet.replace(marker_open, '<strong>').replace(marker_close, '</strong>')
        return snippet

    def emit_link_section(heading: str, per_file: Dict[str, List[Dict[str, object]]],
                          flag_key: str, flag_label: str) -> None:
        w(f"## {heading}")
        w()
        if not per_file:
            w("_None found._")
            w()
            return
        w("Reference files:")
        for ref_file in sorted(per_file.keys()):
            w(f"- {ref_file}")
        for ref_file in sorted(per_file.keys()):
            w()
            w(f"### {ref_file}")
            w()
            w(f"| Before -> After | Current Link | New Link | {flag_label} |")
            w("|---|---|---|---|")
            for entry in per_file[ref_file]:
                before_after = f"{entry['mk']} -> {entry['mv']}"
                current_col = link_cell(str(entry['current_link']))
                new_col = link_cell(str(entry['new_link']))
                flag_val = 'yes' if entry.get(flag_key) else 'no'
                w(f"| {before_after} | {current_col} | {new_col} | {flag_val} |")
        w()

    def emit_prose_section(heading: str, per_file: Dict[str, List[Dict[str, object]]]) -> None:
        w(f"## {heading}")
        w()
        if not per_file:
            w("_None found._")
            w()
            return
        w("Reference files:")
        for ref_file in sorted(per_file.keys()):
            w(f"- {ref_file}")
        for ref_file in sorted(per_file.keys()):
            w()
            w(f"### {ref_file}")
            w()
            w("| Before -> After | Current Prose Context | New Prose Context |")
            w("|---|---|---|")
            for entry in per_file[ref_file]:
                before_after = f"{entry['mk']} -> {entry['mv']}"
                # Recompute new_prose across ALL mappings (repo + external)
                # so a row's Current/New cells reflect every change touching
                # the same context, not just the mapping that recorded the row.
                orig_snippet = str(entry['current_prose'])
                final_new, changes = rewrite_prose_capture(orig_snippet)
                orig_tokens = [c[0] for c in changes] or [str(entry.get('orig_token', ''))]
                new_tokens = [c[1] for c in changes] or [str(entry.get('new_token', ''))]
                current_col = bold_cell(orig_snippet, orig_tokens)
                new_col = bold_cell(final_new, new_tokens)
                w(f"| {before_after} | {current_col} | {new_col} |")
        w()

    def emit_tree_section(heading: str, per_file: Dict[str, List[Dict[str, object]]]) -> None:
        w(f"## {heading}")
        w()
        if not per_file:
            w("_None found._")
            w()
            return

        def file_count(entries: List[Dict[str, object]]) -> int:
            return sum(int(t['count']) for t in entries)

        w("Reference files:")
        for ref_file in sorted(per_file.keys()):
            w(f"- {ref_file} ({file_count(per_file[ref_file])})")

        def esc(s: str) -> str:
            return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

        for ref_file in sorted(per_file.keys()):
            w()
            w(f"### {ref_file} ({file_count(per_file[ref_file])})")
            w()
            for tree in per_file[ref_file]:
                w(f"_Tree at line {tree['line']} — {tree['count']} entr"
                  f"{'y' if tree['count'] == 1 else 'ies'} updated_")
                w()
                # Render as HTML <pre> so the annotation column can be muted
                # via inline styles. Obsidian and GitHub both honour <pre> and
                # inline <span> style attributes inside a markdown document.
                w('<pre>')
                for main, note in tree['new_tree']:
                    if note:
                        w(f'{esc(main)}    <span style="color:#888;">{esc(note)}</span>')
                    else:
                        w(esc(main))
                w('</pre>')
                w()

    def emit_external_section(heading: str, per_file: Dict[str, Dict[str, object]]) -> None:
        w(f"## {heading}")
        w()
        if not per_file:
            w("_None found._")
            w()
            return
        w("Reference files:")
        for ref_file in sorted(per_file.keys()):
            entry = per_file[ref_file]
            w(f"- {ref_file} ({entry['count']})")

        def esc(s: str) -> str:
            return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

        for ref_file in sorted(per_file.keys()):
            entry = per_file[ref_file]
            w()
            w(f"### {ref_file} ({entry['count']})")
            w()
            trees = entry.get('trees') or []
            if not trees:
                w("_No impacted directory trees; occurrences appear only in prose._")
                w()
                continue
            for tree in trees:
                w(f"_Tree at line {tree['line']} — {tree['count']} entr"
                  f"{'y' if tree['count'] == 1 else 'ies'} updated_")
                w()
                w('<pre>')
                for main, note in tree['lines']:
                    if note:
                        w(f'{esc(main)}    <span style="color:#888;">{esc(note)}</span>')
                    else:
                        w(esc(main))
                w('</pre>')
                w()

    emit_link_section(
        "Renamed Links or Those with Missing Targets",
        renamed_by_file,
        'target_missing',
        'Target Missing',
    )
    emit_link_section(
        "Linked File Location Heuristics Changes",
        location_by_file,
        'location_changed',
        'Location Changed',
    )
    emit_prose_section(
        "Stale Filenames and Their Derivatives in Prose",
        prose_by_file,
    )
    emit_tree_section(
        "Repo Root Tree Changes",
        trees_by_file,
    )
    emit_external_section(
        "External Data Root Tree Changes",
        external_by_file,
    )

    report_path.write_text('\n'.join(report) + '\n', encoding='utf-8')

    # Terminal output: top-level info only.
    print("\nReport summary:")
    print(f"- Mapping entries: {len(mapping)}")
    print(f"- Files scanned: {len(files)}")
    print()
    print("| Category                                              | Count |")
    print("|-------------------------------------------------------|------:|")
    print(f"| Total occurrences of stale file references            | {grand_total:>5} |")
    print(f"|   Renamed links or those with missing targets         | {renamed_total:>5} |")
    print(f"|   Linked file location or heuristics changes          | {location_total:>5} |")
    print(f"|   Stale filenames and their derivatives in prose      | {prose_total:>5} |")
    print(f"|   Repo root tree changes                              | {tree_total:>5} |")
    print(f"|   External data root tree changes                     | {external_total:>5} |")
    print()
    print(f"Report directory: {reports_dir}")
    print(f"Report file: {report_path}")

    # write diffs/patches only when requested
    if any_replacements:
        ts = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        if args.patch:
            combined_path = Path(args.patch)
            combined_text = '\n\n'.join(dt for _, dt in all_diffs)
            combined_path.parent.mkdir(parents=True, exist_ok=True)
            combined_path.write_text(combined_text, encoding='utf-8')
            print(f"\nWrote combined patch to {combined_path}")
        if args.diffs:
            diffs_dir = Path(args.diffs_dir) if args.diffs_dir else Path(f"/tmp/diffs/{filename_ts}")
            diffs_dir.mkdir(parents=True, exist_ok=True)
            for fname, dt in all_diffs:
                safe_name = fname.replace('/', '__')
                (diffs_dir / f"{safe_name}-{ts}.diff").write_text(dt, encoding='utf-8')
            print(f"Wrote individual diffs to {diffs_dir} (timestamp: {ts})")

    if not any_replacements:
        print("\nNo replacements performed.")


if __name__ == "__main__":
    main()
