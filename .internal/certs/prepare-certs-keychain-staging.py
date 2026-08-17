#!/usr/bin/env python3
"""Prepare Phase 3A certificate/Keychain staging support artifacts.

Location: .internal/certs/prepare-certs-keychain-staging.py

This helper is intentionally invoked by bin/stage-certs-keychain.sh so the
runbook can keep one user-facing command while using Python for staged-certs
config initialization, TSV cleanup, normalization, hashing, and dedupe. It may
also be run standalone with explicit arguments. It self-locates the repository
root from its own path, so it does not depend on a REIMAGE_ROOT variable.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, Iterator, List, Optional, Sequence, Tuple


# This helper lives at <REPO_ROOT>/.internal/certs/prepare-certs-keychain-staging.py,
# so the repository root is two levels up from this file.
REPO_ROOT = Path(__file__).resolve().parents[2]


ENV_KEYS = [
    "REIMAGE_WORKSPACE_ROOT",
]


def bash_output(script: str) -> bytes:
    return subprocess.check_output(["bash", "-lc", script], stderr=subprocess.STDOUT)


def load_env_values(env_file: Path) -> Dict[str, str]:
    if not env_file.is_file():
        raise SystemExit(f"Missing env file: {env_file}")

    script = "set -a\nsource {0}\nset +a\nenv -0\n".format(shlex.quote(str(env_file)))
    raw = bash_output(script)
    values: Dict[str, str] = {key: "" for key in ENV_KEYS}

    for chunk in raw.split(b"\0"):
        if not chunk or b"=" not in chunk:
            continue
        key_bytes, value_bytes = chunk.split(b"=", 1)
        key = key_bytes.decode("utf-8", errors="ignore")
        if key in values:
            values[key] = value_bytes.decode("utf-8", errors="ignore")

    return values


def ensure_absolute_path(name: str, value: str) -> None:
    if value == "":
        raise SystemExit(f"{name} is empty.")
    if not value.startswith("/"):
        raise SystemExit(f"{name} must be an absolute path: {value}")


def cmd_init_staged_certs_config(args: argparse.Namespace) -> int:
    values = load_env_values(Path(args.env_file))
    workspace_root = values["REIMAGE_WORKSPACE_ROOT"]

    ensure_absolute_path("REIMAGE_WORKSPACE_ROOT", workspace_root)

    templates_dir = REPO_ROOT / ".internal" / "templates" / "staged-certs"
    destination_dir = Path(workspace_root) / "staged-certs"

    if not templates_dir.is_dir():
        raise SystemExit(f"Missing staged-certs templates directory: {templates_dir}")

    destination_dir.mkdir(parents=True, exist_ok=True)

    copied = 0
    skipped = 0
    for source in sorted(templates_dir.glob("*.conf.sh")):
        dest = destination_dir / source.name
        if dest.exists() and not args.force:
            skipped += 1
            continue
        shutil.copy2(source, dest)
        copied += 1

    print(f"Workspace staged-certs directory: {destination_dir}")
    print(f"Copied: {copied}")
    print(f"Skipped existing: {skipped}")
    for path in sorted(destination_dir.glob("*.conf.sh")):
        print(path.name)
    return 0


PLAN_COLUMNS = [
    "record_id",
    "source_feed",
    "source_file",
    "source_kind",
    "source_scope",
    "identifier",
    "normalized_path",
    "repo",
    "ignored_path",
    "gitignored_kind",
    "category",
    "type",
    "recommended_action",
    "recommended_destination",
    "size_bytes",
    "modified",
    "identity_fingerprint",
    "file_sha256",
    "dedupe_key",
    "dedupe_status",
    "duplicate_of",
    "plan_scope",
    "proposed_decision",
    "requires_human",
    "reason",
    "notes",
]

TEN_COL_HEADERS = [
    "source_kind",
    "source_scope",
    "identifier",
    "category",
    "type",
    "recommended_action",
    "recommended_destination",
    "size_bytes",
    "modified",
    "notes",
]

STAT_TAIL_RE = re.compile(r"^(?P<path>.+?)\s+100[0-9a-fA-F]{8,}\s+\?\s+.*$")
BRACKET_FINGERPRINT_RE = re.compile(r"\[([A-Fa-f0-9]{32,128})\]")
HEX_FINGERPRINT_RE = re.compile(r"\b([A-Fa-f0-9]{40}|[A-Fa-f0-9]{64})\b")

CERTLIKE_SUFFIXES = (
    ".pem",
    ".crt",
    ".cer",
    ".der",
    ".p12",
    ".pfx",
    ".jks",
    ".keystore",
    ".truststore",
    ".key",
)
TRUSTSTORE_NAMES = {"cacerts", "jssecacerts"}
SECRET_CONFIG_SUFFIXES = (
    ".env",
    ".local",
    ".properties",
    ".yml",
    ".yaml",
    ".json",
    ".xml",
)
GENERATED_NOISE_MARKERS = (
    "/__pycache__/",
    "__pycache__/",
    "/.venv/",
    "/venv/",
    "venv/",
    ".pyc",
    ".pyo",
    "pyvenv.cfg",
)


@dataclass
class CleanStats:
    source_file: str
    input_rows: int = 0
    kept_rows: int = 0
    dropped_malformed_rows: int = 0
    dropped_blank_rows: int = 0


@dataclass
class PlanStats:
    added_records: int = 0
    duplicate_records: int = 0
    malformed_rows_dropped: int = 0
    filtered_generated_noise_rows: int = 0
    out_of_scope_secret_records: int = 0
    proposed_project_local_paths: int = 0
    manual_keychain_export_checklist_rows: int = 0
    cert_restore_note_rows: int = 0
    input_files_seen: List[str] = field(default_factory=list)
    cleaned_files_written: List[str] = field(default_factory=list)
    derived_files_written: List[str] = field(default_factory=list)
    missing_optional_inputs: List[str] = field(default_factory=list)


def now_stamp() -> str:
    return dt.datetime.now().strftime("%Y%m%d-%H%M%S")


def newest(directory: Path, pattern: str) -> Optional[Path]:
    matches = sorted(directory.glob(pattern), key=lambda p: p.stat().st_mtime if p.exists() else 0, reverse=True)
    return matches[0] if matches else None


def newest_any(directories: Sequence[Path], pattern: str) -> Optional[Path]:
    matches: List[Path] = []
    for directory in directories:
        if directory and directory.exists():
            matches.extend(directory.glob(pattern))
    matches.sort(key=lambda p: p.stat().st_mtime if p.exists() else 0, reverse=True)
    return matches[0] if matches else None


def read_tsv(path: Path) -> Tuple[List[str], List[List[str]]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        rows = list(reader)
    if not rows:
        return [], []
    return rows[0], rows[1:]


def write_tsv(path: Path, headers: Sequence[str], rows: Iterable[Sequence[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        writer.writerow(list(headers))
        for row in rows:
            writer.writerow(["" if value is None else str(value) for value in row])


def is_stat_tail_value(value: str) -> bool:
    return bool(STAT_TAIL_RE.match(value or ""))


def strip_stat_tail(value: str) -> str:
    match = STAT_TAIL_RE.match(value or "")
    return match.group("path") if match else value


def is_blank_row(row: Sequence[str]) -> bool:
    return not row or all(not str(cell).strip() for cell in row)


def is_malformed_stat_row(row: Sequence[str], expected_columns: int, identifier_index: int = 0) -> bool:
    if is_blank_row(row):
        return False
    if len(row) != expected_columns:
        # The broken GNU-stat rows in the path/size/modified report show up as a
        # single-column path followed by filesystem metadata.
        return any(is_stat_tail_value(cell) for cell in row)
    if 0 <= identifier_index < len(row) and is_stat_tail_value(row[identifier_index]):
        return True
    # Also reject rows where size/modified are blank because the malformed stat
    # output landed inside the identifier column.
    if expected_columns >= 3 and 0 <= identifier_index < len(row):
        if is_stat_tail_value(row[identifier_index]):
            return True
    return False


def clean_tsv(path: Path, out_dir: Path, identifier_index: int) -> Tuple[Path, CleanStats]:
    headers, rows = read_tsv(path)
    stats = CleanStats(source_file=path.name)
    expected = len(headers)
    cleaned: List[List[str]] = []
    for row in rows:
        stats.input_rows += 1
        if is_blank_row(row):
            stats.dropped_blank_rows += 1
            continue
        if is_malformed_stat_row(row, expected, identifier_index=identifier_index):
            stats.dropped_malformed_rows += 1
            continue
        if len(row) != expected:
            # Keep the plan safe by treating any other column-count mismatch as malformed.
            stats.dropped_malformed_rows += 1
            continue
        cleaned.append(row)
        stats.kept_rows += 1
    clean_path = out_dir / f"{path.stem}.clean.tsv"
    write_tsv(clean_path, headers, cleaned)
    return clean_path, stats


def path_hash(path_value: str) -> str:
    p = Path(path_value)
    try:
        if not p.is_file():
            return "-"
        h = hashlib.sha256()
        with p.open("rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()
    except (OSError, PermissionError):
        return "-"


def stat_path(path_value: str) -> Tuple[str, str]:
    try:
        st = os.stat(path_value)
        modified = dt.datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d %H:%M:%S")
        return str(st.st_size), modified
    except (OSError, ValueError):
        return "-", "-"


def extract_identity_fingerprint(identifier: str) -> str:
    match = BRACKET_FINGERPRINT_RE.search(identifier or "")
    if match:
        return match.group(1).upper()
    match = HEX_FINGERPRINT_RE.search(identifier or "")
    return match.group(1).upper() if match else "-"


def normalized_join(repo: str, ignored_path: str) -> str:
    if not repo:
        return ignored_path or "-"
    if os.path.isabs(ignored_path):
        return ignored_path
    return str(Path(repo) / ignored_path)


def classify_path(path_value: str) -> Tuple[str, str, str, str, str, str]:
    """Return category, type, action, plan_scope, proposed_decision, reason."""
    lower = (path_value or "").lower()
    base = Path(lower).name

    if any(marker in lower for marker in GENERATED_NOISE_MARKERS):
        return (
            "generated-noise",
            "generated-artifact",
            "likely-skip",
            "out-of-cert-scope",
            "skip-generated-noise",
            "Generated cache/venv artifact; do not stage for cert restore.",
        )

    if base in TRUSTSTORE_NAMES:
        if base == "jssecacerts":
            return (
                "java-trust-override",
                "jssecacerts",
                "review-truststore",
                "cert-keychain",
                "review-before-stage",
                "Java trust override candidate; keep only if local/custom and still required.",
            )
        return (
            "java-truststore",
            "cacerts",
            "likely-skip",
            "cert-keychain",
            "skip-stock-truststore-unless-custom",
            "Usually stock truststore material regenerated by reinstall.",
        )

    if lower.endswith(".key"):
        return (
            "private-key-or-key-extension",
            "key-file-candidate",
            "stage-if-needed",
            "cert-keychain",
            "review-before-stage",
            "Key extension requires content inspection before treating as private-key material.",
        )
    if lower.endswith((".p12", ".pfx")):
        return (
            "private-key-identity",
            "pkcs12",
            "stage-if-needed",
            "cert-keychain",
            "review-before-stage",
            "PKCS#12/PFX may include private-key identity material.",
        )
    if lower.endswith((".jks", ".keystore")):
        return (
            "java-keystore",
            "keystore-container",
            "stage-if-needed",
            "cert-keychain",
            "review-before-stage",
            "Java keystore may contain identities, trust material, or passwords.",
        )
    if lower.endswith(".truststore"):
        return (
            "truststore",
            "truststore-file",
            "review-truststore",
            "cert-keychain",
            "review-before-stage",
            "Truststore-like file; keep only if local/custom and still required.",
        )
    if lower.endswith((".pem", ".crt", ".cer", ".der")):
        return (
            "public-certificate",
            "certificate-or-chain",
            "review-public-cert",
            "cert-keychain",
            "document-or-stage-public-copy",
            "Likely public cert material; keep only if useful restore evidence or trust import material.",
        )

    secret_name_markers = ("credential", "credentials", "secret", "secrets", ".env", "application-local", "gradle-local", "vault.env", "reimage.env")
    if lower.endswith(SECRET_CONFIG_SUFFIXES) or any(marker in lower for marker in secret_name_markers):
        return (
            "secret-config",
            "ignored-secret-config",
            "out-of-cert-scope-secret",
            "out-of-cert-scope-secret",
            "cross-reference-only",
            "Secret-bearing config evidence; do not stage under certs unless it contains cert material.",
        )

    return (
        "unknown",
        "ignored-path",
        "review",
        "unknown",
        "review",
        "Unclassified input; review manually.",
    )


def row_record(**kwargs: str) -> Dict[str, str]:
    rec = {col: "-" for col in PLAN_COLUMNS}
    for k, v in kwargs.items():
        if k in rec:
            rec[k] = "-" if v is None or v == "" else str(v)
    return rec


def infer_dedupe_key(rec: Dict[str, str]) -> str:
    fingerprint = rec.get("identity_fingerprint", "-")
    normalized_path = rec.get("normalized_path", "-")
    file_sha = rec.get("file_sha256", "-")
    if fingerprint and fingerprint != "-":
        return f"identity:{fingerprint.upper()}"
    if file_sha and file_sha != "-":
        return f"file-sha256:{file_sha.lower()}"
    if normalized_path and normalized_path != "-":
        return f"path:{normalized_path}"
    return f"record:{rec.get('source_feed','-')}:{rec.get('identifier','-')}"


def add_dedupe(records: List[Dict[str, str]]) -> Tuple[List[Dict[str, str]], int]:
    seen: Dict[str, str] = {}
    duplicates = 0
    for idx, rec in enumerate(records, start=1):
        rec["record_id"] = f"CKP-{idx:05d}"
        key = infer_dedupe_key(rec)
        rec["dedupe_key"] = key
        if key in seen:
            rec["dedupe_status"] = "duplicate"
            rec["duplicate_of"] = seen[key]
            duplicates += 1
        else:
            rec["dedupe_status"] = "primary"
            rec["duplicate_of"] = "-"
            seen[key] = rec["record_id"]
    return records, duplicates


def normalize_ten_col(path: Path, source_feed: str, backup_root: str) -> List[Dict[str, str]]:
    headers, rows = read_tsv(path)
    if headers != TEN_COL_HEADERS:
        # Be tolerant but preserve by index if possible.
        pass
    records: List[Dict[str, str]] = []
    for row in rows:
        if len(row) != 10 or is_malformed_stat_row(row, 10, identifier_index=2):
            continue
        source_kind, source_scope, identifier, category, typ, action, dest, size, modified, notes = row
        normalized_path = identifier if source_kind == "filesystem" and identifier.startswith("/") else "-"
        sha = path_hash(normalized_path) if normalized_path != "-" else "-"
        fingerprint = extract_identity_fingerprint(identifier) if source_kind.startswith("keychain") else "-"
        plan_scope = "cert-keychain" if source_kind in {"filesystem", "keychain-identity", "keychain-certificate"} else "unknown"
        if action in {"manual-export-if-needed", "stage-if-needed", "review-truststore", "review-public-cert"}:
            proposed = "review-before-stage" if action != "manual-export-if-needed" else "manual-export-review"
            requires_human = "yes"
        elif action == "inventory-only":
            proposed = "document-only"
            requires_human = "no"
        elif action == "likely-skip":
            proposed = "skip"
            requires_human = "no"
        else:
            proposed = action or "review"
            requires_human = "yes"
        records.append(row_record(
            source_feed=source_feed,
            source_file=path.name,
            source_kind=source_kind,
            source_scope=source_scope,
            identifier=identifier,
            normalized_path=normalized_path,
            category=category,
            type=typ,
            recommended_action=action,
            recommended_destination=dest,
            size_bytes=size,
            modified=modified,
            identity_fingerprint=fingerprint,
            file_sha256=sha,
            plan_scope=plan_scope,
            proposed_decision=proposed,
            requires_human=requires_human,
            reason="Normalized from Phase 3A certificate/Keychain TSV feed.",
            notes=notes,
        ))
    return records


def normalize_cert_key_candidates(path: Path) -> List[Dict[str, str]]:
    headers, rows = read_tsv(path)
    records: List[Dict[str, str]] = []
    for row in rows:
        if len(row) != 3 or is_malformed_stat_row(row, 3, identifier_index=0):
            continue
        path_value, size, modified = row
        category, typ, action, scope, proposed, reason = classify_path(path_value)
        records.append(row_record(
            source_feed="cert-key-file-candidates",
            source_file=path.name,
            source_kind="filesystem",
            source_scope="path-scan",
            identifier=path_value,
            normalized_path=path_value,
            category=category,
            type=typ,
            recommended_action=action,
            recommended_destination="-",
            size_bytes=size,
            modified=modified,
            file_sha256=path_hash(path_value),
            plan_scope=scope,
            proposed_decision=proposed,
            requires_human="yes" if "review" in proposed or action.startswith("stage") else "no",
            reason=reason,
            notes="Normalized from loose cert/key candidate path report.",
        ))
    return records


def normalize_java_text(path: Path) -> List[Dict[str, str]]:
    records: List[Dict[str, str]] = []
    with path.open("r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if not line.startswith("/"):
                continue
            path_value = line
            if is_stat_tail_value(path_value):
                path_value = strip_stat_tail(path_value)
            size, modified = stat_path(path_value)
            category, typ, action, scope, proposed, reason = classify_path(path_value)
            records.append(row_record(
                source_feed="java-truststore-candidates",
                source_file=path.name,
                source_kind="java-truststore-text",
                source_scope="path-scan",
                identifier=path_value,
                normalized_path=path_value,
                category=category,
                type=typ,
                recommended_action=action,
                recommended_destination="-",
                size_bytes=size,
                modified=modified,
                file_sha256=path_hash(path_value),
                plan_scope=scope,
                proposed_decision=proposed,
                requires_human="yes" if action in {"review-truststore", "stage-if-needed"} else "no",
                reason=reason,
                notes="Normalized from Java truststore text report.",
            ))
    return records


def normalize_gitignored(path: Path, feed_name: str, backup_root: str = "") -> Tuple[List[Dict[str, str]], List[Dict[str, str]]]:
    """Normalize Git ignored-file feeds.

    Returns (plan_records, filtered_noise_records). The raw gitignored secret
    feed intentionally contains broad matches; generated cache/venv artifacts
    are written to a separate filtered-noise artifact instead of polluting the
    cert/Keychain plan.
    """
    headers, rows = read_tsv(path)
    records: List[Dict[str, str]] = []
    filtered_noise: List[Dict[str, str]] = []
    cert_project_destination = "$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/project-local/" if backup_root else "secrets-encrypted/certs/project-local/"
    out_of_scope_destination = "Phase 3C consolidated secrets DMG or selected ignored-file backup; not Phase 3A cert staging"

    for row in rows:
        if len(row) != 3:
            continue
        repo, ignored_path, kind = row
        normalized = normalized_join(repo, ignored_path)
        category, typ, action, scope, proposed, reason = classify_path(normalized)

        if feed_name == "gitignored-secret-candidates" and category == "generated-noise":
            filtered_noise.append(row_record(
                source_feed=feed_name,
                source_file=path.name,
                source_kind="gitignored",
                source_scope="filtered-generated-noise",
                identifier=normalized,
                normalized_path=normalized,
                repo=repo,
                ignored_path=ignored_path,
                gitignored_kind=kind,
                category=category,
                type=typ,
                recommended_action="filtered-out",
                recommended_destination="-",
                plan_scope="filtered-generated-noise",
                proposed_decision="drop-from-plan",
                requires_human="no",
                reason=reason,
                notes="Filtered from raw gitignored secret candidate feed before cert/Keychain planning.",
            ))
            continue

        recommended_destination = "-"
        requires_human = "yes" if scope == "cert-keychain" and action != "likely-skip" else "no"

        if feed_name == "gitignored-selected-nonsecret-candidates":
            category = "selected-nonsecret-ignored-file"
            typ = "nonsecret-ignored-selection"
            action = "handled-by-selected-ignored-files"
            scope = "out-of-cert-scope-nonsecret"
            proposed = "cross-reference-only"
            recommended_destination = "Selected ignored-file backup, not cert staging"
            requires_human = "no"
            reason = "Selected nonsecret ignored material; useful context but not cert staging input."
        elif feed_name == "gitignored-secret-candidates-refined" and scope == "cert-keychain" and normalized.lower().endswith(".keystore"):
            category = "java-keystore"
            typ = "keystore-container"
            action = "stage-if-needed"
            proposed = "propose-project-local-stage"
            recommended_destination = cert_project_destination
            requires_human = "yes"
            reason = "Refined gitignored secret feed identified a project-local .keystore; promote to proposed project-local staged-certs fragment for review."
        elif feed_name == "gitignored-secret-candidates-refined" and scope == "cert-keychain":
            recommended_destination = cert_project_destination
            reason = "Refined gitignored secret feed identified cert/key/truststore-like project-local material."
        elif scope == "out-of-cert-scope-secret":
            action = "out-of-cert-scope-secret"
            proposed = "cross-reference-only"
            recommended_destination = out_of_scope_destination
            requires_human = "no"
            if feed_name == "gitignored-secret-candidates-refined":
                reason = "Refined gitignored secret feed identified secret config; keep visible in the crosswalk but do not copy into cert staging."
            else:
                reason = "Raw gitignored secret feed identified secret config; keep visible in the crosswalk but do not copy into cert staging."

        size, modified = stat_path(normalized)
        records.append(row_record(
            source_feed=feed_name,
            source_file=path.name,
            source_kind="gitignored",
            source_scope=feed_name,
            identifier=normalized,
            normalized_path=normalized,
            repo=repo,
            ignored_path=ignored_path,
            gitignored_kind=kind,
            category=category,
            type=typ,
            recommended_action=action,
            recommended_destination=recommended_destination,
            size_bytes=size,
            modified=modified,
            file_sha256=path_hash(normalized),
            plan_scope=scope,
            proposed_decision=proposed,
            requires_human=requires_human,
            reason=reason,
            notes="Normalized from gitignored backup candidate feed.",
        ))
    return records, filtered_noise

def clean_known_inputs(review_dir: Path, clean_dir: Path, stats: PlanStats) -> Dict[str, Path]:
    clean_dir.mkdir(parents=True, exist_ok=True)
    cleaned: Dict[str, Path] = {}
    specs = [
        ("all-cert-keychain-discovery", "all-cert-keychain-discovery-*.tsv", 2),
        ("cert-key-file-candidates", "cert-key-file-candidates-*.tsv", 0),
        ("filesystem-cert-material", "filesystem-cert-material-*.tsv", 2),
        ("keychain-certificate-catalog", "keychain-certificate-catalog-*.tsv", 2),
        ("keychain-identity-catalog", "keychain-identity-catalog-*.tsv", 2),
        ("staging-candidates", "staging-candidates-*.tsv", 2),
        ("configured-staged-files", "configured-staged-files-*.tsv", 2),
        ("credential-file-candidates", "credential-file-candidates-*.tsv", 0),
    ]
    clean_stats: List[CleanStats] = []
    for key, pattern, identifier_index in specs:
        p = newest(review_dir, pattern)
        if not p:
            stats.missing_optional_inputs.append(pattern)
            continue
        stats.input_files_seen.append(str(p))
        clean_path, cs = clean_tsv(p, clean_dir, identifier_index=identifier_index)
        cleaned[key] = clean_path
        clean_stats.append(cs)
        stats.cleaned_files_written.append(str(clean_path))
        stats.malformed_rows_dropped += cs.dropped_malformed_rows

    summary_path = clean_dir / "clean-input-summary.md"
    with summary_path.open("w", encoding="utf-8") as f:
        f.write("# Cert/Keychain Clean Input Summary\n\n")
        f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("| Source file | Input rows | Kept rows | Dropped malformed rows | Dropped blank rows |\n")
        f.write("|---|---:|---:|---:|---:|\n")
        for cs in clean_stats:
            f.write(f"| `{cs.source_file}` | {cs.input_rows} | {cs.kept_rows} | {cs.dropped_malformed_rows} | {cs.dropped_blank_rows} |\n")
    stats.cleaned_files_written.append(str(summary_path))
    return cleaned



def bash_fragment_path(path_value: str) -> str:
    """Render a source path for a staged-certs shell fragment."""
    value = path_value or ""
    match = re.match(r"^/Users/[^/]+/(.+)$", value)
    if match:
        value = "$HOME/" + match.group(1)
    escaped = value.replace('\\', '\\\\').replace('"', '\\"')
    return f'"{escaped}"'


def write_filtered_noise(path: Path, rows: List[Dict[str, str]], stats: PlanStats) -> Optional[Path]:
    if not rows:
        return None
    headers = [
        "source_feed",
        "source_file",
        "repo",
        "ignored_path",
        "normalized_path",
        "gitignored_kind",
        "category",
        "type",
        "reason",
    ]
    write_tsv(path, headers, ([rec.get(col, "-") for col in headers] for rec in rows))
    stats.filtered_generated_noise_rows = len(rows)
    stats.derived_files_written.append(str(path))
    return path


def write_out_of_scope_secret_crosswalk(path: Path, records: List[Dict[str, str]], stats: PlanStats) -> Optional[Path]:
    rows = [
        rec for rec in records
        if rec.get("plan_scope") == "out-of-cert-scope-secret" and rec.get("dedupe_status") == "primary"
    ]
    if not rows:
        return None
    headers = [
        "record_id",
        "source_feed",
        "source_file",
        "repo",
        "ignored_path",
        "normalized_path",
        "gitignored_kind",
        "category",
        "type",
        "recommended_action",
        "recommended_destination",
        "proposed_decision",
        "reason",
    ]
    write_tsv(path, headers, ([rec.get(col, "-") for col in headers] for rec in rows))
    stats.out_of_scope_secret_records = len(rows)
    stats.derived_files_written.append(str(path))
    return path


def write_proposed_staged_certs(review_dir: Path, stamp: str, records: List[Dict[str, str]], stats: PlanStats) -> Optional[Path]:
    proposed_candidates = [
        rec for rec in records
        if rec.get("source_feed") == "gitignored-secret-candidates-refined"
        and rec.get("proposed_decision") == "propose-project-local-stage"
        and rec.get("normalized_path", "").lower().endswith(".keystore")
    ]
    proposed_rows: List[Dict[str, str]] = []
    seen_paths: set[str] = set()
    for rec in proposed_candidates:
        path_value = rec.get("normalized_path", "")
        if not path_value or path_value in seen_paths:
            continue
        seen_paths.add(path_value)
        proposed_rows.append(rec)
    proposed_dir = review_dir / "proposed-staged-certs"
    proposed_dir.mkdir(parents=True, exist_ok=True)
    fragment = proposed_dir / "project-local.conf.sh.proposed"
    with fragment.open("w", encoding="utf-8") as f:
        f.write("# Proposed Phase 3A project-local staged-certs fragment\n")
        f.write(f"# Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("# Source: prepare-certs-keychain-staging.py normalize/plan\n")
        f.write("#\n")
        f.write("# Review before use. Do not source this .proposed file directly.\n")
        f.write("# Copy approved entries into:\n")
        f.write("#   $REIMAGE_WORKSPACE_ROOT/staged-certs/project-local.conf.sh\n")
        f.write("# Then rerun:\n")
        f.write("#   ./bin/stage-certs-keychain.sh scan\n\n")
        f.write("STAGED_CERTS_PROJECT_LOCAL=(\n")
        for rec in proposed_rows:
            f.write(f"  {bash_fragment_path(rec.get('normalized_path', ''))}\n")
        f.write(")\n")
    stats.proposed_project_local_paths = len(proposed_rows)
    stats.derived_files_written.append(str(fragment))

    summary = proposed_dir / f"proposed-staged-certs-summary-{stamp}.md.proposed"
    with summary.open("w", encoding="utf-8") as f:
        f.write("# Proposed Staged-Certs Fragment Summary\n\n")
        f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"Proposed project-local paths: {len(proposed_rows)}\n\n")
        if proposed_rows:
            f.write("| Source feed | Proposed path | Reason |\n")
            f.write("|---|---|---|\n")
            for rec in proposed_rows:
                f.write(f"| `{rec.get('source_feed','-')}` | `{rec.get('normalized_path','-')}` | {rec.get('reason','-')} |\n")
        else:
            f.write("No refined `.keystore` project-local candidates were promoted in this run.\n")
    stats.derived_files_written.append(str(summary))
    return fragment



def should_include_for_restore_notes(rec: Dict[str, str]) -> bool:
    """Return True when a primary plan row should appear in proposed restore notes."""
    if rec.get("dedupe_status") != "primary":
        return False
    scope = rec.get("plan_scope", "")
    action = rec.get("recommended_action", "")
    decision = rec.get("proposed_decision", "")
    category = rec.get("category", "")
    if scope == "cert-keychain" and action in {"manual-export-if-needed", "stage-if-needed", "review-truststore", "review-public-cert"}:
        return True
    if decision in {"propose-project-local-stage", "manual-export-review", "review-before-stage", "document-or-stage-public-copy"}:
        return True
    if category in {"java-keystore", "private-key-identity", "java-trust-override", "private-key-or-key-extension"}:
        return True
    return False


def restore_plan_for_record(rec: Dict[str, str]) -> str:
    category = rec.get("category", "")
    typ = rec.get("type", "")
    action = rec.get("recommended_action", "")
    decision = rec.get("proposed_decision", "")
    if action == "manual-export-if-needed" or typ == "keychain-identity":
        return "If exported, import through Keychain Access only if still needed and policy allows; otherwise re-enroll/recreate through the managed corporate path."
    if category == "java-keystore" or typ == "keystore-container":
        return "Restore only to the specific project/tool path that still requires this keystore; password/alias must come from the approved password manager."
    if category in {"java-trust-override", "java-truststore"} or typ in {"jssecacerts", "truststore-container", "truststore-file"}:
        return "Restore only after the target JDK/JBR is installed and confirmed; validate with Maven/Gradle/internal HTTPS before keeping it."
    if category in {"private-key-identity", "private-key-or-key-extension", "private-key"}:
        return "Keep only inside encrypted staging/DMG; restore manually only when the target tool or project still needs it."
    if category == "public-certificate":
        return "Use as public trust/reference material only; import manually if an internal endpoint/tool still requires it after rebuild."
    if decision == "propose-project-local-stage":
        return "After review, copy approved path into the project-local staged-certs fragment, rerun Phase 3A scan, then Phase 3B and Phase 3C, and restore only to that project if still required."
    return "Review the normalized plan row before restoring; do not copy blindly."


def write_manual_keychain_export_checklist(review_dir: Path, stamp: str, records: List[Dict[str, str]], stats: PlanStats) -> Optional[Path]:
    rows = [
        rec for rec in records
        if rec.get("source_kind") == "keychain-identity"
        and rec.get("dedupe_status") == "primary"
    ]
    if not rows:
        return None
    rows.sort(key=lambda rec: (rec.get("identity_fingerprint", "-"), rec.get("identifier", "-")))
    # Distinct from keychain-detail's checklist. Both used to be named
    # keychain-manual-export-checklist-<stamp>.md.proposed, so a decisions/
    # listing mixed two different artifacts -- a candidate table from plan rows
    # and a per-identity checklist with delivery, issuer chain, and exportability
    # -- that looked like successive versions of one file and were not.
    out = review_dir / f"keychain-export-candidates-{stamp}.md.proposed"
    with out.open("w", encoding="utf-8") as f:
        f.write("# Proposed Keychain Export Candidates\n\n")
        f.write("Candidate list derived from the normalized plan. The authoritative per-identity record is `keychain-manual-export-checklist-*.md.proposed`, written by `stage-certs-keychain.sh keychain-detail`.\n\n")
        f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("This is a proposed review checklist generated from primary `keychain-identity` rows in the normalized Phase 3A plan. It is not proof that anything was exported. Review each identity in Keychain Access and export only what is still required.\n\n")
        f.write("Save any `.p12` / `.pfx` export password only in the approved password manager. Do not put passwords in this file, filenames, scripts, OneDrive, iCloud, or the backup folder.\n\n")
        f.write("| Status | Fingerprint | Scope | Identity | Proposed action | Export target | Password-manager entry | Restore source / notes |\n")
        f.write("|---|---|---|---|---|---|---|---|\n")
        for rec in rows:
            f.write(
                "| TODO_REVIEW | "
                f"`{rec.get('identity_fingerprint','-')}` | "
                f"`{rec.get('source_scope','-')}` | "
                f"`{rec.get('identifier','-')}` | "
                "Export only if still needed; otherwise document/re-enroll | "
                "`$REIMAGE_ARTIFACT_ROOT/secrets-encrypted/certs/keychain-manual-exports/` | "
                "TODO_ENTRY_NAME_OR_NA | "
                "TODO_RESTORE_SOURCE_OR_SKIP_REASON |\n"
            )
        f.write("\n## Sign-off\n\n")
        f.write("- [ ] Each listed identity was reviewed in Keychain Access.\n")
        f.write("- [ ] Exported `.p12` / `.pfx` files were saved only under `secrets-encrypted/certs/keychain-manual-exports/`.\n")
        f.write("- [ ] Public-only `.cer` / `.pem` exports were staged intentionally and do not contain private keys.\n")
        f.write("- [ ] Non-exportable managed identities were documented with their restore/re-enrollment source.\n")
        f.write("- [ ] Export passwords were saved only in the approved password manager.\n")
        f.write("- [ ] Phase 3B and then Phase 3C will be rerun after any new manual export is added.\n")
    stats.manual_keychain_export_checklist_rows = len(rows)
    stats.derived_files_written.append(str(out))
    return out


def write_cert_restore_notes(review_dir: Path, stamp: str, records: List[Dict[str, str]], stats: PlanStats) -> Optional[Path]:
    rows = [rec for rec in records if should_include_for_restore_notes(rec)]
    rows.sort(key=lambda rec: (rec.get("plan_scope", "-"), rec.get("category", "-"), rec.get("normalized_path", rec.get("identifier", "-"))))
    out = review_dir / f"cert-restore-notes-{stamp}.md.proposed"
    with out.open("w", encoding="utf-8") as f:
        f.write("# Proposed Certificate and Keychain Restore Notes\n\n")
        f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("These notes are generated from the primary rows of the normalized Phase 3A plan. They are proposed restore notes only; review them before copying any text into a final restore note or before restoring any certificate material.\n\n")
        f.write("## Restore principles\n\n")
        f.write("1. Restore from the newest validated `all-secrets-*.dmg`, not from loose plaintext staging.\n")
        f.write("2. Restore cert/key material only when a tool, project, Java runtime, VPN/client-auth flow, or internal TLS endpoint still requires it after rebuild.\n")
        f.write("3. Treat `.p12`, `.pfx`, `.jks`, `.keystore`, and `*.key` as secret-bearing.\n")
        f.write("4. Re-enroll managed/non-exportable identities through MDM, Company Portal, VPN/client certificate enrollment, certificate profile enrollment, or IT support.\n")
        f.write("5. Keep export/import passwords only in the approved password manager.\n\n")
        if not rows:
            f.write("No primary cert/keychain restore candidates were found in this plan.\n")
        else:
            f.write("## Candidate restore rows\n\n")
            f.write("| Plan row | Source | Category | Identifier or path | Proposed decision | Restore guidance |\n")
            f.write("|---|---|---|---|---|---|\n")
            for rec in rows:
                ident = rec.get("normalized_path", "-")
                if ident == "-":
                    ident = rec.get("identifier", "-")
                f.write(
                    f"| `{rec.get('record_id','-')}` | "
                    f"`{rec.get('source_feed','-')}` | "
                    f"`{rec.get('category','-')}` | "
                    f"`{ident}` | "
                    f"`{rec.get('proposed_decision','-')}` | "
                    f"{restore_plan_for_record(rec)} |\n"
                )
        f.write("\n## Finalize after review\n\n")
        f.write("- [ ] Remove rows that were intentionally skipped.\n")
        f.write("- [ ] Replace generic guidance with exact restore targets where known.\n")
        f.write("- [ ] Confirm the newest Phase 3C DMG contains any manually exported or staged files referenced here.\n")
        f.write("- [ ] Keep this as a proposed note until the cert/keychain plan is reviewed.\n")
    stats.cert_restore_note_rows = len(rows)
    stats.derived_files_written.append(str(out))
    return out

def build_plan(args: argparse.Namespace) -> Tuple[Path, Path, Path]:
    backup_root = Path(args.artifact_root).expanduser() if args.artifact_root else None
    review_dir = Path(args.review_dir).expanduser() if args.review_dir else (backup_root / "secrets-encrypted" / "extra-secrets-certs-review")
    gitignore_dir = Path(args.gitignore_dir).expanduser() if args.gitignore_dir else (backup_root / "gitignore-superset" if backup_root else review_dir)
    stamp = args.stamp or now_stamp()

    # By-function layout under the review dir: scan writes its reports to
    # discovery/, the plan writes its outputs to plan/, and the human-facing
    # docs (checklist, restore notes) go to decisions/.
    discovery_dir = review_dir / "discovery"
    plan_dir = review_dir / "plan"
    decisions_dir = review_dir / "decisions"
    plan_dir.mkdir(parents=True, exist_ok=True)
    decisions_dir.mkdir(parents=True, exist_ok=True)

    clean_dir = plan_dir / f"cleaned-inputs-{stamp}"
    stats = PlanStats()
    cleaned = clean_known_inputs(discovery_dir, clean_dir, stats)

    records: List[Dict[str, str]] = []

    for key in ["keychain-identity-catalog", "keychain-certificate-catalog", "filesystem-cert-material", "staging-candidates", "all-cert-keychain-discovery"]:
        p = cleaned.get(key)
        if p:
            # Include staging-candidates and all-discovery for crosswalk only? For now include all feeds;
            # dedupe will mark repeated identities/paths as duplicates.
            records.extend(normalize_ten_col(p, key, str(backup_root or "")))

    p = cleaned.get("cert-key-file-candidates")
    if p:
        records.extend(normalize_cert_key_candidates(p))

    java = newest(discovery_dir, "java-truststore-candidates-*.txt")
    if java:
        stats.input_files_seen.append(str(java))
        records.extend(normalize_java_text(java))
    else:
        stats.missing_optional_inputs.append("java-truststore-candidates-*.txt")

    # Gitignore feeds may be under gitignore_dir in the real backup root. For uploaded/test fixtures,
    # allow them to be colocated with review_dir.
    filtered_noise_records: List[Dict[str, str]] = []
    git_dirs = [gitignore_dir, review_dir]
    for feed, pattern in [
        ("gitignored-secret-candidates-refined", "gitignored-secret-candidates-refined.tsv"),
        ("gitignored-secret-candidates", "gitignored-secret-candidates.tsv"),
        ("gitignored-selected-nonsecret-candidates", "gitignored-selected-nonsecret-candidates.tsv"),
    ]:
        gp = newest_any(git_dirs, pattern)
        if gp:
            stats.input_files_seen.append(str(gp))
            git_records, noise = normalize_gitignored(gp, feed, str(backup_root or ""))
            records.extend(git_records)
            filtered_noise_records.extend(noise)
        else:
            stats.missing_optional_inputs.append(pattern)

    records, duplicate_count = add_dedupe(records)
    stats.added_records = len(records)
    stats.duplicate_records = duplicate_count

    write_filtered_noise(
        plan_dir / f"gitignored-secret-generated-noise-filtered-{stamp}.tsv",
        filtered_noise_records,
        stats,
    )
    write_out_of_scope_secret_crosswalk(
        plan_dir / f"out-of-cert-scope-secret-material-{stamp}.tsv",
        records,
        stats,
    )
    write_proposed_staged_certs(plan_dir, stamp, records, stats)
    write_manual_keychain_export_checklist(decisions_dir, stamp, records, stats)
    write_cert_restore_notes(decisions_dir, stamp, records, stats)

    out_plan = plan_dir / f"cert-keychain-normalized-plan-{stamp}.tsv"
    write_tsv(out_plan, PLAN_COLUMNS, ([rec[col] for col in PLAN_COLUMNS] for rec in records))

    primary_plan = plan_dir / f"cert-keychain-normalized-plan-primary-{stamp}.tsv"
    write_tsv(primary_plan, PLAN_COLUMNS, ([rec[col] for col in PLAN_COLUMNS] for rec in records if rec.get("dedupe_status") == "primary"))

    summary = plan_dir / f"cert-keychain-normalized-plan-summary-{stamp}.md"
    write_summary(summary, out_plan, primary_plan, records, stats)
    return out_plan, primary_plan, summary


def write_summary(path: Path, full_plan: Path, primary_plan: Path, records: List[Dict[str, str]], stats: PlanStats) -> None:
    def count_by(field: str) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        for rec in records:
            value = rec.get(field, "-") or "-"
            counts[value] = counts.get(value, 0) + 1
        return dict(sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])))

    with path.open("w", encoding="utf-8") as f:
        f.write("# Cert/Keychain Normalized Plan Summary\n\n")
        f.write(f"Generated: {dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("## Outputs\n\n")
        f.write(f"- Full normalized plan: `{full_plan.name}`\n")
        f.write(f"- Primary-only normalized plan: `{primary_plan.name}`\n")
        f.write("\n## Cleanup and dedupe\n\n")
        f.write(f"- Records written: {stats.added_records}\n")
        f.write(f"- Duplicate records marked: {stats.duplicate_records}\n")
        f.write(f"- Malformed rows dropped from cleaned inputs: {stats.malformed_rows_dropped}\n")
        f.write(f"- Cleaned input files written: {len(stats.cleaned_files_written)}\n")
        f.write(f"- Derived planning artifacts written: {len(stats.derived_files_written)}\n")
        f.write(f"- Raw gitignored generated-noise rows filtered out: {stats.filtered_generated_noise_rows}\n")
        f.write(f"- Out-of-cert-scope secret records cross-referenced: {stats.out_of_scope_secret_records}\n")
        f.write(f"- Refined `.keystore` paths proposed for project-local staging: {stats.proposed_project_local_paths}\n")
        f.write(f"- Manual Keychain export checklist rows proposed: {stats.manual_keychain_export_checklist_rows}\n")
        f.write(f"- Cert restore note rows proposed: {stats.cert_restore_note_rows}\n")
        if stats.derived_files_written:
            f.write("\n## Derived planning artifacts\n\n")
            for item in stats.derived_files_written:
                f.write(f"- `{item}`\n")
        f.write("\n## Counts by source feed\n\n")
        f.write("| Source feed | Count |\n|---|---:|\n")
        for value, count in count_by("source_feed").items():
            f.write(f"| `{value}` | {count} |\n")
        f.write("\n## Counts by plan scope\n\n")
        f.write("| Plan scope | Count |\n|---|---:|\n")
        for value, count in count_by("plan_scope").items():
            f.write(f"| `{value}` | {count} |\n")
        f.write("\n## Counts by proposed decision\n\n")
        f.write("| Proposed decision | Count |\n|---|---:|\n")
        for value, count in count_by("proposed_decision").items():
            f.write(f"| `{value}` | {count} |\n")
        if stats.missing_optional_inputs:
            f.write("\n## Missing optional inputs\n\n")
            for item in stats.missing_optional_inputs:
                f.write(f"- `{item}`\n")
        f.write("\n## Input files seen\n\n")
        for item in stats.input_files_seen:
            f.write(f"- `{item}`\n")
        f.write("\n## Cleaned files written\n\n")
        for item in stats.cleaned_files_written:
            f.write(f"- `{item}`\n")


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare Phase 3A cert/Keychain staging config and normalized planning artifacts."
    )
    sub = parser.add_subparsers(dest="command")

    init = sub.add_parser(
        "init-staged-certs-config",
        help="Copy staged-certs template fragments into REIMAGE_WORKSPACE_ROOT for Phase 3A reuse.",
    )
    init.add_argument("--env-file", required=True, help="Path to reimage.env.")
    init.add_argument("--force", action="store_true", help="Overwrite existing workspace staged-certs fragments.")

    normalize = sub.add_parser("normalize", help="Create cleaned inputs and normalized plan TSVs.")
    normalize.add_argument("--artifact-root", help="Artifact root containing secrets-encrypted/ and gitignore-superset/.")
    normalize.add_argument("--review-dir", help="Override extra-secrets-certs-review directory.")
    normalize.add_argument("--gitignore-dir", help="Override gitignore-superset directory.")
    normalize.add_argument("--stamp", help="Optional output timestamp for deterministic testing.")
    args = parser.parse_args(argv)
    if not args.command:
        parser.print_help(sys.stderr)
        raise SystemExit(2)
    if args.command == "normalize" and not args.artifact_root and not args.review_dir:
        parser.error("normalize requires --artifact-root or --review-dir")
    return args


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    if args.command == "init-staged-certs-config":
        return cmd_init_staged_certs_config(args)
    if args.command == "normalize":
        full_plan, primary_plan, summary = build_plan(args)
        print(f"Normalized cert/Keychain plan: {full_plan}")
        print(f"Primary-only plan: {primary_plan}")
        print(f"Summary: {summary}")
        return 0
    raise SystemExit(f"unsupported command: {args.command}")


if __name__ == "__main__":
    raise SystemExit(main())
