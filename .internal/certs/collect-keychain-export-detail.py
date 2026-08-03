#!/usr/bin/env python3
"""collect-keychain-export-detail.py

Enumerate macOS Keychain identities, correlate each to the configuration profile
that delivers it, classify export vs document/re-enroll, and emit the
per-identity keychain-manual-export-checklist (a `.proposed` review artifact).

Data sources (run live by default; the --*-file flags feed captured output
instead, so the tool can run without live sudo and be tested against samples):

  security find-identity -v             -> identity list (sha1 + name)  [--identities-file]
  security find-certificate -a -Z -p    -> all cert PEMs                 [--certs-file]
  profiles show                         -> USER-level profiles           [--profiles-file ...]
  sudo profiles show                    -> COMPUTER-level profiles        [--profiles-file ...]
  profiles status -type enrollment      -> MDM server (optional)         [--enrollment-file]

IMPORTANT: `profiles show` lists payload types and identifiers but NOT the SCEP
server URL or the payload subject. So the enrollment-server field is flagged for
you to read from Device Management; everything else -- fingerprint, subject,
issuer chain, delivery type/level, Intune-managed, exportability -- is auto-filled.
The actual export stays manual; this tool never handles private keys or passwords.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional


# ── data capture ──────────────────────────────────────────────────────────────
def _run(cmd: List[str], sudo: bool = False) -> str:
    if sudo:
        cmd = ["sudo", *cmd]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        return res.stdout
    except OSError as exc:
        print(f"WARNING: could not run {' '.join(cmd)}: {exc}", file=sys.stderr)
        return ""


def load_text(path: Optional[str], live_cmd: Optional[List[str]], sudo: bool = False) -> str:
    if path:
        return Path(path).expanduser().read_text(encoding="utf-8", errors="replace")
    if live_cmd is None:
        return ""
    return _run(live_cmd, sudo=sudo)


# ── identities ────────────────────────────────────────────────────────────────
_IDENT_RE = re.compile(r'^\s*\d+\)\s+([0-9A-Fa-f]{40})\s+"(.*)"\s*$')


def parse_identities(text: str) -> List[Dict[str, str]]:
    """Return deduped identities [{'sha1','name'}], first occurrence wins."""
    seen: set[str] = set()
    out: List[Dict[str, str]] = []
    for line in text.splitlines():
        m = _IDENT_RE.match(line)
        if not m:
            continue
        sha1 = m.group(1).upper()
        if sha1 in seen:
            continue
        seen.add(sha1)
        out.append({"sha1": sha1, "name": m.group(2)})
    return out


# ── certificates ──────────────────────────────────────────────────────────────
_PEM_RE = re.compile(r"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----", re.DOTALL)


def _cn(dn: str) -> str:
    m = re.search(r"CN\s*=\s*([^,+/]+)", dn or "")
    return m.group(1).strip() if m else (dn or "").strip()


def parse_certs(pem_text: str) -> Dict[str, Dict[str, str]]:
    """sha1 -> {subject, subject_cn, issuer, issuer_cn, not_after} via openssl."""
    certs: Dict[str, Dict[str, str]] = {}
    for block in _PEM_RE.findall(pem_text):
        res = subprocess.run(
            ["openssl", "x509", "-noout", "-subject", "-issuer", "-enddate",
             "-fingerprint", "-sha1"],
            input=block, capture_output=True, text=True, check=False,
        )
        subject = issuer = not_after = fp = ""
        for line in res.stdout.splitlines():
            if line.startswith("subject="):
                subject = line[len("subject="):].strip()
            elif line.startswith("issuer="):
                issuer = line[len("issuer="):].strip()
            elif line.startswith("notAfter="):
                not_after = line[len("notAfter="):].strip()
            elif "Fingerprint=" in line:
                fp = line.split("Fingerprint=", 1)[1].replace(":", "").strip().upper()
        if not fp:
            continue
        certs[fp] = {
            "subject": subject, "subject_cn": _cn(subject),
            "issuer": issuer, "issuer_cn": _cn(issuer),
            "not_after": not_after,
        }
    return certs


def issuer_chain(leaf_issuer_cn: str, by_subject_cn: Dict[str, Dict[str, str]]) -> List[str]:
    """Walk subject->issuer up to a self-signed root. Returns root..issuing order."""
    chain: List[str] = []
    cur = leaf_issuer_cn
    seen: set[str] = set()
    while cur and cur not in seen:
        chain.append(cur)
        seen.add(cur)
        ca = by_subject_cn.get(cur)
        if not ca:
            break
        nxt = ca["issuer_cn"]
        if nxt == cur:  # self-signed root
            break
        cur = nxt
    return list(reversed(chain))


# ── profiles ──────────────────────────────────────────────────────────────────
_PROF_RE = re.compile(r"^(?P<level>\S+)\[(?P<idx>\d+)\]\s+(?P<rest>.*)$")


def parse_profiles(text: str) -> List[Dict]:
    """Parse `profiles show` output into profile dicts (any level prefix)."""
    profs: Dict[str, Dict] = {}
    order: List[str] = []
    for line in text.splitlines():
        m = _PROF_RE.match(line)
        if not m:
            continue
        level, idx, rest = m.group("level"), m.group("idx"), m.group("rest").strip()
        key = f"{level}[{idx}]"
        if key not in profs:
            profs[key] = {
                "level": level,
                "scope": "computer" if level == "_computerlevel" else f"user:{level}",
                "name": "", "identifier": "", "organization": "",
                "installed_by_mdm": False, "payloads": [],
            }
            order.append(key)
        p = profs[key]
        am = re.match(r"attribute:\s*(\w+):\s*(.*)$", rest)
        if am:
            k, v = am.group(1), am.group(2).strip()
            if k == "name":
                p["name"] = v
            elif k == "profileIdentifier":
                p["identifier"] = v
            elif k == "organization":
                p["organization"] = v
            elif k == "installedByMDM":
                p["installed_by_mdm"] = v.upper() == "TRUE"
            continue
        pm = re.match(r"payload\[(\d+)\]\s+(\w+)\s*=\s*(.*)$", rest)
        if pm:
            pidx, field, val = pm.group(1), pm.group(2), pm.group(3).strip()
            payloads = p["payloads"]
            while len(payloads) < int(pidx):
                payloads.append({"type": "", "name": "", "identifier": ""})
            slot = payloads[int(pidx) - 1]
            if field in ("type", "name", "identifier"):
                slot[field] = val
    return [profs[k] for k in order]


def profile_payload_types(p: Dict) -> List[str]:
    return [pl.get("type", "") for pl in p["payloads"]]


# ── classification ────────────────────────────────────────────────────────────
INTUNE_CA_RE = re.compile(r"Intune", re.I)
GUIDish_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)


def _scep_profiles(profiles: List[Dict]) -> List[Dict]:
    return [p for p in profiles
            if any(t.endswith("security.scep") for t in profile_payload_types(p))]


def _uniq(seq: List[str]) -> List[str]:
    return list(dict.fromkeys(seq))


def classify(ident: Dict, cert: Optional[Dict], profiles: List[Dict], mdm_server: str) -> Dict:
    name = ident["name"]
    subj_cn = (cert or {}).get("subject_cn", "")
    issuer_full = (cert or {}).get("issuer", "")
    issuer_cn = (cert or {}).get("issuer_cn", "")
    scep = _scep_profiles(profiles)
    intune_server = mdm_server or "Intune (i.manage.microsoft.com)"

    result = {
        "status": "TODO_REVIEW", "exportable": "Unknown",
        "delivery": "Unknown — no matching profile in captures",
        "enrollment_server": "TODO", "restore": "TODO", "confidence": "LOW",
    }

    # 1) Azure AD device registration (Workplace Join) — auto, not a SCEP profile.
    if "MS-Organization-Access" in issuer_full:
        result.update(
            status="DOCUMENT", exportable="No",
            delivery="Azure AD device registration (Workplace Join; MS-Organization-Access)",
            enrollment_server="Azure AD / Intune (automatic on device join)",
            restore="Re-registers automatically on Azure AD join / Intune enrollment.",
            confidence="HIGH")
        return result

    # 2) Intune-native, computer-level, auto-reprovisioned (agent, then device).
    if "Intune MDM Agent CA" in issuer_full or name.startswith("IntuneMDMAgent"):
        prof = [p for p in scep if p["scope"] == "computer"
                and ("MdmAgent" in p["identifier"] or "Agent" in p["name"])]
        result.update(
            status="DOCUMENT", exportable="No",
            delivery="Intune MDM Agent SCEP (computer-level)"
            + (f": {prof[0]['name']}" if prof else ""),
            enrollment_server=intune_server,
            restore="Re-provisions automatically on Intune re-enrollment.",
            confidence="HIGH")
        return result
    if "Intune MDM Device CA" in issuer_full:
        prof = [p for p in scep if p["scope"] == "computer"
                and "MdmAgent" not in p["identifier"]
                and (p["identifier"].endswith("Profiles.SCEP") or p["name"].strip() == "SCEP Profile")]
        result.update(
            status="DOCUMENT", exportable="No",
            delivery="Intune MDM device SCEP (computer-level)"
            + (f": {prof[0]['name']}" if prof else ""),
            enrollment_server=intune_server,
            restore="Re-provisions automatically on Intune re-enrollment.",
            confidence="HIGH")
        return result

    # 3) Internal-PKI client cert delivered via a user-scope SCEP profile (NDES/ADCS).
    user_scep = _uniq([p["name"] for p in scep if p["scope"] != "computer"])
    if user_scep and issuer_cn:
        one = len(user_scep) == 1
        result.update(
            status="DOCUMENT", exportable="No",
            delivery=f"Intune SCEP (user-level) via {issuer_cn}",
            enrollment_server=(f"(read from profile '{user_scep[0]}' in Device Management)"
                               if one else
                               f"(read from a SCEP profile in Device Management; candidates: {'; '.join(user_scep)})"),
            restore="Re-enroll via Intune after re-enrollment, on corporate network/VPN. "
                    "Do not attempt .p12 restore.",
            confidence="HIGH" if one else "MEDIUM")
        return result

    # 4) Self-signed / local — a real export candidate.
    if subj_cn and subj_cn == issuer_cn:
        result.update(delivery="Self-signed / local (candidate for export)",
                      exportable="Unknown", confidence="LOW")
    return result


# ── render ────────────────────────────────────────────────────────────────────
def render(identities, certs, profiles, mdm_server) -> str:
    by_subject_cn = {c["subject_cn"]: c for c in certs.values() if c["subject_cn"]}
    lines: List[str] = [
        "# Keychain Manual Export Checklist",
        "",
        "Generated by `stage-certs-keychain.sh keychain-detail`.",
        "",
        "One block per Keychain identity. Auto-filled from `security` + `profiles`; "
        "confirm each block and fill any TODO. `profiles show` cannot expose the SCEP "
        "server URL, so that field points you at the delivering profile in Device Management.",
        "",
        "Save any `.p12`/`.pfx` export password only in the approved password manager. "
        "Never put a password in this file, a filename, a script, OneDrive, iCloud, or the backup folder.",
        "",
        "Status legend: **EXPORT** (export + stage) · **DOCUMENT** (record + re-enroll, no export) "
        "· **TODO_REVIEW** (decide by hand) · **SKIP** (ignore).",
        "",
    ]

    def sort_key(i):
        cert = certs.get(i["sha1"], {})
        cl = classify(i, cert, profiles, mdm_server)
        return (0 if cl["status"] != "DOCUMENT" else 1, i["name"].lower(), i["sha1"])

    for ident in sorted(identities, key=sort_key):
        cert = certs.get(ident["sha1"], {})
        cl = classify(ident, cert, profiles, mdm_server)
        subj_cn = cert.get("subject_cn", "") or ident["name"]
        chain = issuer_chain(cert.get("issuer_cn", ""), by_subject_cn) if cert else []
        chain_str = " → ".join(chain) if chain else (cert.get("issuer_cn", "") or "(unknown)")
        scope_word = "ssl-client" if not GUIDish_RE.match(subj_cn or "") \
            and not ident["name"].startswith("IntuneMDMAgent") else "all"
        note = f"auto ({cl['confidence']}): delivery + issuer chain derived from captures. " \
               f"VERIFY enrollment server in Device Management" + \
               ("; decide export vs document." if cl["status"] == "TODO_REVIEW" else ".")

        lines += [
            "---",
            "",
            f"## {ident['name']} — {scope_word} — {ident['sha1']}",
            "",
            f"- Status:            {cl['status']}",
            f"- Exportable:        {cl['exportable']}",
            f"- Delivery:          {cl['delivery']}",
            f"- Enrollment server: {cl['enrollment_server']}",
            f"- Issuer chain:      {chain_str}",
            f"- Subject:           {cert.get('subject_cn','(unknown)')}",
            f"- Expires:           {cert.get('not_after','(unknown)')}",
            f"- Export attempt:    (not attempted)",
            f"- Export target:     (none)",
            f"- Password entry:    N/A",
            f"- Restore:           {cl['restore']}",
            f"- Notes:             {note}",
            "",
        ]

    lines += [
        "## Sign-off",
        "",
        "- [ ] Each listed identity was reviewed in Keychain Access.",
        "- [ ] Exported `.p12`/`.pfx` files were saved only under `secrets-encrypted/certs/keychain-manual-exports/`.",
        "- [ ] Public-only `.cer`/`.pem` exports were staged intentionally and contain no private keys.",
        "- [ ] Non-exportable identities were documented with their delivery + restore source.",
        "- [ ] Export passwords were saved only in the approved password manager (failed-export passwords discarded).",
        "- [ ] Phase 2F will be rerun after any new manual export is added.",
        "",
    ]
    return "\n".join(lines)


# ── rollups: export summary + public inventory (same classification) ──────────
EXPORT_EXTS = {".p12", ".pfx", ".cer", ".pem", ".crt", ".der"}


def classify_all(identities, certs, profiles, mdm_server):
    return [(i, certs.get(i["sha1"], {}),
             classify(i, certs.get(i["sha1"], {}), profiles, mdm_server))
            for i in identities]


def scan_exports(dirpath):
    """Actual exported cert files under keychain-manual-exports/ (never .md/README)."""
    if not dirpath:
        return []
    p = Path(dirpath).expanduser()
    if not p.is_dir():
        return []
    return sorted(f.name for f in p.iterdir()
                  if f.is_file() and f.suffix.lower() in EXPORT_EXTS)


def scan_staged_loose(dirpath):
    """{subdir: [filenames]} for the loose/project/tool staged cert dirs."""
    out = {}
    if not dirpath:
        return out
    base = Path(dirpath).expanduser()
    for sub in ("loose-candidates-selected", "project-local", "tool-local"):
        d = base / sub
        if d.is_dir():
            files = sorted(f.name for f in d.iterdir() if f.is_file())
            if files:
                out[sub] = files
    return out


def _group(cl):
    d = cl["delivery"]
    if d.startswith("Azure AD"):
        return "aad"
    if "Agent SCEP" in d or "device SCEP" in d or "MDM" in d:
        return "intune_native"
    if "user-level" in d or "via " in d:
        return "internal_pki"
    return "other"


def render_summary(rows, exported, staged_loose, checklist_name):
    documented = [r for r in rows if r[2]["status"] == "DOCUMENT"]
    candidates = [r for r in rows if r[2]["status"] != "DOCUMENT"]
    has = {g: any(_group(r[2]) == g for r in rows) for g in ("internal_pki", "intune_native", "aad")}
    L = [
        "# Keychain Certificate Export Summary", "",
        f"Generated by `stage-certs-keychain.sh keychain-detail`. Per-identity detail: `{checklist_name}`.",
        "",
        "## Result",
        f"Keychain identities reviewed: {len(rows)}. Exportable candidates: {len(candidates)}. "
        f"Non-exportable (document + re-enroll): {len(documented)}.",
        "Files actually exported under `keychain-manual-exports/`: "
        + (f"{len(exported)} ({', '.join(exported)})." if exported else "0 — none."),
        "",
        "## Password handling",
        ("- `.p12`/`.pfx` export password stored in approved password manager entry: TODO_ENTRY_NAME"
         if exported else "- No exports performed, so no export passwords were created."),
        "- No export passwords are stored in notes, scripts, filenames, cloud storage, or this backup folder.",
        "",
        "## Restore plan",
    ]
    if has["internal_pki"]:
        L.append("- Internal-PKI client identities: re-enroll via Intune SCEP over the internal corporate NDES/ADCS endpoint, on corporate network/VPN. Do not attempt .p12 restore.")
    if has["intune_native"]:
        L.append("- Intune device/agent identities: re-provision automatically on Intune re-enrollment.")
    if has["aad"]:
        L.append("- Azure AD Workplace Join cert: re-registers automatically on Azure AD join / Intune enrollment.")
    if staged_loose:
        total = sum(len(v) for v in staged_loose.values())
        L.append(f"- Staged CA public certs ({total}) under certs/{', certs/'.join(staged_loose)}/: reinstall internal TLS trust only if needed.")
    L += [
        "",
        "## Sign-off",
        f"- [{'x' if not candidates else ' '}] Public certs exported or intentionally skipped.",
        "- [x] Keychain identities inventoried (see checklist above).",
        "- [ ] Private-key export failure documented, if applicable.",
        "- [x] Duplicate-looking certificates reviewed by fingerprint (deduped by SHA-1).",
        "- [ ] These files stay staged until the Phase 2F DMG is created, mounted, and verified.",
        "",
    ]
    return "\n".join(L)


def _generic_delivery(cl):
    d = cl["delivery"]
    if d.startswith("Azure AD"):
        return "Azure AD device registration (Workplace Join)"
    if "Agent SCEP" in d:
        return "Intune-managed agent identity"
    if "device SCEP" in d or "MDM device" in d:
        return "Intune-managed device identity"
    if "user-level" in d:
        return "Intune SCEP via internal corporate PKI"
    return d


def render_inventory(rows, staged_loose):
    L = [
        "# Certificate and Keychain Export Inventory", "",
        "Public-only record — no private keys, passwords, or internal hostnames. "
        "Generated by `stage-certs-keychain.sh keychain-detail`.", "",
        "## Export decisions", "",
        "| Item | Source | Decision | Destination | Password needed? | Restore plan |",
        "|---|---|---|---|---|---|",
    ]
    for (i, c, cl) in rows:
        item = c.get("subject_cn") or i["name"]
        decision = "Document — non-exportable" if cl["status"] == "DOCUMENT" else "Review / export"
        dest = "(none)" if cl["status"] == "DOCUMENT" else "keychain-manual-exports/"
        restore = cl["restore"].replace("Do not attempt .p12 restore.", "").strip().rstrip(".") or "—"
        L.append(f"| {item} | Keychain (login) | {decision} | {dest} | No | {restore} |")
    for sub, files in staged_loose.items():
        L.append(f"| Staged CA public certs ({len(files)}) | Filesystem | Stage public copy "
                 f"| secrets-encrypted/certs/{sub}/ | No | Reinstall internal TLS trust only if needed |")
    L += [
        "", "## Sign-off",
        "- [x] Keychain login / System / My Certificates reviewed.",
        "- [x] Non-exportable identities documented with re-enrollment source.",
        "- [x] No export passwords created or stored (this is the unencrypted record).",
        "- [x] Loose CA certs staged narrowly, not bulk-copied.",
        "",
    ]
    return "\n".join(L)


# ── main ──────────────────────────────────────────────────────────────────────
def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Build the keychain export/restore checklist.")
    ap.add_argument("--identities-file")
    ap.add_argument("--certs-file")
    ap.add_argument("--profiles-file", action="append", default=[],
                    help="Captured `profiles show` dump (repeatable: user + computer).")
    ap.add_argument("--enrollment-file")
    ap.add_argument("--fingerprint", help="Limit output to one identity (SHA-1).")
    ap.add_argument("--out", help="Write checklist here (default: stdout).")
    ap.add_argument("--summary-out", help="Also write the export summary here (encrypted-side).")
    ap.add_argument("--inventory-out", help="Also write the public export inventory here (generic; no hostnames).")
    ap.add_argument("--exports-dir", help="keychain-manual-exports/ dir, scanned to report what was actually exported.")
    ap.add_argument("--staged-loose-dir", help="certs/ dir, scanned to list staged loose CA certs in the rollups.")
    args = ap.parse_args(argv)

    identities = parse_identities(
        load_text(args.identities_file, ["security", "find-identity", "-v"]))
    certs = parse_certs(
        load_text(args.certs_file, ["security", "find-certificate", "-a", "-Z", "-p"]))

    if args.profiles_file:
        prof_text = "\n".join(Path(p).expanduser().read_text(encoding="utf-8", errors="replace")
                              for p in args.profiles_file)
    else:
        prof_text = _run(["profiles", "show"]) + "\n" + _run(["profiles", "show"], sudo=True)
    profiles = parse_profiles(prof_text)

    mdm_server = ""
    enr = load_text(args.enrollment_file, ["profiles", "status", "-type", "enrollment"])
    m = re.search(r"MDM server:\s*(\S+)", enr)
    if m:
        mdm_server = f"Intune ({re.sub(r'^https?://', '', m.group(1)).split('/')[0]})"

    if args.fingerprint:
        fp = args.fingerprint.replace(":", "").upper()
        identities = [i for i in identities if i["sha1"] == fp]

    if not identities:
        print("No identities found. Pass --identities-file or run where `security` works.",
              file=sys.stderr)
        return 1

    out = render(identities, certs, profiles, mdm_server)
    if args.out:
        Path(args.out).expanduser().write_text(out, encoding="utf-8")
        print(f"Wrote {len(identities)} identities to {args.out}")
    else:
        sys.stdout.write(out)

    if args.summary_out or args.inventory_out:
        rows = classify_all(identities, certs, profiles, mdm_server)
        exported = scan_exports(args.exports_dir)
        staged = scan_staged_loose(args.staged_loose_dir)
        checklist_name = Path(args.out).name if args.out else "keychain-manual-export-checklist"
        if args.summary_out:
            Path(args.summary_out).expanduser().write_text(
                render_summary(rows, exported, staged, checklist_name), encoding="utf-8")
            print(f"Wrote export summary to {args.summary_out}")
        if args.inventory_out:
            Path(args.inventory_out).expanduser().write_text(
                render_inventory(rows, staged), encoding="utf-8")
            print(f"Wrote export inventory to {args.inventory_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
