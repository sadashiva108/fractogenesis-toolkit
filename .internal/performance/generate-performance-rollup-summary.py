#!/usr/bin/env python3
"""
Generate quantitative performance rollup summaries from mac-memory-health outputs.

Inputs searched recursively under --input:
  - metrics/memory_metrics.csv
  - diagnostics/app_rollup_YYYYMMDD_HHMMSS.csv
  - diagnostics/<category>_processes_YYYYMMDD_HHMMSS.csv
  - diagnostics/diagnostics_YYYYMMDD_HHMMSS_(report|monitor).txt
  - reports/memory_report_YYYYMMDD_HHMMSS_report.txt

The script is intentionally read-only for input data. It writes structured
CSV and Markdown summaries under --output. It does not generate charts.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

TIMESTAMP_RE = re.compile(r"_(\d{8})_(\d{6})\.csv$")
PROCESS_RE = re.compile(r"(?P<category>.+)_processes_(?P<date>\d{8})_(?P<time>\d{6})\.csv$")
MEMORY_REPORT_RE = re.compile(r"memory_report_(\d{8})_(\d{6})_[^.]+\.txt$")
DIAGNOSTICS_TXT_RE = re.compile(r"diagnostics_(\d{8})_(\d{6})_(report|monitor)\.txt$")
QUOTED_ROLLUP_RE = re.compile(
    r'^\s*"(?P<app>.+?)"\s+'
    r'(?P<rss_mb>-?\d+(?:\.\d+)?)\s+'
    r'(?P<cpu_pct>-?\d+(?:\.\d+)?)\s+'
    r'(?P<process_count>\d+)\s+'
    r'(?P<top_pid>\d+)\s+'
    r'(?P<top_rss_mb>-?\d+(?:\.\d+)?)\s+'
    r'"(?P<sample_command>.*)"\s*$'
)


def safe_float(value: Any, default: float = 0.0) -> float:
    if value is None:
        return default
    text = str(value).strip()
    if not text:
        return default
    try:
        return float(text)
    except ValueError:
        return default


def safe_int(value: Any, default: int = 0) -> int:
    if value is None:
        return default
    text = str(value).strip()
    if not text:
        return default
    try:
        return int(float(text))
    except ValueError:
        return default


def parse_compact_timestamp(date_text: str, time_text: str) -> dt.datetime:
    return dt.datetime.strptime(date_text + time_text, "%Y%m%d%H%M%S")


def parse_timestamp_from_name(path: Path) -> Optional[dt.datetime]:
    match = TIMESTAMP_RE.search(path.name)
    if not match:
        return None
    return parse_compact_timestamp(match.group(1), match.group(2))


def timestamp_label(value: dt.datetime) -> str:
    return value.strftime("%Y-%m-%d %H:%M:%S")


def read_csv(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        return [dict(row) for row in reader]


def write_csv(path: Path, fieldnames: List[str], rows: Iterable[Dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def discover_app_rollups(input_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in sorted(input_root.rglob("app_rollup_*.csv")):
        timestamp = parse_timestamp_from_name(path)
        if not timestamp:
            continue
        for row in read_csv(path):
            app = (row.get("app") or "Unknown").strip() or "Unknown"
            rows.append(
                {
                    "timestamp": timestamp,
                    "timestamp_label": timestamp_label(timestamp),
                    "source_file": str(path),
                    "source_kind": "app_rollup_csv",
                    "app": app,
                    "rss_mb": safe_float(row.get("rss_mb")),
                    "cpu_pct": safe_float(row.get("cpu_pct")),
                    "process_count": safe_int(row.get("process_count")),
                    "top_pid": row.get("top_pid", ""),
                    "top_rss_mb": safe_float(row.get("top_rss_mb")),
                    "sample_command": row.get("sample_command", ""),
                }
            )
    return rows


def discover_process_rows(input_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in sorted(input_root.rglob("*_processes_*.csv")):
        match = PROCESS_RE.match(path.name)
        if not match:
            continue
        timestamp = parse_compact_timestamp(match.group("date"), match.group("time"))
        category = match.group("category").replace("_", " ").title()
        for row in read_csv(path):
            command = row.get("command", "")
            if not any((row.get("pid"), command, row.get("rss_mb"), row.get("cpu_pct"))):
                continue
            rows.append(
                {
                    "timestamp": timestamp,
                    "timestamp_label": timestamp_label(timestamp),
                    "source_file": str(path),
                    "category": category,
                    "pid": row.get("pid", ""),
                    "ppid": row.get("ppid", ""),
                    "rss_mb": safe_float(row.get("rss_mb")),
                    "mem_pct": safe_float(row.get("mem_pct")),
                    "cpu_pct": safe_float(row.get("cpu_pct")),
                    "elapsed": row.get("elapsed", ""),
                    "command": command,
                }
            )
    return rows


def discover_metric_rows(input_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in sorted(input_root.rglob("memory_metrics.csv")):
        for row in read_csv(path):
            epoch = safe_int(row.get("epoch"))
            if epoch <= 0:
                continue
            timestamp = dt.datetime.fromtimestamp(epoch)
            rows.append(
                {
                    "timestamp": timestamp,
                    "timestamp_label": timestamp_label(timestamp),
                    "source_file": str(path),
                    "event": row.get("event", ""),
                    "host": row.get("host", ""),
                    "used_est_gb": safe_float(row.get("used_est_gb")),
                    "free_gb": safe_float(row.get("free_gb")),
                    "active_gb": safe_float(row.get("active_gb")),
                    "inactive_gb": safe_float(row.get("inactive_gb")),
                    "wired_gb": safe_float(row.get("wired_gb")),
                    "compressor_gb": safe_float(row.get("compressor_gb")),
                    "compressed_gb": safe_float(row.get("compressed_gb")),
                    "swap_used_mb": safe_float(row.get("swap_used_mb")),
                    "memory_pressure_free_pct": safe_float(row.get("memory_pressure_free_pct")),
                    "delta_pageouts": safe_int(row.get("delta_pageouts")),
                    "delta_swapouts": safe_int(row.get("delta_swapouts")),
                    "seconds_since_last": safe_int(row.get("seconds_since_last")),
                    "health": row.get("health", ""),
                    "report_file": row.get("report_file", ""),
                    "top_process_file": row.get("top_process_file", ""),
                }
            )
    rows.sort(key=lambda item: item["timestamp"])
    return rows


def parse_float_from_line(text: str, pattern: str) -> float:
    match = re.search(pattern, text, re.MULTILINE)
    return safe_float(match.group(1)) if match else 0.0


def parse_int_from_line(text: str, pattern: str) -> int:
    match = re.search(pattern, text, re.MULTILINE)
    return safe_int(match.group(1)) if match else 0


def parse_str_from_line(text: str, pattern: str) -> str:
    match = re.search(pattern, text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def discover_memory_report_rows(input_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in sorted(input_root.rglob("memory_report_*_*.txt")):
        if not MEMORY_REPORT_RE.search(path.name):
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        timestamp_match = MEMORY_REPORT_RE.search(path.name)
        assert timestamp_match is not None
        timestamp = parse_compact_timestamp(timestamp_match.group(1), timestamp_match.group(2))
        top_process = ""
        top_process_rss_mb = 0.0
        in_top_processes = False
        for line in text.splitlines():
            stripped = line.strip()
            if stripped == "Top memory-consuming processes":
                in_top_processes = True
                continue
            if in_top_processes:
                if not stripped or stripped.startswith("Raw vm_stat"):
                    break
                if stripped.startswith("pid"):
                    continue
                parts = line.split()
                if len(parts) >= 5 and parts[0].isdigit():
                    top_process_rss_mb = safe_float(parts[1])
                    top_process = " ".join(parts[4:]).strip('"')
                    break
        rows.append(
            {
                "timestamp": timestamp,
                "timestamp_label": timestamp_label(timestamp),
                "source_file": str(path),
                "event": parse_str_from_line(text, r"^Event:\s+(.+)$"),
                "health": parse_str_from_line(text, r"^Health:\s+(.+)$"),
                "total_gb": parse_float_from_line(text, r"^Total memory:\s+([0-9.]+)\s+GB$"),
                "used_est_gb": parse_float_from_line(text, r"^Estimated used memory:\s+([0-9.]+)\s+GB"),
                "used_est_pct": parse_float_from_line(text, r"^Estimated used memory:\s+[0-9.]+\s+GB\s+\(([0-9.]+)%\)$"),
                "free_gb": parse_float_from_line(text, r"^Free pages:\s+([0-9.]+)\s+GB$"),
                "memory_pressure_free_pct": parse_float_from_line(text, r"^memory_pressure free %:\s+([0-9.]+)$"),
                "swap_used_mb": parse_float_from_line(text, r"^Swap used:\s+([0-9.]+)\s+MB$"),
                "delta_pageouts": parse_int_from_line(text, r"^Pageout delta:\s+([0-9]+)\s+over\s+[0-9]+s$"),
                "delta_swapouts": parse_int_from_line(text, r"^Swapout delta:\s+([0-9]+)\s+over\s+[0-9]+s$"),
                "top_process_rss_mb": top_process_rss_mb,
                "top_process_command": top_process,
            }
        )
    return rows


def discover_diagnostics_text_rollups(input_root: Path) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for path in sorted(input_root.rglob("diagnostics_*_*.txt")):
        match = DIAGNOSTICS_TXT_RE.search(path.name)
        if not match:
            continue
        timestamp = parse_compact_timestamp(match.group(1), match.group(2))
        event = match.group(3)
        text = path.read_text(encoding="utf-8", errors="replace")
        in_rollup = False
        for line in text.splitlines():
            stripped = line.strip()
            if stripped == "App-level RAM/CPU rollup":
                in_rollup = True
                continue
            if not in_rollup:
                continue
            if stripped.startswith("Development agent parent chains"):
                break
            if not stripped or stripped.startswith("app "):
                continue
            parsed = QUOTED_ROLLUP_RE.match(line)
            if not parsed:
                continue
            rows.append(
                {
                    "timestamp": timestamp,
                    "timestamp_label": timestamp_label(timestamp),
                    "source_file": str(path),
                    "source_kind": f"diagnostics_{event}_txt",
                    "event": event,
                    "app": parsed.group("app"),
                    "rss_mb": safe_float(parsed.group("rss_mb")),
                    "cpu_pct": safe_float(parsed.group("cpu_pct")),
                    "process_count": safe_int(parsed.group("process_count")),
                    "top_pid": parsed.group("top_pid"),
                    "top_rss_mb": safe_float(parsed.group("top_rss_mb")),
                    "sample_command": parsed.group("sample_command"),
                }
            )
    return rows


def top_items(rows: Iterable[Dict[str, Any]], key_field: str, value_field: str, n: int, exclude: Optional[set[str]] = None) -> List[str]:
    exclude = exclude or set()
    totals: Dict[str, float] = defaultdict(float)
    for row in rows:
        key = str(row.get(key_field, "")).strip()
        if not key or key in exclude:
            continue
        totals[key] = max(totals[key], safe_float(row.get(value_field)))
    return [name for name, _ in sorted(totals.items(), key=lambda item: item[1], reverse=True)[:n]]


def pivot_app_metric(rows: List[Dict[str, Any]], metric: str, app_names: List[str]) -> Tuple[List[dt.datetime], Dict[str, List[float]]]:
    timestamps = sorted({row["timestamp"] for row in rows})
    by_key = {(row["timestamp"], row["app"]): safe_float(row.get(metric)) for row in rows}
    series = {app: [by_key.get((timestamp, app), 0.0) for timestamp in timestamps] for app in app_names}
    return timestamps, series


def write_app_pivot(path: Path, rows: List[Dict[str, Any]], metric: str, app_names: List[str]) -> None:
    timestamps, series = pivot_app_metric(rows, metric, app_names)
    fieldnames = ["timestamp"] + app_names
    out_rows: List[Dict[str, Any]] = []
    for idx, timestamp in enumerate(timestamps):
        row: Dict[str, Any] = {"timestamp": timestamp_label(timestamp)}
        for app in app_names:
            row[app] = f"{series[app][idx]:.2f}"
        out_rows.append(row)
    write_csv(path, fieldnames, out_rows)


def summarize_processes(process_rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    grouped: Dict[Tuple[dt.datetime, str], Dict[str, Any]] = {}
    for row in process_rows:
        key = (row["timestamp"], row["category"])
        entry = grouped.setdefault(
            key,
            {
                "timestamp": row["timestamp"],
                "timestamp_label": row["timestamp_label"],
                "category": row["category"],
                "rss_mb": 0.0,
                "cpu_pct": 0.0,
                "process_count": 0,
                "top_pid": "",
                "top_rss_mb": 0.0,
                "top_command": "",
            },
        )
        entry["rss_mb"] += row["rss_mb"]
        entry["cpu_pct"] += row["cpu_pct"]
        entry["process_count"] += 1
        if row["rss_mb"] > entry["top_rss_mb"]:
            entry["top_rss_mb"] = row["rss_mb"]
            entry["top_pid"] = row["pid"]
            entry["top_command"] = row["command"]
    return sorted(grouped.values(), key=lambda item: (item["timestamp"], -item["rss_mb"]))


def nearest_metric_row(timestamp: dt.datetime, metric_rows: List[Dict[str, Any]], max_seconds: int = 10800) -> Optional[Dict[str, Any]]:
    best: Optional[Dict[str, Any]] = None
    best_delta: Optional[float] = None
    for row in metric_rows:
        delta = abs((row["timestamp"] - timestamp).total_seconds())
        if best_delta is None or delta < best_delta:
            best = row
            best_delta = delta
    if best is None or best_delta is None or best_delta > max_seconds:
        return None
    return best


def build_snapshot_correlation_rows(
    app_rows: List[Dict[str, Any]], metric_rows: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    grouped_rows: List[Dict[str, Any]] = []
    timestamps = sorted({row["timestamp"] for row in app_rows})
    for timestamp in timestamps:
        matching = [row for row in app_rows if row["timestamp"] == timestamp]
        total_rss = sum(row["rss_mb"] for row in matching)
        total_cpu = sum(row["cpu_pct"] for row in matching)
        total_processes = sum(row["process_count"] for row in matching)
        top_app = max(matching, key=lambda row: row["rss_mb"], default=None)
        metric = nearest_metric_row(timestamp, metric_rows)
        grouped_rows.append(
            {
                "timestamp": timestamp_label(timestamp),
                "snapshot_total_grouped_rss_mb": f"{total_rss:.2f}",
                "snapshot_total_grouped_cpu_pct": f"{total_cpu:.1f}",
                "snapshot_total_grouped_process_count": total_processes,
                "largest_app_group": "" if not top_app else top_app["app"],
                "largest_app_group_rss_mb": "" if not top_app else f"{top_app['rss_mb']:.2f}",
                "largest_app_group_cpu_pct": "" if not top_app else f"{top_app['cpu_pct']:.1f}",
                "health": "" if not metric else metric["health"],
                "used_est_gb": "" if not metric else f"{metric['used_est_gb']:.2f}",
                "free_gb": "" if not metric else f"{metric['free_gb']:.2f}",
                "swap_used_mb": "" if not metric else f"{metric['swap_used_mb']:.2f}",
                "memory_pressure_free_pct": "" if not metric else f"{metric['memory_pressure_free_pct']:.1f}",
                "delta_pageouts": "" if not metric else metric["delta_pageouts"],
                "delta_swapouts": "" if not metric else metric["delta_swapouts"],
                "seconds_since_last": "" if not metric else metric["seconds_since_last"],
                "metric_source_file": "" if not metric else metric["source_file"],
            }
        )
    return grouped_rows


def build_app_health_summary(
    app_rows: List[Dict[str, Any]], metric_rows: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    health_by_timestamp: Dict[dt.datetime, str] = {}
    for timestamp in {row["timestamp"] for row in app_rows}:
        metric = nearest_metric_row(timestamp, metric_rows)
        health_by_timestamp[timestamp] = "" if not metric else metric["health"]

    grouped: Dict[Tuple[str, str], Dict[str, Any]] = {}
    for row in app_rows:
        health = health_by_timestamp.get(row["timestamp"], "")
        key = (health or "UNMATCHED", row["app"])
        entry = grouped.setdefault(
            key,
            {
                "health": health or "UNMATCHED",
                "app": row["app"],
                "snapshot_count": 0,
                "rss_total": 0.0,
                "rss_max": 0.0,
                "cpu_total": 0.0,
                "cpu_max": 0.0,
                "process_count_total": 0,
                "process_count_max": 0,
            },
        )
        entry["snapshot_count"] += 1
        entry["rss_total"] += row["rss_mb"]
        entry["rss_max"] = max(entry["rss_max"], row["rss_mb"])
        entry["cpu_total"] += row["cpu_pct"]
        entry["cpu_max"] = max(entry["cpu_max"], row["cpu_pct"])
        entry["process_count_total"] += row["process_count"]
        entry["process_count_max"] = max(entry["process_count_max"], row["process_count"])

    out_rows: List[Dict[str, Any]] = []
    for value in grouped.values():
        count = max(1, value["snapshot_count"])
        out_rows.append(
            {
                "health": value["health"],
                "app": value["app"],
                "snapshot_count": value["snapshot_count"],
                "avg_rss_mb": f"{value['rss_total'] / count:.2f}",
                "max_rss_mb": f"{value['rss_max']:.2f}",
                "avg_cpu_pct": f"{value['cpu_total'] / count:.1f}",
                "max_cpu_pct": f"{value['cpu_max']:.1f}",
                "avg_process_count": f"{value['process_count_total'] / count:.2f}",
                "max_process_count": value["process_count_max"],
            }
        )
    return sorted(out_rows, key=lambda item: (item["health"], -safe_float(item["max_rss_mb"])))


def build_health_counts(metric_rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    counts = Counter((row["health"] or "UNKNOWN") for row in metric_rows)
    return [{"health": health, "snapshot_count": count} for health, count in sorted(counts.items())]


def build_degraded_windows(metric_rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out_rows: List[Dict[str, Any]] = []
    for row in metric_rows:
        reported_health = (row["health"] or "").strip()
        health = reported_health or "UNKNOWN"
        degraded = (
            # A snapshot with no health verdict is unknown, not degraded.
            # Treating it as degraded put every row of a history whose
            # memory_metrics.csv predates the health column into
            # helper_degraded_windows.csv, contradicting the thresholds the
            # generated Markdown prints.
            (reported_health != "" and reported_health != "OK")
            or row["swap_used_mb"] >= 1024
            # Explicit None test: a genuine 0.0 (worst possible free
            # percentage) is falsy and was silently skipped by a truthiness
            # check.
            or (row["memory_pressure_free_pct"] is not None and row["memory_pressure_free_pct"] < 20)
            or row["delta_swapouts"] > 0
        )
        if not degraded:
            continue
        out_rows.append(
            {
                "timestamp": row["timestamp_label"],
                "event": row["event"],
                "health": health,
                "used_est_gb": f"{row['used_est_gb']:.2f}",
                "free_gb": f"{row['free_gb']:.2f}",
                "swap_used_mb": f"{row['swap_used_mb']:.2f}",
                "memory_pressure_free_pct": f"{row['memory_pressure_free_pct']:.1f}",
                "delta_pageouts": row["delta_pageouts"],
                "delta_swapouts": row["delta_swapouts"],
                "seconds_since_last": row["seconds_since_last"],
                "report_file": row["report_file"],
                "top_process_file": row["top_process_file"],
                "source_file": row["source_file"],
            }
        )
    return out_rows


def build_input_inventory(
    app_rows: List[Dict[str, Any]],
    process_rows: List[Dict[str, Any]],
    metric_rows: List[Dict[str, Any]],
    memory_report_rows: List[Dict[str, Any]],
    diagnostics_text_rows: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    counts: Dict[Tuple[str, str], int] = defaultdict(int)
    for row in app_rows:
        counts[("app_rollup_csv", row["source_file"])] += 1
    for row in process_rows:
        counts[("process_csv", row["source_file"])] += 1
    for row in metric_rows:
        counts[("memory_metrics_csv", row["source_file"])] += 1
    for row in memory_report_rows:
        counts[("memory_report_txt", row["source_file"])] += 1
    for row in diagnostics_text_rows:
        counts[(row["source_kind"], row["source_file"])] += 1

    return [
        {"source_kind": source_kind, "source_file": source_file, "row_count": row_count}
        for (source_kind, source_file), row_count in sorted(counts.items())
    ]


def generate_summary_markdown(
    path: Path,
    metric_rows: List[Dict[str, Any]],
    app_rows: List[Dict[str, Any]],
    process_summary: List[Dict[str, Any]],
    health_counts: List[Dict[str, Any]],
    degraded_windows: List[Dict[str, Any]],
    snapshot_correlation_rows: List[Dict[str, Any]],
) -> None:
    lines: List[str] = []
    lines.append("# Performance Rollup Summary")
    lines.append("")
    lines.append("This report was generated from mac-memory-health historical outputs. It is intended as a quantitative companion to the pre-image and post-image performance audit bundles.")
    lines.append("")
    lines.append("## Input coverage")
    lines.append("")
    lines.append(f"- Helper metric snapshots: `{len(metric_rows)}`")
    lines.append(f"- App rollup rows: `{len(app_rows)}`")
    lines.append(f"- Process-category snapshots: `{len(process_summary)}`")
    if metric_rows:
        lines.append(f"- Metric time span: `{metric_rows[0]['timestamp_label']}` to `{metric_rows[-1]['timestamp_label']}`")
    lines.append("")
    lines.append("## Health counts")
    lines.append("")
    lines.append("| Health | Snapshot count |")
    lines.append("|---|---:|")
    for row in health_counts:
        lines.append(f"| {row['health']} | {row['snapshot_count']} |")
    lines.append("")
    lines.append("## What counts as degraded")
    lines.append("")
    lines.append("- `CRITICAL` when `memory_pressure_free_pct < 10` or `swap_used_mb >= 4096`")
    lines.append("- `WARN` when `memory_pressure_free_pct < 20` or `swap_used_mb >= 1024`")
    lines.append("- `WATCH` when `delta_swapouts > 0` within a recent sampling window")
    lines.append("- `OK` otherwise")
    lines.append("")
    lines.append("## Degraded windows")
    lines.append("")
    if not degraded_windows:
        lines.append("No degraded helper windows were identified from the parsed metric rows.")
        lines.append("")
    else:
        lines.append("| Timestamp | Health | Used GB | Swap MB | Pressure free % | Delta swapouts |")
        lines.append("|---|---|---:|---:|---:|---:|")
        for row in degraded_windows[:25]:
            lines.append(
                f"| {row['timestamp']} | {row['health']} | {row['used_est_gb']} | {row['swap_used_mb']} | {row['memory_pressure_free_pct']} | {row['delta_swapouts']} |"
            )
        lines.append("")
    if snapshot_correlation_rows:
        lines.append("## App/metric correlation snapshots")
        lines.append("")
        lines.append("| Snapshot | Largest app group | App RSS MB | Health | Swap MB | Pressure free % |")
        lines.append("|---|---|---:|---|---:|---:|")
        for row in snapshot_correlation_rows[:25]:
            lines.append(
                f"| {row['timestamp']} | {row['largest_app_group'] or 'n/a'} | {row['snapshot_total_grouped_rss_mb']} | {row['health'] or 'UNMATCHED'} | {row['swap_used_mb'] or 'n/a'} | {row['memory_pressure_free_pct'] or 'n/a'} |"
            )
        lines.append("")
    lines.append("## Recommended quantitative review order")
    lines.append("")
    lines.append("1. `summary/helper_degraded_windows.csv`")
    lines.append("2. `summary/snapshot_correlation_summary.csv`")
    lines.append("3. `summary/app_rollup_by_health.csv`")
    lines.append("4. `summary/app_rollup_by_snapshot.csv`")
    lines.append("5. `summary/process_category_summary_by_snapshot.csv`")
    lines.append("6. `summary/helper_memory_metrics.csv`")
    lines.append("")
    lines.append("## Notes")
    lines.append("")
    lines.append("- App rollup CSV files remain the primary quantitative source for app-group RSS/CPU/process counts.")
    lines.append("- Diagnostics text reports and memory reports are treated as supplemental sources and inventories; use them when you need corroborating text context.")
    lines.append("- Generate matching pre-image and post-image summary packages for fair comparison.")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Generate quantitative performance rollup summaries from mac-memory-health outputs.")
    parser.add_argument("--input", required=True, help="Folder containing metrics/, diagnostics/, and reports/ data. Searched recursively.")
    parser.add_argument("--output", required=True, help="Output folder for summary CSV and Markdown files.")
    parser.add_argument("--top-n", type=int, default=8, help="Number of top app groups to include in pivot summaries. Default: 8.")
    args = parser.parse_args(argv)

    input_root = Path(args.input).expanduser().resolve()
    output_root = Path(args.output).expanduser().resolve()
    summary_dir = output_root / "summary"

    app_rows = discover_app_rollups(input_root)
    process_rows = discover_process_rows(input_root)
    metric_rows = discover_metric_rows(input_root)
    memory_report_rows = discover_memory_report_rows(input_root)
    diagnostics_text_rows = discover_diagnostics_text_rollups(input_root)

    if not any((app_rows, process_rows, metric_rows, memory_report_rows, diagnostics_text_rows)):
        print(f"No supported performance history files found under {input_root}", file=sys.stderr)
        return 2

    # Created only after the emptiness check: a mistyped --input must not leave
    # behind an empty <output>/summary/ that later reads as a rollup that ran
    # and found a healthy system.
    output_root.mkdir(parents=True, exist_ok=True)
    summary_dir.mkdir(parents=True, exist_ok=True)

    process_summary = summarize_processes(process_rows)
    top_apps = top_items(app_rows, "app", "rss_mb", args.top_n)
    health_counts = build_health_counts(metric_rows)
    degraded_windows = build_degraded_windows(metric_rows)
    snapshot_correlation_rows = build_snapshot_correlation_rows(app_rows, metric_rows) if app_rows else []
    app_health_rows = build_app_health_summary(app_rows, metric_rows) if app_rows else []
    input_inventory_rows = build_input_inventory(app_rows, process_rows, metric_rows, memory_report_rows, diagnostics_text_rows)

    write_csv(summary_dir / "input_inventory.csv", ["source_kind", "source_file", "row_count"], input_inventory_rows)

    write_csv(
        summary_dir / "helper_memory_metrics.csv",
        [
            "timestamp",
            "event",
            "host",
            "used_est_gb",
            "free_gb",
            "active_gb",
            "inactive_gb",
            "wired_gb",
            "compressor_gb",
            "compressed_gb",
            "swap_used_mb",
            "memory_pressure_free_pct",
            "delta_pageouts",
            "delta_swapouts",
            "seconds_since_last",
            "health",
            "report_file",
            "top_process_file",
            "source_file",
        ],
        [
            {
                "timestamp": row["timestamp_label"],
                "event": row["event"],
                "host": row["host"],
                "used_est_gb": f"{row['used_est_gb']:.2f}",
                "free_gb": f"{row['free_gb']:.2f}",
                "active_gb": f"{row['active_gb']:.2f}",
                "inactive_gb": f"{row['inactive_gb']:.2f}",
                "wired_gb": f"{row['wired_gb']:.2f}",
                "compressor_gb": f"{row['compressor_gb']:.2f}",
                "compressed_gb": f"{row['compressed_gb']:.2f}",
                "swap_used_mb": f"{row['swap_used_mb']:.2f}",
                "memory_pressure_free_pct": f"{row['memory_pressure_free_pct']:.1f}",
                "delta_pageouts": row["delta_pageouts"],
                "delta_swapouts": row["delta_swapouts"],
                "seconds_since_last": row["seconds_since_last"],
                "health": row["health"],
                "report_file": row["report_file"],
                "top_process_file": row["top_process_file"],
                "source_file": row["source_file"],
            }
            for row in metric_rows
        ],
    )

    write_csv(summary_dir / "helper_health_counts.csv", ["health", "snapshot_count"], health_counts)
    write_csv(
        summary_dir / "helper_degraded_windows.csv",
        [
            "timestamp",
            "event",
            "health",
            "used_est_gb",
            "free_gb",
            "swap_used_mb",
            "memory_pressure_free_pct",
            "delta_pageouts",
            "delta_swapouts",
            "seconds_since_last",
            "report_file",
            "top_process_file",
            "source_file",
        ],
        degraded_windows,
    )

    write_csv(
        summary_dir / "memory_report_summary.csv",
        [
            "timestamp",
            "event",
            "health",
            "total_gb",
            "used_est_gb",
            "used_est_pct",
            "free_gb",
            "memory_pressure_free_pct",
            "swap_used_mb",
            "delta_pageouts",
            "delta_swapouts",
            "top_process_rss_mb",
            "top_process_command",
            "source_file",
        ],
        [
            {
                "timestamp": row["timestamp_label"],
                "event": row["event"],
                "health": row["health"],
                "total_gb": f"{row['total_gb']:.2f}",
                "used_est_gb": f"{row['used_est_gb']:.2f}",
                "used_est_pct": f"{row['used_est_pct']:.1f}",
                "free_gb": f"{row['free_gb']:.2f}",
                "memory_pressure_free_pct": f"{row['memory_pressure_free_pct']:.1f}",
                "swap_used_mb": f"{row['swap_used_mb']:.2f}",
                "delta_pageouts": row["delta_pageouts"],
                "delta_swapouts": row["delta_swapouts"],
                "top_process_rss_mb": f"{row['top_process_rss_mb']:.2f}",
                "top_process_command": row["top_process_command"],
                "source_file": row["source_file"],
            }
            for row in memory_report_rows
        ],
    )

    write_csv(
        summary_dir / "diagnostics_text_rollup_by_snapshot.csv",
        [
            "timestamp",
            "event",
            "app",
            "rss_mb",
            "cpu_pct",
            "process_count",
            "top_pid",
            "top_rss_mb",
            "sample_command",
            "source_kind",
            "source_file",
        ],
        [
            {
                "timestamp": row["timestamp_label"],
                "event": row["event"],
                "app": row["app"],
                "rss_mb": f"{row['rss_mb']:.2f}",
                "cpu_pct": f"{row['cpu_pct']:.1f}",
                "process_count": row["process_count"],
                "top_pid": row["top_pid"],
                "top_rss_mb": f"{row['top_rss_mb']:.2f}",
                "sample_command": row["sample_command"],
                "source_kind": row["source_kind"],
                "source_file": row["source_file"],
            }
            for row in diagnostics_text_rows
        ],
    )

    write_csv(
        summary_dir / "app_rollup_by_snapshot.csv",
        ["timestamp", "app", "rss_mb", "cpu_pct", "process_count", "top_pid", "top_rss_mb", "sample_command", "source_file"],
        [
            {
                "timestamp": row["timestamp_label"],
                "app": row["app"],
                "rss_mb": f"{row['rss_mb']:.2f}",
                "cpu_pct": f"{row['cpu_pct']:.1f}",
                "process_count": row["process_count"],
                "top_pid": row["top_pid"],
                "top_rss_mb": f"{row['top_rss_mb']:.2f}",
                "sample_command": row["sample_command"],
                "source_file": row["source_file"],
            }
            for row in sorted(app_rows, key=lambda item: (item["timestamp"], -item["rss_mb"]))
        ],
    )

    write_csv(
        summary_dir / "process_category_summary_by_snapshot.csv",
        ["timestamp", "category", "rss_mb", "cpu_pct", "process_count", "top_pid", "top_rss_mb", "top_command"],
        [
            {
                "timestamp": row["timestamp_label"],
                "category": row["category"],
                "rss_mb": f"{row['rss_mb']:.2f}",
                "cpu_pct": f"{row['cpu_pct']:.1f}",
                "process_count": row["process_count"],
                "top_pid": row["top_pid"],
                "top_rss_mb": f"{row['top_rss_mb']:.2f}",
                "top_command": row["top_command"],
            }
            for row in process_summary
        ],
    )

    write_csv(
        summary_dir / "snapshot_correlation_summary.csv",
        [
            "timestamp",
            "snapshot_total_grouped_rss_mb",
            "snapshot_total_grouped_cpu_pct",
            "snapshot_total_grouped_process_count",
            "largest_app_group",
            "largest_app_group_rss_mb",
            "largest_app_group_cpu_pct",
            "health",
            "used_est_gb",
            "free_gb",
            "swap_used_mb",
            "memory_pressure_free_pct",
            "delta_pageouts",
            "delta_swapouts",
            "seconds_since_last",
            "metric_source_file",
        ],
        snapshot_correlation_rows,
    )

    write_csv(
        summary_dir / "app_rollup_by_health.csv",
        ["health", "app", "snapshot_count", "avg_rss_mb", "max_rss_mb", "avg_cpu_pct", "max_cpu_pct", "avg_process_count", "max_process_count"],
        app_health_rows,
    )

    if top_apps:
        write_app_pivot(summary_dir / "app_rss_pivot_top_apps.csv", app_rows, "rss_mb", top_apps)
        write_app_pivot(summary_dir / "app_cpu_pivot_top_apps.csv", app_rows, "cpu_pct", top_apps)
        write_app_pivot(summary_dir / "app_process_count_pivot_top_apps.csv", app_rows, "process_count", top_apps)

    generate_summary_markdown(
        output_root / "performance-rollup-summary.md",
        metric_rows,
        app_rows,
        process_summary,
        health_counts,
        degraded_windows,
        snapshot_correlation_rows,
    )

    print(f"Wrote performance rollup summary output to: {output_root}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
