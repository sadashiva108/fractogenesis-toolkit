#!/usr/bin/env python3
"""Report Postman exports that carry literal credential values.

A Postman export is a JSON tree, so a filename sweep can never see inside one.
The values that matter are usually references -- {{CLIENT_SECRET}} resolved from
an environment, or {{vault:...}} resolved from Postman Vault -- and those are
safe to back up in the clear. What is not safe is a value pasted directly into a
collection: an auth block filled in while debugging, a header typed once and
forgotten, or a token assigned from a pre-request script.

This walks collections, environments and globals and reports every secret-shaped
key whose value is a literal rather than a reference, plus a set of formats that
are credentials regardless of the key they sit under (JWTs, PEM private keys,
provider-specific token prefixes).

Values are never printed. Findings report the key, the value's length, and a
shape label, which is enough to triage without putting a secret on a terminal or
into a report file.

Read-only: nothing is copied, moved, rewritten, or deleted.

Usage:
  .internal/scan-postman-collections.py [--external-only | --onedrive-only]
                                        [--root PATH]... [--context LABEL]
                                        [--dest DIR] [--all]

Options:
  --external-only Scan only the external drive leg: every source in
                  EXTERNAL_TARGETS, with the directory-shaped
                  EXTERNAL_EXCLUDES pruned.
  --onedrive-only Scan only the OneDrive leg: ONEDRIVE_TARGETS sources, pruned
                  by EXTERNAL_EXCLUDES and ONEDRIVE_EXTRA_EXCLUDES.

                  With neither flag, BOTH legs run -- the same convention as
                  bin/backup-home.sh, whose modes these mirror. Each leg is its
                  own indexed run with its own official/ pointer.
  --root PATH     Scan this directory, ignoring the target lists entirely.
                  Repeatable, and it suppresses the both-legs default. Use it
                  to verify the artifact root after a run.
  --context LABEL Sub-label for this run's directory under the report root.
                  Default: pre-image.
  --dest DIR      Report root. Default:
                  $REIMAGE_ARTIFACT_ROOT/loose-secrets-reports
                  The run's context gets the leg appended, so a both-legs run
                  produces <context>-external and <context>-onedrive as two
                  separate indexed runs.
  --report FILE   Write to this exact path instead of a run directory. For a
                  one-off; no MANIFEST row is written.
  --no-report     Terminal only; write nothing.
  --all           List every file scanned, not only those with findings.

Exit codes:
  0  scan completed, no literal credential values found
  1  at least one literal value found (review it)
  2  usage or configuration error
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys

# .internal/home/<this file> -- three levels up is the repository root. Two
# levels reaches .internal/, and every join below adds ".internal" again.
REPO_ROOT = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ---------------------------------------------------------------------------
# Shared run index
#
# `.internal/artifact-runs.sh` is a sourced Bash library: artifact_run_begin
# sets shell variables the caller reads, which Python cannot receive. Rather
# than reimplement the point rules, the manifest format and the pointer
# computation here -- a second implementation that could only ever drift from
# the first -- these call `.internal/artifact-run-cli.sh`, which is the same
# library behind a command line.
# ---------------------------------------------------------------------------

RUN_CLI = os.path.join(REPO_ROOT, ".internal", "artifact-run-cli.sh")


def run_begin(category_root, context):
    """Stage a run and return the staging directory to write into."""
    if not os.path.exists(RUN_CLI):
        die("ERROR: cannot find .internal/artifact-run-cli.sh (run from the repo)")
    r = subprocess.run(
        ["bash", RUN_CLI, "begin", "--category", category_root, "--context", context],
        stdout=subprocess.PIPE, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        die("ERROR: could not stage a run under: %s" % category_root)
    return r.stdout.strip()


def run_finalize(category_root, run_dir, result):
    """Promote and index a staged run. Returns runs/<id>, or "" on failure."""
    r = subprocess.run(
        ["bash", RUN_CLI, "finalize", "--category", category_root,
         "--run-dir", run_dir, "--result", result],
        stdout=subprocess.PIPE, text=True)
    if r.returncode != 0:
        sys.stderr.write("WARNING: the report was written but could not be indexed.\n")
        sys.stderr.write("  Repair with: ./bin/reindex-artifact-runs.sh --category \"%s\"\n"
                         % category_root)
        return ""
    return r.stdout.strip()


CONTENT_INDEX_HEADER = """# Content Scan Index

Append-only, and specific to the scans that read *inside* files rather than
matching filenames: archives (`scan-archive-contents.sh`) and Postman exports
(`scan-postman-collections.py`). The filename sweep that produces
`open-findings.md` cannot see either, so nothing here feeds that ledger or the
Phase 6B gate that reads it.

`MANIFEST.md` beside this file is the canonical run index; this one only adds
what that schema cannot carry.

| Completed | Context | Run | Scan | Leg | Scanned | With findings | Report |
|---|---|---|---|---|---:|---:|---|
"""


def write_content_scan_row(category_root, context, run_id, scan, leg,
                           scanned, findings):
    """Append this run's domain columns to content-scan-index.md."""
    index = os.path.join(category_root, "content-scan-index.md")
    if not os.path.exists(index):
        with open(index, "w", encoding="utf-8") as fh:
            fh.write(CONTENT_INDEX_HEADER)
    with open(index, "a", encoding="utf-8") as fh:
        fh.write("| %s | `%s` | `%s` | %s | %s | %d | %d | "
                 "[Open report](runs/%s/postman-export-scan.md) |\n"
                 % (datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    context, run_id, scan, leg, scanned, findings, run_id))


def die(message):
    """Usage and configuration errors exit 2, per the documented codes.

    sys.exit("text") exits 1, which this script reserves for "findings were
    found" -- so a config mistake would have been indistinguishable from a hit.
    """
    print(message, file=sys.stderr)
    raise SystemExit(2)

POSTMAN_SUFFIXES = (
    ".postman_collection.json",
    ".postman_environment.json",
    ".postman_globals.json",
)

# Keys whose value is expected to be a credential.
SECRET_KEY = re.compile(
    r"(secret|token|password|passwd|pwd|api[_-]?key|apikey|access[_-]?key"
    r"|private[_-]?key|client[_-]?id|credential|authorization|auth[_-]?header"
    r"|consumer[_-]?(key|secret)|refresh|bearer|session)",
    re.I,
)

# A value that resolves at request time is not a stored secret.
REFERENCE = re.compile(
    r"^\s*(\{\{.*\}\}|\$\{.*\}|<[^>]*>|\$env[.:].*|process\.env\..*)\s*$"
)
PLACEHOLDER = re.compile(
    r"^\s*(changeme|change_me|placeholder|redacted|removed|todo|tbd|none|null"
    r"|n/?a|xxx+|\*+|your[-_ ]?(client|api|token|secret).*|example|sample"
    r"|dummy|test|fake|foo|bar)\s*$",
    re.I,
)

# Formats that are credentials whatever key they sit under.
STRONG = [
    ("JWT", re.compile(r"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}")),
    ("PEM private key", re.compile(r"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----")),
    ("AWS access key id", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("GitHub token", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("Google API key", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("Authorization: Basic", re.compile(r"(?i)\bbasic\s+[A-Za-z0-9+/]{16,}={0,2}\b")),
    ("Authorization: Bearer", re.compile(r"(?i)\bbearer\s+(?!\{\{)[A-Za-z0-9._-]{20,}\b")),
    ("client_secret in body", re.compile(r"(?i)client_secret=(?!\{\{|%7B)[^&\s\"']{8,}")),
]

UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
HEXONLY = re.compile(r"^[0-9a-f]+$", re.I)
B64ISH = re.compile(r"^[A-Za-z0-9+/_-]+={0,2}$")


def shape(value):
    v = value.strip()
    if UUID.match(v):
        return "UUID"
    if len(v) >= 16 and HEXONLY.match(v):
        return "hex-%d" % len(v)
    if len(v) >= 16 and B64ISH.match(v):
        return "base64ish-%d" % len(v)
    return "literal-%d" % len(v)


def is_reference(value):
    v = value.strip()
    if not v:
        return True
    return bool(REFERENCE.match(v) or PLACEHOLDER.match(v))


def walk(node, path, findings, seen_strings):
    """Recurse the export tree, collecting findings."""
    if isinstance(node, dict):
        # Postman's key/value shape: variables, headers, query params, auth params,
        # form data. One rule covers all of them.
        k = node.get("key")
        if isinstance(k, str) and isinstance(node.get("value"), str):
            v = node["value"]
            disabled = node.get("disabled") is True
            if SECRET_KEY.search(k) and not is_reference(v):
                findings.append({
                    "where": path or "(root)",
                    "kind": "literal value",
                    "key": k,
                    "shape": shape(v),
                    "note": "disabled" if disabled else "",
                })
        for key, val in node.items():
            walk(val, "%s.%s" % (path, key) if path else str(key), findings, seen_strings)
    elif isinstance(node, list):
        for i, val in enumerate(node):
            walk(val, "%s[%d]" % (path, i), findings, seen_strings)
    elif isinstance(node, str):
        if node in seen_strings:
            return
        for label, rx in STRONG:
            m = rx.search(node)
            if m:
                seen_strings.add(node)
                findings.append({
                    "where": path or "(root)",
                    "kind": label,
                    "key": "",
                    "shape": "match-%d" % len(m.group(0)),
                    "note": "",
                })
                break


def scan_file(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            data = json.load(fh)
    except Exception as exc:
        return None, "unreadable: %s" % type(exc).__name__
    findings = []
    walk(data, "", findings, set())
    # Deduplicate: the same key can appear in many requests of one collection.
    unique = {}
    for f in findings:
        sig = (f["kind"], f["key"], f["shape"])
        if sig in unique:
            unique[sig]["count"] += 1
        else:
            f["count"] = 1
            unique[sig] = f
    return sorted(unique.values(), key=lambda f: (f["kind"], f["key"])), None


def config_roots(mode):
    """Ask the shared config for target sources and directory prunes."""
    loader = os.path.join(REPO_ROOT, ".internal", "load-reimage-config.sh")
    if not os.path.exists(loader):
        die("ERROR: cannot find .internal/load-reimage-config.sh (run from the repo)")
    tvar = "ONEDRIVE_TARGETS" if mode == "onedrive" else "EXTERNAL_TARGETS"
    extra = ' ${ONEDRIVE_EXTRA_EXCLUDES[@]+"${ONEDRIVE_EXTRA_EXCLUDES[@]}"}' if mode == "onedrive" else ""
    script = (
        'source "%s" >/dev/null 2>&1 || exit 2\n'
        'printf "SRC\\t%%s\\n" "${%s[@]}"\n'
        'for p in ${EXTERNAL_EXCLUDES[@]+"${EXTERNAL_EXCLUDES[@]}"}%s; do printf "EXCL\\t%%s\\n" "$p"; done\n'
        'printf "ROOT\\t%%s\\n" "${REIMAGE_ARTIFACT_ROOT:-}"\n'
    ) % (loader, tvar, extra)
    out = subprocess.run(["bash", "-c", script], capture_output=True, text=True)
    if out.returncode != 0:
        die("ERROR: could not load shared config:\n%s" % out.stderr.strip())
    roots, prunes, artifact_root = [], [], ""
    for line in out.stdout.splitlines():
        tag, _, rest = line.partition("\t")
        if tag == "SRC":
            src = rest.split("|")[1].strip() if "|" in rest else ""
            if src and os.path.isdir(src):
                roots.append(src.rstrip("/"))
        elif tag == "EXCL":
            p = rest.strip()
            if p.endswith("/"):
                prunes.append(p.rstrip("/"))
        elif tag == "ROOT":
            artifact_root = rest.strip()
    return roots, sorted(set(prunes)), artifact_root


def collect(roots, prunes):
    files = []
    pruneset = set(prunes)
    nested = [p for p in prunes if "/" in p]
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root, followlinks=True):
            dirnames[:] = [
                d for d in dirnames
                if d not in pruneset
                and not any(os.path.join(dirpath, d).endswith(os.sep + n) for n in nested)
            ]
            for fn in filenames:
                if fn.lower().endswith(POSTMAN_SUFFIXES):
                    files.append(os.path.join(dirpath, fn))
    return sorted(set(files))


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--external-only", dest="targets", action="store_true")
    ap.add_argument("--onedrive-only", dest="onedrive", action="store_true")
    ap.add_argument("--root", action="append", default=[])
    ap.add_argument("--report")
    ap.add_argument("--context", default="pre-image")
    ap.add_argument("--dest")
    ap.add_argument("--no-report", dest="no_report", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("-h", "--help", action="store_true")
    args = ap.parse_args()

    if args.help:
        print(__doc__)
        return 0
    if args.targets and args.onedrive:
        die("ERROR: --external-only and --onedrive-only are alternatives; "
            "omit both to run both legs.")
    # A context becomes a directory name, so keep it path-safe.
    if (not args.context or args.context.startswith(".")
            or any(c in args.context for c in "/\\ \t") or ".." in args.context):
        die("ERROR: --context must not be empty or contain slashes, '..', "
                 "a leading dot, or whitespace: %s" % args.context)

    # No leg flag and no --root means BOTH legs, mirroring bin/backup-home.sh.
    # Each leg is its own indexed run: different roots, different prune sets and
    # different counters, so a merged result would mean nothing, and a lineage
    # per leg is what lets official/<context>-onedrive.txt answer "what would be
    # pushed to corporate cloud storage" without also answering the other
    # question.
    if not args.targets and not args.onedrive and not args.root:
        child = ["--context", args.context]
        if args.dest:
            child += ["--dest", args.dest]
        if args.no_report:
            child.append("--no-report")
        if args.all:
            child.append("--all")
        rc = 0
        for flag in ("--external-only", "--onedrive-only"):
            r = subprocess.run([sys.executable, os.path.abspath(__file__), flag] + child)
            rc = max(rc, r.returncode)
        return rc

    # The leg is part of the run's identity, not a column inside it: two legs
    # answer two questions, and a pointer that resolved to whichever ran last
    # would answer neither reliably.
    prunes, leg = [], ""
    run_context = args.context
    roots = [r.rstrip("/") for r in args.root]
    if args.targets or args.onedrive:
        mode = "onedrive" if args.onedrive else "external"
        leg = "OneDrive leg (ONEDRIVE_TARGETS)" if args.onedrive else "external drive leg (EXTERNAL_TARGETS)"
        run_context = "%s-%s" % (args.context, mode)
        derived, prunes, _ = config_roots(mode)
        roots = derived + roots
    if not roots:
        ar = os.environ.get("REIMAGE_ARTIFACT_ROOT", "")
        if not ar:
            _, _, ar = config_roots("external")
        if not ar:
            die("ERROR: no --targets/--onedrive/--root given and REIMAGE_ARTIFACT_ROOT is unset.")
        roots = [ar.rstrip("/")]

    roots = [r for r in dict.fromkeys(roots) if os.path.isdir(r)]
    if not roots:
        die("ERROR: no scannable directory among the roots given.")

    files = collect(roots, prunes)

    print("")
    print("> Postman export scan")
    if leg:
        print("  Leg: %s" % leg)
    print("  " + "-" * 48)
    print("  Scanned %d Postman export(s) under %d director%s:"
          % (len(files), len(roots), "y" if len(roots) == 1 else "ies"))
    for r in roots:
        n = sum(1 for f in files if f.startswith(r + os.sep))
        print("    %6d  %s" % (n, r))
    if prunes:
        print("  Pruned: %s" % ", ".join(prunes))
    print("")

    hits = unreadable = 0
    report_blocks = []
    for path in files:
        findings, err = scan_file(path)
        if err:
            unreadable += 1
            print("  ?   %s  (%s)" % (path, err))
            continue
        if not findings:
            if args.all:
                print("  OK  %s" % path)
            continue
        hits += 1
        print("  !!  %s" % path)
        for f in findings:
            times = "  x%d" % f["count"] if f["count"] > 1 else ""
            key = " %s" % f["key"] if f["key"] else ""
            note = "  (%s)" % f["note"] if f["note"] else ""
            print("        %-22s%-22s %s%s%s" % (f["kind"], key, f["shape"], times, note))
        block = ["", "### `%s`" % path, "", "| Finding | Key | Shape | Count | Note |", "|---|---|---|---:|---|"]
        for f in findings:
            block.append("| %s | `%s` | %s | %d | %s |"
                         % (f["kind"], f["key"], f["shape"], f["count"], f["note"]))
        report_blocks.append("\n".join(block))

    print("")
    if hits:
        print("  %d of %d export(s) carry literal credential values." % (hits, len(files)))
        print("  A literal is a candidate, not proof -- a UUID client id is public, a UUID")
        print("  client secret is not. Decide per file: rewrite the value as a {{reference}},")
        print("  or give the file a SECRETS_TARGETS row so it is encrypted into the DMG.")
    else:
        print("  No export carried a literal credential value (%d scanned)." % len(files))
    if unreadable:
        print("  %d file(s) could not be parsed." % unreadable)

    # Default the report into a run in the Phase 3B sweep's own category. Both
    # answer "is credential material sitting in the clear?", the contexts do not
    # collide, and one MANIFEST.md over both means one place to look rather than
    # an index nested inside an index.
    run_dir = ""
    dest_root = args.dest or ""
    if not args.no_report and not args.report:
        if not dest_root:
            ar = os.environ.get("REIMAGE_ARTIFACT_ROOT", "")
            if not ar:
                _, _, ar = config_roots("external")
            if ar:
                dest_root = os.path.join(ar.rstrip("/"), "loose-secrets-reports")
        if dest_root:
            run_dir = run_begin(dest_root, run_context)
            # The run id carries the leg, so the file inside does not repeat it.
            args.report = os.path.join(run_dir, "postman-export-scan.md")
        else:
            print("  !  REIMAGE_ARTIFACT_ROOT unset and no --dest given; no report written.")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            fh.write("# Postman Export Scan\n\n")
            if leg:
                fh.write("Leg: %s\n\n" % leg)
            fh.write("## Directories scanned\n\n")
            for r in roots:
                n = sum(1 for f in files if f.startswith(r + os.sep))
                fh.write("- `%s` - %d export(s)\n" % (r, n))
            if prunes:
                fh.write("\nPruned: %s\n" % ", ".join("`%s`" % p for p in prunes))
            fh.write("\nValues are never recorded. Each row gives the key, the value's\n"
                     "length, and a shape label.\n\n")
            fh.write("- exports scanned: %d\n" % len(files))
            fh.write("- exports with literal values: %d\n" % hits)
            fh.write("- exports that could not be parsed: %d\n" % unreadable)
            fh.write("\n".join(report_blocks) + "\n")

        # The scan type, the leg and the two counts are this category's own
        # question and the shared schema has no column for them, so they go in a
        # domain index beside the run index -- the same treatment the filename
        # sweep's outside and inside counts get in loose-secrets-index.md.
        # --report is an explicit one-off and appends no history.
        if run_dir:
            run_id = os.path.basename(run_dir).lstrip(".")
            if run_id.endswith(".incomplete"):
                run_id = run_id[:-len(".incomplete")]
            write_content_scan_row(
                dest_root, run_context, run_id, "postman",
                leg or "artifact root", len(files), hits)
            relative = run_finalize(
                dest_root, run_dir,
                "%d scanned / %d with findings" % (len(files), hits))
            if relative:
                print("  Report:        %s" % os.path.join(dest_root, relative,
                                                           "postman-export-scan.md"))
                print("  Run index:     %s" % os.path.join(dest_root, "MANIFEST.md"))
                print("  Domain index:  %s" % os.path.join(dest_root, "content-scan-index.md"))
                print("  Official:      %s"
                      % os.path.join(dest_root, "official", run_context + ".txt"))
        else:
            print("  Report: %s" % args.report)

    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
