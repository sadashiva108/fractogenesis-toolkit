#!/usr/bin/env python3
"""
Entrypoint for prepare-artifact-root.md.

This script keeps the longer environment rewrite, artifact-root creation,
verification, and workspace-config copy logic out of the Markdown guide.
It writes resolved export values back into reimage.env while preserving
unrelated comments and lines in the file, and it reads artifact-config.sh
when Phase 1 needs the shared expected artifact-folder layout.

REIMAGE_ROOT was retired as an env var. This script self-locates instead
(REPO_ROOT below), matching artifact-config.sh's existing SCRIPT_DIR pattern.
Nothing needs to be filled in for this in reimage.env anymore.
"""

from __future__ import annotations

import argparse
import datetime as dt
import filecmp
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple


# This script lives at <repo>/bin/prepare-artifact-root.py, so the repo root
# is one level up. Self-locating this way means reimage.env never needs to
# carry a path to the repo itself — it's always correct regardless of where
# the repo is checked out or moved.
REPO_ROOT = Path(__file__).resolve().parent.parent

PATH_KEYS = {
    "REIMAGE_WORKSPACE_ROOT",
    "PERFORMANCE_HISTORY_SOURCE",
    "EXTERNAL_DATA_VOLUME",
    "EXTERNAL_APPLE_BACKUPS_VOLUME",
    "REIMAGE_ARTIFACT_ROOT",
    "OFFICE_WATCH",
    "ONEDRIVE_ROOT",
    "GIT_WORK_REPO_ROOT",
    "GIT_PERSONAL_REPO_ROOT",
    "GIT_WORK_SSH_KEY",
    "GIT_PERSONAL_SSH_KEY",
}

ENV_KEYS = [
    "REIMAGE_WORKSPACE_ROOT",
    "PERFORMANCE_HISTORY_SOURCE",
    "EXTERNAL_DATA_VOLUME",
    "EXTERNAL_APPLE_BACKUPS_VOLUME",
    "ASSET_OR_HOST",
    "REIMAGE_START_DATE",
    "REIMAGE_ARTIFACT_ROOT",
    "OFFICE_WATCH",
    "ONEDRIVE_FOLDER_NAME",
    "ONEDRIVE_PARENT_DIR",
    "ONEDRIVE_ROOT",
    "ONEDRIVE_DEST_SUBDIR",
    "GIT_WORK_REPO_ROOT",
    "GIT_PERSONAL_REPO_ROOT",
]

LITERAL_PATH_MARKERS = (
    "$HOME",
    "${HOME}",
    "$EXTERNAL_DATA_VOLUME",
    "${EXTERNAL_DATA_VOLUME}",
    "$EXTERNAL_APPLE_BACKUPS_VOLUME",
    "${EXTERNAL_APPLE_BACKUPS_VOLUME}",
    "$ASSET_OR_HOST",
    "${ASSET_OR_HOST}",
    "$REIMAGE_START_DATE",
    "${REIMAGE_START_DATE}",
    "$REIMAGE_WORKSPACE_ROOT",
    "${REIMAGE_WORKSPACE_ROOT}",
)


def detect_asset_or_host() -> str:
    commands: List[List[str]] = [
        ["scutil", "--get", "LocalHostName"],
        ["hostname", "-s"],
    ]
    for command in commands:
        try:
            value = subprocess.check_output(
                command,
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
        except Exception:
            continue
        if value:
            return value
    # Never return the "<asset-or-host>" placeholder. It used to be returned
    # here and nothing downstream caught it: LITERAL_PATH_MARKERS carries no
    # "<...>" entry, so contains_literal_path() passed it through and
    # REIMAGE_ARTIFACT_ROOT became a real, placeholder-named directory that
    # both validators accepted.
    raise SystemExit(
        "ERROR: Could not detect an asset tag or hostname for this Mac.\n"
        "       Both `scutil --get LocalHostName` and `hostname -s` failed or returned nothing.\n"
        "       Rerun with an explicit value, e.g. --asset-or-host MACBOOK-1234"
    )


def require_workspace_root(workspace_root: str, origin: str) -> str:
    # There is no sensible default here. The workspace holds the artifact-config
    # and staged-certs fragments every later script reads, so guessing a path
    # that does not exist makes those loaders fall back to the repository's
    # generic templates and the run continues against placeholder targets.
    # Fail loudly instead; REIMAGE_WORKSPACE_ROOT is a required export.
    value = (workspace_root or "").strip()
    if not value:
        raise SystemExit(
            "ERROR: REIMAGE_WORKSPACE_ROOT is not set.\n"
            f"       Expected from {origin}.\n"
            "       Export it before running, e.g. export REIMAGE_WORKSPACE_ROOT=\"$HOME/<workspace-dir>\""
        )
    return value


def normalize_value(key: str, value: str) -> str:
    if key in PATH_KEYS and value not in {"", "/"}:
        return value.rstrip("/")
    return value


def quote_value(value: str) -> str:
    return shlex.quote(value)


def update_env_exports(env_path: Path, updates: Dict[str, str]) -> None:
    normalized = {key: normalize_value(key, value) for key, value in updates.items()}
    lines = env_path.read_text(encoding="utf-8").splitlines()
    out: List[str] = []
    seen = set()

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("export ") and "=" in stripped:
            key = stripped.split("=", 1)[0].replace("export ", "").strip()
            if key in normalized:
                out.append("export {0}={1}".format(key, quote_value(normalized[key])))
                seen.add(key)
                continue
        out.append(line)

    for key, value in normalized.items():
        if key not in seen:
            out.append("export {0}={1}".format(key, quote_value(value)))

    env_path.write_text("\n".join(out) + "\n", encoding="utf-8")


def parse_assignment(text: str) -> Tuple[str, str]:
    if "=" not in text:
        raise SystemExit("Expected KEY=VALUE assignment, got: {0}".format(text))
    key, value = text.split("=", 1)
    key = key.strip()
    if not key:
        raise SystemExit("Assignment is missing a key: {0}".format(text))
    return key, value


def bash_output(script: str) -> bytes:
    # Deliberately NOT a login shell (-l): a login shell sources
    # .zprofile/.bash_profile -> .zshrc/.bashrc, which can print startup
    # noise (SDKMAN's "Setting candidates csv: ..." banner is a confirmed
    # real example) directly into this function's output stream, silently
    # corrupting the parsed values downstream. source/reimage.env loading
    # is done explicitly in the script text passed in, so a login shell
    # was never actually required.
    #
    # stderr is captured separately and re-emitted to this process's stderr —
    # never merged into the returned stream. artifact-config.sh writes a
    # two-line WARNING to stderr whenever REIMAGE_WORKSPACE_ROOT is set but
    # carries no artifact-config directory; merging it made those lines the
    # first entry of the NUL-delimited folder list, so create-standard-layout
    # built a nested junk directory tree from the warning text and never
    # created the real first folder. The warning still has to reach the user,
    # so it is forwarded rather than discarded.
    completed = subprocess.run(
        ["bash", "-c", script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if completed.stderr:
        sys.stderr.buffer.write(completed.stderr)
        sys.stderr.flush()
    if completed.returncode != 0:
        raise subprocess.CalledProcessError(
            completed.returncode,
            completed.args,
            output=completed.stdout,
            stderr=completed.stderr,
        )
    return completed.stdout


def load_env_values(env_file: Path) -> Dict[str, str]:
    if not env_file.is_file():
        raise SystemExit(f"Missing env file: {env_file}")

    script = "set +u\nset -a\nsource {0}\nset +a\nenv -0\n".format(shlex.quote(str(env_file)))
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


def load_expected_artifact_folders(env_file: Path, repo_root: str) -> List[str]:
    config_path = Path(repo_root) / ".internal" / "artifact-config.sh"
    script = "\n".join(
        [
            f"set +u",
            f"set -a",
            f"source {shlex.quote(str(env_file))}",
            "set +a",
            "ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false",
            f"source {shlex.quote(str(config_path))}",
            'printf "%s\\0" "${EXPECTED_ARTIFACT_FOLDERS[@]}"',
        ]
    )
    raw = bash_output(script)
    folders = [item.decode("utf-8", errors="ignore") for item in raw.split(b"\0") if item]
    # Create in alphabetical order regardless of how the fragment lists them, so
    # the directory reads predictably and a reordered fragment cannot change the
    # on-disk creation order.
    return sorted(set(folders))


def load_artifact_config_source_dir(env_file: Path, repo_root: str) -> str:
    config_path = Path(repo_root) / ".internal" / "artifact-config.sh"
    script = "\n".join(
        [
            f"set +u",
            f"set -a",
            f"source {shlex.quote(str(env_file))}",
            "set +a",
            "ARTIFACT_CONFIG_REQUIRE_REIMAGE_ARTIFACT_ROOT=false",
            f"source {shlex.quote(str(config_path))}",
            'printf "%s" "${ARTIFACT_CONFIG_SOURCE_DIR:-}"',
        ]
    )
    return bash_output(script).decode("utf-8", errors="ignore").strip()


def contains_literal_path(value: str) -> bool:
    return any(marker in value for marker in LITERAL_PATH_MARKERS)


def require_resolved_path(name: str, value: str, *, allow_empty: bool = False) -> None:
    if value == "":
        if allow_empty:
            return
        raise SystemExit(f"{name} is empty.")
    if contains_literal_path(value):
        raise SystemExit(f"{name} contains literal variable text instead of a resolved path: {value}")


def ensure_absolute_path(name: str, value: str, *, allow_empty: bool = False) -> None:
    require_resolved_path(name, value, allow_empty=allow_empty)
    if value and not value.startswith("/"):
        raise SystemExit(f"{name} must be an absolute path: {value}")


def ensure_artifact_root_under_external(external_data_volume: str, artifact_root: str) -> None:
    external = external_data_volume.rstrip("/")
    artifact = artifact_root.rstrip("/")
    if artifact == "":
        raise SystemExit("REIMAGE_ARTIFACT_ROOT is empty. Recheck reimage.env.")
    if contains_literal_path(artifact):
        raise SystemExit(
            "REIMAGE_ARTIFACT_ROOT contains literal variable text instead of a resolved path. Rewrite it in reimage.env first."
        )
    if not artifact.startswith(external + "/"):
        raise SystemExit(
            "REIMAGE_ARTIFACT_ROOT is not under EXTERNAL_DATA_VOLUME.\n"
            f"Expected prefix: {external}/\n"
            f"Actual REIMAGE_ARTIFACT_ROOT: {artifact}"
        )


def print_env_summary(values: Dict[str, str]) -> None:
    for key in [
        "REIMAGE_WORKSPACE_ROOT",
        "PERFORMANCE_HISTORY_SOURCE",
        "EXTERNAL_DATA_VOLUME",
        "EXTERNAL_APPLE_BACKUPS_VOLUME",
        "ASSET_OR_HOST",
        "REIMAGE_START_DATE",
        "REIMAGE_ARTIFACT_ROOT",
        "OFFICE_WATCH",
        "ONEDRIVE_ROOT",
    ]:
        print(f"{key}={values.get(key, '')}")


def write_test_file(root: Path, prefix: str) -> None:
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    test_file = root / f"{prefix}-{stamp}.txt"
    test_file.write_text(dt.datetime.now().isoformat() + "\n", encoding="utf-8")
    print(test_file.read_text(encoding="utf-8").strip())
    test_file.unlink()


def print_ls(path: Path) -> None:
    command = ["/bin/ls", "-la", str(path)]
    try:
        subprocess.run(command, check=False)
    except Exception:
        subprocess.run(["ls", "-la", str(path)], check=False)


def ensure_workspace_dirs(*paths: str) -> None:
    for path in paths:
        if path:
            Path(path).mkdir(parents=True, exist_ok=True)


DEFAULT_ONEDRIVE_PARENT_DIR = str(Path.home() / "Library" / "CloudStorage")


def resolve_onedrive_root(onedrive_folder_name: str, onedrive_parent_dir: str = "") -> str:
    # OneDrive is optional. When a folder name is supplied, resolve the full
    # path the same way REIMAGE_ARTIFACT_ROOT is built from parts, so
    # reimage.env stores a resolved absolute path — never a bare folder name
    # (which older scripts could treat as relative to the cwd) or a literal
    # "$HOME/..." string. Return "" to leave OneDrive unconfigured.
    #
    # macOS puts file-provider mounts under ~/Library/CloudStorage, which is the
    # default parent. It is a default and not an assumption: an unmanaged or
    # relocated sync folder lives elsewhere, so onedrive_parent_dir overrides it.
    name = onedrive_folder_name.strip()
    if not name:
        return ""
    parent = (onedrive_parent_dir or "").strip() or DEFAULT_ONEDRIVE_PARENT_DIR
    return str(Path(parent).expanduser() / name)


def create_onedrive_destination(onedrive_root: str, onedrive_dest_subdir: str) -> None:
    # Pre-create the per-reimage OneDrive destination that mirrors the
    # artifact-root name — but only when the CloudStorage root already exists
    # (OneDrive signed in). Creating it otherwise would make a plain local
    # folder that never syncs (the accidental-relative-folder failure), so leave
    # it for the signed-in backup run instead.
    if not onedrive_root:
        return
    print(f"ONEDRIVE_ROOT={onedrive_root}")
    root_path = Path(onedrive_root)
    if root_path.is_dir():
        destination = root_path / onedrive_dest_subdir
        destination.mkdir(parents=True, exist_ok=True)
        print(f"OK: OneDrive destination ready: {destination}")
    else:
        print(f"NOTE: OneDrive root not found yet: {onedrive_root}")
        print("      Sign in to OneDrive so CloudStorage creates it; the backup will create the destination on first run.")


def resolve_it_plan_source(explicit_source: str, values: Dict[str, str], workspace_root_override: str = "") -> Path:
    if explicit_source:
        source = Path(explicit_source).expanduser()
        if not source.is_file():
            raise SystemExit(f"IT plan source file not found: {source}")
        return source

    # Locate the filled note under REIMAGE_WORKSPACE_ROOT/reimage-confirmation.
    workspace_root = require_workspace_root(
        workspace_root_override or values.get("REIMAGE_WORKSPACE_ROOT", ""),
        "--workspace-root or REIMAGE_WORKSPACE_ROOT in reimage.env",
    )
    search_root = str(Path(workspace_root) / "reimage-confirmation")
    search_path = Path(search_root).expanduser()
    if not search_path.is_dir():
        raise SystemExit(
            "IT plan source directory does not exist yet: {0}\n"
            "Fill the Phase 0 IT confirmation first, or rerun this helper with --source /absolute/path/to/it-reimage-confirmation-YYYYMMDD.md".format(
                search_path
            )
        )

    candidates = sorted(search_path.glob("it-reimage-confirmation-*.md"), key=lambda path: path.stat().st_mtime)
    if not candidates:
        raise SystemExit(
            "No filled IT confirmation was found under: {0}\n"
            "Create it during Phase 0, or rerun this helper with --source /absolute/path/to/it-reimage-confirmation-YYYYMMDD.md".format(
                search_path
            )
        )
    return candidates[-1]


def cmd_init_reimage_env(args: argparse.Namespace) -> int:
    workspace_root = require_workspace_root(args.workspace_root, "--workspace-root")
    confirmation_dir = str(Path(workspace_root) / "reimage-confirmation")
    asset_or_host = args.asset_or_host or detect_asset_or_host()
    reimage_start_date = args.reimage_start_date or dt.datetime.now().strftime("%Y%m%d")
    external_data_volume = args.external_data_volume.rstrip("/")
    reimage_artifact_root = f"{external_data_volume}/reimage-{asset_or_host}-{reimage_start_date}-open"
    onedrive_dest_subdir = Path(reimage_artifact_root).name
    onedrive_folder_name = args.onedrive_folder_name.strip()
    onedrive_parent_dir = (
        args.onedrive_parent_dir.strip() or DEFAULT_ONEDRIVE_PARENT_DIR
    )
    onedrive_root = resolve_onedrive_root(onedrive_folder_name, onedrive_parent_dir)

    updates = {
        "REIMAGE_WORKSPACE_ROOT": workspace_root,
        "PERFORMANCE_HISTORY_SOURCE": args.performance_history_source,
        "EXTERNAL_DATA_VOLUME": external_data_volume,
        "EXTERNAL_APPLE_BACKUPS_VOLUME": args.external_apple_backups_volume,
        "ASSET_OR_HOST": asset_or_host,
        "REIMAGE_START_DATE": reimage_start_date,
        "REIMAGE_ARTIFACT_ROOT": reimage_artifact_root,
        "OFFICE_WATCH": "",
        "ONEDRIVE_FOLDER_NAME": onedrive_folder_name,
        "ONEDRIVE_PARENT_DIR": onedrive_parent_dir,
        "ONEDRIVE_ROOT": onedrive_root,
        "ONEDRIVE_DEST_SUBDIR": onedrive_dest_subdir,
    }
    update_env_exports(args.env_file, updates)
    ensure_workspace_dirs(workspace_root, confirmation_dir)
    print(f"ASSET_OR_HOST={asset_or_host}")
    print(f"REIMAGE_START_DATE={reimage_start_date}")
    print(f"REIMAGE_ARTIFACT_ROOT={reimage_artifact_root}")
    create_onedrive_destination(onedrive_root, onedrive_dest_subdir)
    return 0


def cmd_upsert_env(args: argparse.Namespace) -> int:
    updates: Dict[str, str] = {}
    for assignment in args.assignment:
        key, value = parse_assignment(assignment)
        updates[key] = value
    update_env_exports(args.env_file, updates)
    return 0


def cmd_create_artifact_root(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    external_data_volume = values["EXTERNAL_DATA_VOLUME"].rstrip("/")
    artifact_root = values["REIMAGE_ARTIFACT_ROOT"].rstrip("/")

    print(f"EXTERNAL_DATA_VOLUME=<{external_data_volume}>")
    print(f"REIMAGE_ARTIFACT_ROOT=<{artifact_root}>")

    ensure_absolute_path("EXTERNAL_DATA_VOLUME", external_data_volume)
    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", artifact_root)
    ensure_artifact_root_under_external(external_data_volume, artifact_root)

    try:
        Path(artifact_root).mkdir(parents=True, exist_ok=True)
    except PermissionError as exc:
        raise SystemExit(
            "Permission denied while creating REIMAGE_ARTIFACT_ROOT.\n"
            "Use the troubleshooting repair helper:\n"
            f"  python3 bin/prepare-artifact-root.py repair-artifact-root-perms --env-file {args.env_file}\n"
            f"Underlying error: {exc}"
        ) from exc
    except OSError as exc:
        if exc.errno == 1:
            raise SystemExit(
                "Operation not permitted while creating REIMAGE_ARTIFACT_ROOT.\n"
                "Check Terminal privacy / Full Disk Access, then rerun this helper."
            ) from exc
        raise

    print("OK: REIMAGE_ARTIFACT_ROOT is under EXTERNAL_DATA_VOLUME")
    print(f"OK: artifact root exists: {artifact_root}")
    write_test_file(Path(artifact_root), "write-test")
    print_ls(Path(artifact_root))
    return 0


def cmd_repair_artifact_root_perms(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    artifact_root = values["REIMAGE_ARTIFACT_ROOT"].rstrip("/")

    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", artifact_root)
    if contains_literal_path(artifact_root):
        raise SystemExit(f"REIMAGE_ARTIFACT_ROOT still contains literal variable text: {artifact_root}")

    current_uid = str(os.getuid())
    current_gid = str(os.getgid())

    print(f"REIMAGE_ARTIFACT_ROOT={artifact_root}")
    print(f"CURRENT_UID={current_uid}")
    print(f"CURRENT_GID={current_gid}")

    subprocess.run(["sudo", "mkdir", "-p", artifact_root], check=True)
    subprocess.run(["sudo", "chown", f"{current_uid}:{current_gid}", artifact_root], check=True)
    subprocess.run(["chmod", "700", artifact_root], check=True)

    write_test_file(Path(artifact_root), "write-test")
    print_ls(Path(artifact_root))
    return 0


def resolve_home_literal(value: str) -> str:
    # Handles both a literal "$HOME" substring and an escaped "\$HOME" the
    # way it can end up in reimage.env after a careless copy-paste.
    if not value:
        return value
    resolved = value.replace("\\$HOME", str(Path.home())).replace("$HOME", str(Path.home()))
    return resolved


def cmd_repair_literal_paths(args: argparse.Namespace) -> int:
    """
    Repair reimage.env when REIMAGE_ARTIFACT_ROOT or an optional path
    (OFFICE_WATCH, ONEDRIVE_ROOT) contains literal helper-variable text
    instead of a resolved value. Recomputes REIMAGE_ARTIFACT_ROOT from
    EXTERNAL_DATA_VOLUME/ASSET_OR_HOST/REIMAGE_START_DATE, resolves any
    literal $HOME text in the optional paths, and writes the results back.

    Safe to run even if reimage.env currently has bad references --
    load_env_values already disables nounset before sourcing.
    """
    values = load_env_values(args.env_file)

    external_data_volume = values["EXTERNAL_DATA_VOLUME"].rstrip("/")
    external_apple_backups_volume = values["EXTERNAL_APPLE_BACKUPS_VOLUME"].rstrip("/")
    ensure_absolute_path("EXTERNAL_DATA_VOLUME", external_data_volume)

    recomputed_root = f"{external_data_volume}/reimage-{values['ASSET_OR_HOST']}-{values['REIMAGE_START_DATE']}-open"
    onedrive_dest_subdir = Path(recomputed_root.rstrip("/")).name

    office_watch = resolve_home_literal(values.get("OFFICE_WATCH", ""))
    onedrive_root = resolve_home_literal(values.get("ONEDRIVE_ROOT", ""))

    updates = {
        "EXTERNAL_DATA_VOLUME": external_data_volume,
        "EXTERNAL_APPLE_BACKUPS_VOLUME": external_apple_backups_volume,
        "REIMAGE_ARTIFACT_ROOT": recomputed_root,
        "ONEDRIVE_DEST_SUBDIR": onedrive_dest_subdir,
        "OFFICE_WATCH": office_watch,
        "ONEDRIVE_ROOT": onedrive_root,
    }
    update_env_exports(args.env_file, updates)

    print(f"REIMAGE_ARTIFACT_ROOT={recomputed_root}")
    print(f"ONEDRIVE_DEST_SUBDIR={onedrive_dest_subdir}")
    print(f"OFFICE_WATCH={office_watch}")
    print(f"ONEDRIVE_ROOT={onedrive_root}")

    if contains_literal_path(recomputed_root):
        raise SystemExit(
            "REIMAGE_ARTIFACT_ROOT still contains literal variable text after repair.\n"
            "EXTERNAL_DATA_VOLUME, ASSET_OR_HOST, or REIMAGE_START_DATE is itself unresolved -- fix those first."
        )
    return 0


def cmd_confirm_env(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    print_env_summary(values)

    ensure_absolute_path("REIMAGE_WORKSPACE_ROOT", values["REIMAGE_WORKSPACE_ROOT"])
    ensure_absolute_path("EXTERNAL_DATA_VOLUME", values["EXTERNAL_DATA_VOLUME"])
    # EXTERNAL_APPLE_BACKUPS_VOLUME is an optional Time Machine destination —
    # reimage.env.example ships it blank — so an empty value is valid here, the
    # same as it already is in verify-prepared-root.
    ensure_absolute_path("EXTERNAL_APPLE_BACKUPS_VOLUME", values["EXTERNAL_APPLE_BACKUPS_VOLUME"], allow_empty=True)
    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", values["REIMAGE_ARTIFACT_ROOT"])
    ensure_absolute_path("PERFORMANCE_HISTORY_SOURCE", values["PERFORMANCE_HISTORY_SOURCE"], allow_empty=True)
    ensure_absolute_path("OFFICE_WATCH", values["OFFICE_WATCH"], allow_empty=True)
    ensure_absolute_path("ONEDRIVE_ROOT", values["ONEDRIVE_ROOT"], allow_empty=True)
    ensure_artifact_root_under_external(values["EXTERNAL_DATA_VOLUME"], values["REIMAGE_ARTIFACT_ROOT"])

    if Path(values["REIMAGE_ARTIFACT_ROOT"]).is_dir():
        print(f"OK: REIMAGE_ARTIFACT_ROOT exists: {values['REIMAGE_ARTIFACT_ROOT']}")
    else:
        raise SystemExit(
            f"REIMAGE_ARTIFACT_ROOT does not exist yet: {values['REIMAGE_ARTIFACT_ROOT']}\n"
            "Return to Step 6, create the artifact root, then rerun this helper."
        )
    return 0


def cmd_create_standard_layout(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", values["REIMAGE_ARTIFACT_ROOT"])
    ensure_artifact_root_under_external(values["EXTERNAL_DATA_VOLUME"], values["REIMAGE_ARTIFACT_ROOT"])
    expected = load_expected_artifact_folders(args.env_file, str(REPO_ROOT))
    for folder in expected:
        path = Path(values["REIMAGE_ARTIFACT_ROOT"]) / folder
        path.mkdir(parents=True, exist_ok=True)
        print(f"OK: {path}")
    return 0


def cmd_copy_it_plan(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", values["REIMAGE_ARTIFACT_ROOT"])
    ensure_artifact_root_under_external(values["EXTERNAL_DATA_VOLUME"], values["REIMAGE_ARTIFACT_ROOT"])

    source = resolve_it_plan_source(args.source, values, args.workspace_root)
    destination_dir = Path(values["REIMAGE_ARTIFACT_ROOT"]) / "reimage-confirmation"
    destination_dir.mkdir(parents=True, exist_ok=True)
    destination = destination_dir / source.name

    if destination.exists() and not filecmp.cmp(source, destination, shallow=False):
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        previous = destination.with_name(f"{destination.name}.previous-{stamp}")
        shutil.copy2(destination, previous)
        print(f"Backed up previous copy: {previous}")

    shutil.copy2(source, destination)
    print(f"IT_PLAN_SOURCE={source}")
    print(f"IT_PLAN_DEST={destination}")
    return 0


def cmd_init_artifact_config(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    workspace_root = values["REIMAGE_WORKSPACE_ROOT"]
    ensure_absolute_path("REIMAGE_WORKSPACE_ROOT", workspace_root)
    templates_dir = REPO_ROOT / ".internal" / "templates" / "artifact-config"
    destination_dir = Path(workspace_root) / "artifact-config"

    if not templates_dir.is_dir():
        raise SystemExit(f"Missing artifact-config templates directory: {templates_dir}")

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

    print(f"Workspace artifact-config directory: {destination_dir}")
    print(f"Copied: {copied}")
    print(f"Skipped existing: {skipped}")
    for path in sorted(destination_dir.glob("*.conf.sh")):
        print(path.name)
    return 0


def cmd_verify_prepared_root(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    expected = load_expected_artifact_folders(args.env_file, str(REPO_ROOT))
    config_source_dir = load_artifact_config_source_dir(args.env_file, str(REPO_ROOT))

    print_env_summary(values)
    print(f"ARTIFACT_CONFIG_SOURCE_DIR={config_source_dir}")

    ensure_absolute_path("REIMAGE_WORKSPACE_ROOT", values["REIMAGE_WORKSPACE_ROOT"])
    ensure_absolute_path("EXTERNAL_DATA_VOLUME", values["EXTERNAL_DATA_VOLUME"])
    # Optional Time Machine destination — blank is valid, matching confirm-env.
    ensure_absolute_path("EXTERNAL_APPLE_BACKUPS_VOLUME", values["EXTERNAL_APPLE_BACKUPS_VOLUME"], allow_empty=True)
    ensure_absolute_path("REIMAGE_ARTIFACT_ROOT", values["REIMAGE_ARTIFACT_ROOT"])
    ensure_artifact_root_under_external(values["EXTERNAL_DATA_VOLUME"], values["REIMAGE_ARTIFACT_ROOT"])

    # No REIMAGE_ROOT existence check needed — REPO_ROOT is self-located from
    # this script's own path, so if this code is running, it trivially exists.
    if not args.env_file.is_file():
        raise SystemExit(f"reimage.env does not exist: {args.env_file}")
    if not Path(values["EXTERNAL_DATA_VOLUME"]).is_dir():
        raise SystemExit(f"EXTERNAL_DATA_VOLUME does not exist: {values['EXTERNAL_DATA_VOLUME']}")
    if not values["EXTERNAL_APPLE_BACKUPS_VOLUME"]:
        # Without this branch an empty value fell through to Path("").is_dir(),
        # which is the current directory and always true, so an unset optional
        # volume produced no line at all.
        print("INFO: EXTERNAL_APPLE_BACKUPS_VOLUME is not set; Time Machine destination checks will be skipped unless configured later")
    elif not Path(values["EXTERNAL_APPLE_BACKUPS_VOLUME"]).is_dir():
        print(f"INFO: EXTERNAL_APPLE_BACKUPS_VOLUME not found yet: {values['EXTERNAL_APPLE_BACKUPS_VOLUME']}")
    if not Path(values["REIMAGE_ARTIFACT_ROOT"]).is_dir():
        raise SystemExit(f"REIMAGE_ARTIFACT_ROOT does not exist: {values['REIMAGE_ARTIFACT_ROOT']}")

    if values["ONEDRIVE_ROOT"]:
        if Path(values["ONEDRIVE_ROOT"]).is_dir():
            print(f"OK: ONEDRIVE_ROOT exists: {values['ONEDRIVE_ROOT']}")
        else:
            print(f"INFO: ONEDRIVE_ROOT not found or not signed in yet: {values['ONEDRIVE_ROOT']}")
    else:
        print("INFO: ONEDRIVE_ROOT is not set; skipping OneDrive root check")

    if values["OFFICE_WATCH"]:
        if Path(values["OFFICE_WATCH"]).is_dir():
            print(f"OK: OFFICE_WATCH exists: {values['OFFICE_WATCH']}")
        else:
            print(f"INFO: OFFICE_WATCH not found yet: {values['OFFICE_WATCH']}")
    else:
        print("INFO: OFFICE_WATCH is not set; Office watcher checks will be skipped unless configured later")

    subprocess.run(["df", "-h", values["EXTERNAL_DATA_VOLUME"]], check=False)
    write_test_file(Path(values["REIMAGE_ARTIFACT_ROOT"]), "write-test")

    print("Top-level directories:")
    for child in sorted(Path(values["REIMAGE_ARTIFACT_ROOT"]).iterdir()):
        if child.is_dir():
            print(child.name)

    missing: List[str] = []
    for folder in expected:
        path = Path(values["REIMAGE_ARTIFACT_ROOT"]) / folder
        if path.is_dir():
            print(f"OK: {folder}")
        else:
            print(f"MISSING: {folder}")
            missing.append(folder)

    if missing:
        raise SystemExit(
            "Expected artifact folders are missing.\n"
            "Create the standard directory layout, then rerun this helper."
        )

    reimage_confirmation_dir = Path(values["REIMAGE_ARTIFACT_ROOT"]) / "reimage-confirmation"
    it_plan_files = sorted(reimage_confirmation_dir.glob("it-reimage-confirmation-*.md"))
    if it_plan_files:
        print(f"OK: reimage-confirmation IT confirmation: {it_plan_files[-1].name}")
    else:
        raise SystemExit(
            "Missing IT reimage confirmation under reimage-confirmation/.\n"
            "Copy it during Phase 1, then rerun this helper."
        )
    return 0


def cmd_diagnose_external_root(args: argparse.Namespace) -> int:
    values = load_env_values(args.env_file)
    external_data_volume = values["EXTERNAL_DATA_VOLUME"]
    artifact_root = values["REIMAGE_ARTIFACT_ROOT"]

    print(f"EXTERNAL_DATA_VOLUME={external_data_volume}")
    print(f"REIMAGE_ARTIFACT_ROOT={artifact_root}")

    commands = [
        ["diskutil", "info", external_data_volume],
        ["/bin/ls", "-ldeO@", external_data_volume],
        ["id"],
        ["df", "-h", external_data_volume],
    ]
    for command in commands:
        print("\n$ " + " ".join(shlex.quote(part) for part in command))
        subprocess.run(command, check=False)

    print("\n$ stat -f 'owner=%Su group=%Sg mode=%Sp path=%N' <external-root>")
    subprocess.run(
        ["stat", "-f", "owner=%Su group=%Sg mode=%Sp path=%N", external_data_volume],
        check=False,
    )

    test_file = Path(external_data_volume) / f"reimage-parent-write-test-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"
    print(f"\nParent write test: {test_file}")
    try:
        test_file.write_text(dt.datetime.now().isoformat() + "\n", encoding="utf-8")
        print(test_file.read_text(encoding="utf-8").strip())
        test_file.unlink()
        print("OK: parent-volume write test succeeded")
    except Exception as exc:
        print(f"WRITE TEST FAILED: {exc}")

    return 0


# --env-file is accepted by every subcommand, so its help text is shared. The
# two variants differ only in whether the subcommand rewrites the file.
ENV_FILE_HELP_READ = (
    "Path to the local reimage.env to read resolved values from. A relative "
    "path resolves against the current directory, so run this from the "
    "repository root."
)
ENV_FILE_HELP_WRITE = (
    "Path to the local reimage.env to update in place. Matching export lines "
    "are rewritten, missing keys are appended, and unrelated lines and "
    "comments are preserved. A relative path resolves against the current "
    "directory, so run this from the repository root."
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Entrypoint for prepare-artifact-root.md")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser(
        "init-reimage-env",
        help="Write the starter resolved values into reimage.env after copying the example file.",
    )
    init_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_WRITE)
    init_parser.add_argument(
        "--workspace-root",
        default="",
        help=(
            "Absolute path written to REIMAGE_WORKSPACE_ROOT: the directory outside this repo "
            "and outside the external volume that holds the artifact-config and staged-certs "
            "fragments. Required -- there is no default. Both it and its reimage-confirmation/ "
            "subdirectory are created if missing."
        ),
    )
    init_parser.add_argument(
        "--performance-history-source",
        default="",
        help=(
            "Optional absolute path written to PERFORMANCE_HISTORY_SOURCE: the long-lived "
            "mac_memory_health.sh history directory read by the rollup summary. Leave empty "
            "when that external helper is not in use."
        ),
    )
    init_parser.add_argument(
        "--external-data-volume",
        default="/Volumes/Data",
        help=(
            "Mounted external data/artifact volume that REIMAGE_ARTIFACT_ROOT is created "
            "under -- the volume itself, not the per-reimage folder on it. Any trailing "
            "slash is stripped. Default: %(default)s."
        ),
    )
    init_parser.add_argument(
        "--external-apple-backups-volume",
        default="/Volumes/AppleBackups",
        help=(
            "Optional dedicated Time Machine destination volume, written through as-is to "
            "EXTERNAL_APPLE_BACKUPS_VOLUME. Pass an empty string when no Time Machine volume "
            "is in use. Default: %(default)s."
        ),
    )
    init_parser.add_argument(
        "--asset-or-host",
        default="",
        help=(
            "Asset tag or hostname used for ASSET_OR_HOST and in the REIMAGE_ARTIFACT_ROOT "
            "folder name. Defaults to this Mac's LocalHostName, falling back to the short "
            "hostname; pass it explicitly when neither can be detected."
        ),
    )
    init_parser.add_argument(
        "--reimage-start-date",
        default="",
        help=(
            "Date the reimage effort started, in YYYYMMDD format, used for REIMAGE_START_DATE "
            "and in the REIMAGE_ARTIFACT_ROOT folder name. Defaults to today."
        ),
    )
    init_parser.add_argument(
        "--onedrive-parent-dir",
        default="",
        help=(
            "Directory the OneDrive sync folder lives under. Defaults to "
            "$HOME/Library/CloudStorage. Override when the sync folder is not a "
            "macOS file-provider mount."
        ),
    )
    init_parser.add_argument(
        "--onedrive-folder-name",
        default="",
        help=(
            "Optional OneDrive sync folder name (e.g. OneDrive-AcmeGroup). When set, "
            "ONEDRIVE_ROOT is resolved to <onedrive-parent-dir>/<name> and the per-reimage "
            "OneDrive destination is created when that parent already exists. Leave empty to "
            "skip OneDrive."
        ),
    )
    init_parser.set_defaults(func=cmd_init_reimage_env)

    upsert_parser = subparsers.add_parser(
        "upsert-env",
        help="Update one or more export values in reimage.env using KEY=VALUE assignments.",
    )
    upsert_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_WRITE)
    upsert_parser.add_argument(
        "assignment",
        nargs="+",
        help=(
            "One or more KEY=VALUE assignments to write into reimage.env. Each value is "
            "shell-quoted; path-valued keys have any trailing slash stripped. An empty value "
            "(KEY=) clears the key."
        ),
    )
    upsert_parser.set_defaults(func=cmd_upsert_env)

    create_root_parser = subparsers.add_parser(
        "create-artifact-root",
        help="Create REIMAGE_ARTIFACT_ROOT, validate it, and run a write test.",
    )
    create_root_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    create_root_parser.set_defaults(func=cmd_create_artifact_root)

    repair_root_parser = subparsers.add_parser(
        "repair-artifact-root-perms",
        help="Create REIMAGE_ARTIFACT_ROOT with sudo once, then hand it back to the current user.",
    )
    repair_root_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    repair_root_parser.set_defaults(func=cmd_repair_artifact_root_perms)

    repair_literal_parser = subparsers.add_parser(
        "repair-literal-paths",
        help="Recompute REIMAGE_ARTIFACT_ROOT and resolve literal $HOME text in OFFICE_WATCH/ONEDRIVE_ROOT.",
    )
    repair_literal_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_WRITE)
    repair_literal_parser.set_defaults(func=cmd_repair_literal_paths)

    confirm_env_parser = subparsers.add_parser(
        "confirm-env",
        help="Print and validate the loaded reimage environment values.",
    )
    confirm_env_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    confirm_env_parser.set_defaults(func=cmd_confirm_env)

    layout_parser = subparsers.add_parser(
        "create-standard-layout",
        help="Create the stable top-level artifact folders defined by artifact-config.sh.",
    )
    layout_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    layout_parser.set_defaults(func=cmd_create_standard_layout)

    copy_it_plan_parser = subparsers.add_parser(
        "copy-it-plan",
        help="Copy the filled IT reimage confirmation into REIMAGE_ARTIFACT_ROOT/reimage-confirmation/.",
    )
    copy_it_plan_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    copy_it_plan_parser.add_argument(
        "--source",
        default="",
        help=(
            "Absolute path to the filled IT reimage confirmation Markdown file to copy. When "
            "omitted, the most recently modified it-reimage-confirmation-*.md under "
            "<workspace-root>/reimage-confirmation/ is used."
        ),
    )
    copy_it_plan_parser.add_argument(
        "--workspace-root",
        default="",
        help=(
            "Override REIMAGE_WORKSPACE_ROOT for locating the filled IT plan note under "
            "<workspace-root>/reimage-confirmation/. Use this instead of persisting "
            "REIMAGE_WORKSPACE_ROOT in reimage.env. Ignored if --source is provided."
        ),
    )
    copy_it_plan_parser.set_defaults(func=cmd_copy_it_plan)

    init_config_parser = subparsers.add_parser(
        "init-artifact-config",
        help="Copy artifact-config template fragments into REIMAGE_WORKSPACE_ROOT for reuse across reruns.",
    )
    init_config_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    init_config_parser.add_argument(
        "--force",
        action="store_true",
        help=(
            "Overwrite workspace artifact-config fragments that already exist. Without it, "
            "existing fragments are left untouched and reported as skipped."
        ),
    )
    init_config_parser.set_defaults(func=cmd_init_artifact_config)

    verify_parser = subparsers.add_parser(
        "verify-prepared-root",
        help="Validate the prepared root, top-level layout, and related environment paths.",
    )
    verify_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    verify_parser.set_defaults(func=cmd_verify_prepared_root)

    diagnose_parser = subparsers.add_parser(
        "diagnose-external-root",
        help="Inspect external-root ownership, disk info, and parent write access for troubleshooting.",
    )
    diagnose_parser.add_argument("--env-file", type=Path, required=True, help=ENV_FILE_HELP_READ)
    diagnose_parser.set_defaults(func=cmd_diagnose_external_root)

    return parser


def main(argv: List[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
