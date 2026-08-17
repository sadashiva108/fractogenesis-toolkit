#!/usr/bin/env python3
"""
Generate auto-filled manual-observations.md and workload-reproduction-config.md
for a capture-performance-audit.sh bundle.

Internal helper: invoked by capture-performance-audit.sh with explicit CLI
arguments (--audit-dir/--phase/--scenario/--note) and safe to run standalone
when those are supplied. It deliberately does NOT load the shared reimage
config (reimage.env / .internal/artifact-config.sh): every path it touches is
derived from --audit-dir, so the caller stays the single source of truth for
which bundle is being annotated.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Dict, List, Tuple


def read_csv(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def safe_float(value: str, default: float = 0.0) -> float:
    text = (value or "").strip()
    if not text:
        return default
    try:
        return float(text)
    except ValueError:
        return default


def extract_command_output(text: str, title: str) -> str:
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        if line.strip() != title:
            continue
        j = idx + 1
        # run_cmd emits: ==== / title / ==== / Timestamp: / Command: / blank /
        # body / blank. When the command produced no output there is no body,
        # so the skip loop must stop at the banner that opens the NEXT section
        # instead of walking into it and returning that section's title as this
        # section's output.
        seen_command = False
        while j < len(lines):
            current = lines[j]
            if current.startswith("="):
                if seen_command:
                    return ""
                j += 1
                continue
            if current.startswith("Timestamp:"):
                j += 1
                continue
            if current.startswith("Command:"):
                seen_command = True
                j += 1
                continue
            if not current.strip():
                j += 1
                continue
            start = j
            end = j
            while end < len(lines):
                if lines[end].startswith("================================================================================"):
                    break
                end += 1
            return "\n".join(lines[start:end]).strip()
    return ""


def summarize_app_rollup(app_rollup_path: Path, top_n: int = 8) -> Tuple[List[Dict[str, str]], str]:
    if not app_rollup_path.exists():
        return [], ""
    rows = read_csv(app_rollup_path)
    rows.sort(key=lambda row: safe_float(row.get("rss_mb", "0")), reverse=True)
    summary = ", ".join(
        f"{row.get('app', 'Unknown')} ({safe_float(row.get('rss_mb', '0')):.0f} MB)"
        for row in rows[:top_n]
    )
    return rows, summary


def summarize_responsiveness(path: Path) -> Dict[str, str]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8", errors="replace")
    sections = {
        "System Events visible app query": [],
        "Python interpreter cold-ish startup, if python3 exists": [],
        "shell process listing": [],
    }
    current = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("Timing: "):
            for key in sections:
                if key in stripped:
                    current = key
                    break
            else:
                current = None
            continue
        if current and stripped.startswith("real "):
            try:
                sections[current].append(float(stripped.split()[1]))
            except Exception:
                pass
    out: Dict[str, str] = {}
    for key, values in sections.items():
        if values:
            out[key] = f"{sum(values) / len(values):.3f}s avg across {len(values)} runs"
    return out


def detect_docker_state(path: Path) -> str:
    if not path.exists():
        return "unknown"
    text = path.read_text(encoding="utf-8", errors="replace")
    if "Docker daemon reachable: yes" in text:
        return "yes"
    if "Docker daemon reachable: no" in text:
        return "no"
    if "Docker capture was skipped" in text:
        return "skipped"
    return "unknown"


def generate_manual_observations(
    audit_dir: Path,
    phase: str,
    scenario: str,
    note: str,
) -> None:
    system_text = (audit_dir / "system" / "system-overview.txt").read_text(encoding="utf-8", errors="replace") if (audit_dir / "system" / "system-overview.txt").exists() else ""
    visible_apps = extract_command_output(system_text, "login items visible apps").strip()
    active_network = extract_command_output(system_text, "active network interfaces").strip()
    vpn_services = extract_command_output(system_text, "VPN services").strip()

    app_rows, app_summary = summarize_app_rollup(audit_dir / "processes" / "app_rollup.csv")
    docker_state = detect_docker_state(audit_dir / "docker" / "docker-daemon-state.txt")
    responsiveness = summarize_responsiveness(audit_dir / "responsiveness" / "responsiveness-probes.txt")

    top_apps_table = "\n".join(
        f"- {row.get('app', 'Unknown')}: {safe_float(row.get('rss_mb', '0')):.2f} MB RSS, {safe_float(row.get('cpu_pct', '0')):.1f}% CPU, {row.get('process_count', '0')} processes"
        for row in app_rows[:8]
    ) or "- TODO"

    lines: List[str] = []
    lines.append("# Manual Observations")
    lines.append("")
    lines.append("This file was auto-filled from the captured bundle. Replace or complete TODO lines where the script cannot know the answer with confidence.")
    lines.append("")
    lines.append("## Auto-filled capture context")
    lines.append("")
    lines.append(f"- Phase: {phase}")
    lines.append(f"- Scenario: {scenario}")
    lines.append(f"- Note: {note or 'n/a'}")
    lines.append(f"- Bundle root: `{audit_dir}`")
    lines.append(f"- Visible GUI apps captured: {visible_apps or 'TODO verify from system/system-overview.txt'}")
    lines.append(f"- Docker daemon running: {docker_state}")
    lines.append(f"- Top app groups by RSS: {app_summary or 'TODO review processes/app_rollup.csv'}")
    if responsiveness:
        for key, value in responsiveness.items():
            lines.append(f"- Objective responsiveness probe — {key}: {value}")
    else:
        lines.append("- Objective responsiveness probes: TODO review responsiveness/responsiveness-probes.txt")
    lines.append("")
    lines.append("## Remaining TODOs to confirm manually")
    lines.append("")
    lines.append("- Power state at capture (plugged in / battery): TODO")
    lines.append("- External displays actually in use: TODO")
    lines.append(f"- Network state detail: {active_network or 'TODO'}")
    lines.append(f"- VPN/service detail: {vpn_services or 'TODO'}")
    lines.append("- IntelliJ projects open: TODO")
    lines.append("- Chrome windows/tabs approximate count: TODO")
    lines.append("- Any intentionally open workload-specific tools not obvious from app rollup: TODO")
    lines.append("- Any user-perceived lag not already reflected in the objective responsiveness probes: TODO")
    lines.append("")
    lines.append("## Auto-filled top app groups")
    lines.append("")
    lines.append(top_apps_table)
    lines.append("")
    lines.append("## Post-reimage comparison TODOs")
    lines.append("")
    lines.append("- Same workload reproduced after reimage: TODO")
    lines.append("- Memory pressure comparison: TODO")
    lines.append("- Swap comparison: TODO")
    lines.append("- Top app-group comparison: TODO")
    lines.append("- Docker settings comparison: TODO")
    lines.append("- IntelliJ heap comparison: TODO")
    lines.append("- Workload reproduction reference: see `workload-reproduction-config.md`")
    (audit_dir / "manual-observations.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def generate_workload_reproduction_config(
    audit_dir: Path,
    phase: str,
    scenario: str,
    note: str,
) -> None:
    system_text = (audit_dir / "system" / "system-overview.txt").read_text(encoding="utf-8", errors="replace") if (audit_dir / "system" / "system-overview.txt").exists() else ""
    visible_apps = extract_command_output(system_text, "login items visible apps").strip()
    active_network = extract_command_output(system_text, "active network interfaces").strip()
    vpn_services = extract_command_output(system_text, "VPN services").strip()
    docker_state = detect_docker_state(audit_dir / "docker" / "docker-daemon-state.txt")
    responsiveness = summarize_responsiveness(audit_dir / "responsiveness" / "responsiveness-probes.txt")
    app_rows, _ = summarize_app_rollup(audit_dir / "processes" / "app_rollup.csv")

    lines: List[str] = []
    lines.append("# Workload Reproduction Config")
    lines.append("")
    lines.append("Use this as the closest reproducible setup reference for the post-image comparison run. It is intentionally objective where possible and still leaves a few manual checks when the script cannot infer exact user intent.")
    lines.append("")
    lines.append(f"- Phase: {phase}")
    lines.append(f"- Scenario: {scenario}")
    lines.append(f"- Note: {note or 'n/a'}")
    lines.append(f"- Bundle root: `{audit_dir}`")
    lines.append("")
    lines.append("## Captured workload signals")
    lines.append("")
    lines.append(f"- Visible GUI apps: {visible_apps or 'see system/system-overview.txt'}")
    lines.append(f"- Docker daemon state: {docker_state}")
    lines.append(f"- Active network interfaces: {active_network or 'see system/system-overview.txt'}")
    lines.append(f"- VPN services: {vpn_services or 'see system/system-overview.txt'}")
    lines.append("")
    lines.append("## Top app groups by RSS")
    lines.append("")
    for row in app_rows[:10]:
        lines.append(
            f"- {row.get('app', 'Unknown')}: {safe_float(row.get('rss_mb', '0')):.2f} MB RSS, "
            f"{safe_float(row.get('cpu_pct', '0')):.1f}% CPU, {row.get('process_count', '0')} processes"
        )
    if not app_rows:
        lines.append("- TODO review processes/app_rollup.csv")
    lines.append("")
    lines.append("## Objective responsiveness baseline")
    lines.append("")
    if responsiveness:
        for key, value in responsiveness.items():
            lines.append(f"- {key}: {value}")
    else:
        lines.append("- TODO review responsiveness/responsiveness-probes.txt")
    lines.append("")
    lines.append("## Reproduction checklist")
    lines.append("")
    lines.append("1. Match the same scenario label (`clean-boot`, `normal-workload`, `active-dev`, or `symptom-capture`).")
    lines.append("2. Match whether Docker was intentionally running or intentionally stopped.")
    lines.append("3. Reopen the same major app groups shown above before running the post-image capture.")
    lines.append("4. Compare `processes/app_rollup.csv`, `memory/sample_*_memory.txt`, `memory/sample_*_top_memory.csv`, and `responsiveness/responsiveness-probes.txt` first.")
    lines.append("5. Use this file together with `manual-observations.md` to close the remaining subjective gaps.")
    (audit_dir / "workload-reproduction-config.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate auto-filled performance manual observations and reproduction config.")
    parser.add_argument("--audit-dir", required=True)
    parser.add_argument("--phase", required=True)
    parser.add_argument("--scenario", required=True)
    parser.add_argument("--note", default="")
    args = parser.parse_args()

    audit_dir = Path(args.audit_dir).expanduser().resolve()
    generate_manual_observations(audit_dir, args.phase, args.scenario, args.note)
    generate_workload_reproduction_config(audit_dir, args.phase, args.scenario, args.note)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
