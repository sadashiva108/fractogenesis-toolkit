#!/usr/bin/env python3
"""
extract-metadata.py -- one-way extraction of framework state from the tree.

Reads the markdown that is authoritative today and writes the metadata.json
that becomes authoritative tomorrow. Migration step 1 of
docs/architecture/state-as-data.md section 9.

CLASSIFICATION: .internal/ai-scripts/session-management/ helper. Not a bin/
entrypoint: it runs once per migration, and bin/verify-session-findings.sh is
the callsite for anything a session runs routinely.

Written ONCE and thrown away is the point. It is the third generation of the
markdown parser 0043 F3 is about, and the last one ever written -- everything
after this reads JSON.

It does NOT create documents and it does NOT modify the markdown. It only adds
metadata.json beside what exists, which makes the whole run reversible with rm.

Usage:
  python3 .internal/ai-scripts/session-management/extract-metadata.py [--dry-run]
  python3 .internal/ai-scripts/session-management/extract-metadata.py --check
"""
import json, os, re, sys, subprocess, datetime

ROOT = subprocess.run(["git","rev-parse","--show-toplevel"],capture_output=True,text=True).stdout.strip()
DRY = "--dry-run" in sys.argv
NOW = datetime.datetime.now().astimezone().replace(microsecond=0).isoformat()

FINDING_TREES = ["docs/session-management-findings","docs/cross-cutting-findings",
                 "docs/instruction-set-findings","docs/runbook-findings"]

def read(p):
    try: return open(os.path.join(ROOT,p)).read()
    except (IOError,OSError): return None

def rows(md, pat):
    """Table rows whose first cell matches pat. Returns list of cell lists."""
    out=[]
    for ln in md.split("\n"):
        if not ln.strip().startswith("|"): continue
        cells=[c.strip() for c in ln.strip().strip("|").split("|")]
        if cells and re.match(pat, cells[0]): out.append(cells)
    return out

def unwrap(v):
    """Strip markdown ornament from a value. Presentation never enters data."""
    if v is None: return None
    v = v.strip()
    if v in ("", "-", "--", "—", "–"): return None
    v = re.sub(r'^`(.*)`$', r'\1', v.strip())
    # No markdown ornament inside a value -- state-as-data section 4.1. The
    # renderer adds the backticks; the data holds the fact. An earlier run left
    # "configured `claude-opus-5`" in a model field, which is a rendering
    # instruction stored as data.
    v = v.replace("`","")
    return v.strip() or None

def header_fields(md):
    """Bold field lines from the title to the first non-field line. Repeatable
    fields accumulate -- 0043 F6: a scalar cannot be widened back into a list.

    THE FIRST VERSION OF THIS FUNCTION WAS WRONG in three ways, and the parallel
    session found them by reading the output rather than by any check passing or
    failing. All three are recorded because they are 0043 F3 happening inside the
    migration away from 0043 F3 -- a markdown parser, wrong, at the moment it was
    being retired.

      1. `lstrip(": ")` stripped the colon and the space and NOT the closing
         `**`, so 162 values began with two asterisks. The bold marker is
         presentation and section 4.1 forbids it in a value.
      2. A field whose value is a BULLET LIST -- `**Read:**` followed by
         `- item` lines -- captured the empty remainder of the label line and
         stopped. Nine bundles lost 39 bullets that way.
      3. `Session:` was stored whole into `sessionId`, leaving `sessionBundle`
         null. That is the field split the schema exists to enforce, undone by
         the thing populating it.
    """
    fields = {}
    lines = md.split("\n")
    seen = False
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("# "):
            seen = True; i += 1; continue
        if not seen:
            i += 1; continue
        m = re.match(r'^\*\*([A-Z][^:*]*):?\*?\*?:?', ln)
        if not m:
            if ln.strip() == "" or ln.startswith("**"):
                i += 1; continue
            break
        name = m.group(1).strip()
        val = ln[m.end():]
        # The closing bold marker, whichever side of the colon it fell on.
        val = re.sub(r'^\*\*', '', val.lstrip(": ")).lstrip(": ").strip()
        val = re.sub(r'\s+$', '', val)

        if not val:
            # A list-valued field: collect the bullets that follow, across at
            # most one blank line. This is what lost 39 lines.
            j = i + 1
            items = []
            while j < len(lines):
                nxt = lines[j]
                if nxt.strip() == "" and not items:
                    j += 1; continue
                b = re.match(r'^[-*] +(.*)$', nxt.strip())
                if b:
                    items.append(b.group(1).strip()); j += 1; continue
                break
            if items:
                fields.setdefault(name, []).extend(items)
                i = j; continue
        if val:
            fields.setdefault(name, []).append(val)
        i += 1
    return fields

def split_session(v):
    """`bundle-name` (`session_id`) -> (bundle, id). Either half may be absent:
    older headers carry only a raw session id, newer ones carry both."""
    if not v: return (None, None)
    v = unwrap(v) or ""
    v = v.replace("`", "").strip()
    if not v: return (None, None)
    m = re.match(r'^(.*?)\s*\(\s*(session_[A-Za-z0-9]+)\s*\)\s*$', v)
    if m:
        return (m.group(1).strip() or None, m.group(2))
    if v.startswith("session_") or re.match(r'^[0-9A-Za-z]{20,}$', v):
        return (None, v)
    return (v or None, None)

def title(md):
    for ln in md.split("\n"):
        if ln.startswith("# "): return ln[2:].strip()
    return None

def section_heading_for(md, ident):
    for ln in md.split("\n"):
        if re.match(r'^#{2,3} +%s\b' % re.escape(ident), ln):
            return ln.lstrip("#").strip()
    return None

def git_first_date(path):
    r = subprocess.run(["git","-C",ROOT,"log","--format=%ad","--date=short","--follow","--",path],
                       capture_output=True,text=True).stdout.strip().split("\n")
    return r[-1] if r and r[-1] else None

# ---------------------------------------------------------------------------
# Provenance: which predecessor finding became which successor finding.
#
# Derived by COMPARING STATEMENTS, never guessed. Identical statement ->
# carried; changed statement at the same id -> successor; a predecessor id with
# no counterpart -> dropped. A successor with no counterpart gets NO edge at
# all, because 0039 D12 makes `new` derived from the absence of one.
#
# Coverage and exclusivity are asserted here rather than left to a later check:
# an extraction that silently loses a finding is the failure the gate exists to
# prevent, and this is the run that would introduce it.
# ---------------------------------------------------------------------------
def supersedes_target(md):
    for v in header_fields(md).get("Relates to", []):
        if "supersedes it" in v:
            m = re.search(r'`?(\d{4})[-`]', v) or re.search(r'/(\d{4})-', v)
            if m: return m.group(1)
    return None

def finding_rows(md):
    return {c[0]: c[1] for c in rows(md, r'^F\d+$')}

def provenance(old_md, new_md, old_num, new_num, session, today):
    old, new = finding_rows(old_md), finding_rows(new_md)
    edges=[]
    for fid, stmt in old.items():
        if fid in new:
            same = re.sub(r'\s+',' ',stmt).strip() == re.sub(r'\s+',' ',new[fid]).strip()
            edges.append({
                "kind": "carried" if same else "successor",
                "from": f"{new_num}/{fid}", "to": f"{old_num}/{fid}",
                "why": None if same else "the statement changed in the superseding reading",
                "reason": None if same else "restated",
                "basis": "derived", "asserted_by": session, "asserted_on": today})
        else:
            edges.append({
                "kind": "dropped", "from": new_num, "to": f"{old_num}/{fid}",
                "why": "no counterpart in the superseding reading",
                "reason": "no-longer-applies",
                "basis": "derived", "asserted_by": session, "asserted_on": today})
    # 0039 D12: coverage, then exclusivity.
    covered = set()
    for e in edges: covered.add(e["to"].split("/")[-1])
    missing = set(old) - covered
    if missing: raise SystemExit(f"COVERAGE FAIL {old_num}->{new_num}: unaccounted {sorted(missing)}")
    seen={}
    for e in edges:
        t=e["to"]; seen.setdefault(t,[]).append(e["kind"])
    for t,kinds in seen.items():
        if "dropped" in kinds and len(kinds)>1:
            raise SystemExit(f"EXCLUSIVITY FAIL {t}: dropped alongside {kinds}")
    return edges

# ---------------------------------------------------------------------------
# Findings bundle
# ---------------------------------------------------------------------------
def bundle_json(tree, name):
    d = os.path.join(tree, name)
    fmd = read(os.path.join(d,"findings.md"))
    if fmd is None: return None
    h = header_fields(fmd)
    num = name.split("-")[0]
    sub = None
    if tree.endswith("runbook-findings"): sub = os.path.basename(os.path.dirname(os.path.join(ROOT,tree,name)))
    kind = {"docs/session-management-findings":"session-management",
            "docs/cross-cutting-findings":"cross-cutting",
            "docs/instruction-set-findings":"instruction-set"}.get(tree,"runbook")

    # The STATUS- tag was read here during the migration, to prove the
    # derivation reproduced it. It did, on all 47 bundles, and the tags were
    # removed at Revision 222. `ownership` and `lineage` survive as FIELDS,
    # because the legend already said they were never progress; `progress`
    # itself is derived and never stored.
    tag = None

    findings=[]
    for c in rows(fmd, r'^F\d+$'):
        fid, stmt, status = c[0], c[1], unwrap(c[-1])
        findings.append({
            "id": fid, "statement": stmt, "status": status,
            "statusReason": None, "statusNote": None,
            "updatedAt": None,
            "sectionHeading": section_heading_for(fmd, fid),
            "reopened": None, "withdrawn": None, "resolution": None})

    dmd = read(os.path.join(d,"decisions.md"))
    decisions=[]
    if dmd:
        for c in rows(dmd, r'^D\d+$'):
            if len(c) < 5: continue
            out = unwrap(c[-1])
            # 0039 D9: the Outcome vocabulary. refined/superseded -> replaced.
            if out and out.startswith("superseded"): out = out.replace("superseded","replaced",1)
            if out and out.startswith("refined"):    out = out.replace("refined","replaced",1)
            decisions.append({
                "id": c[0], "decision": c[1],
                "findings": [x.strip() for x in c[2].split(",") if x.strip() and x.strip() not in ("—","-")],
                "decided": unwrap(c[3]), "outcome": out or "proposed",
                "answersAsOf": None, "voidedReason": None,
                "sectionHeading": section_heading_for(dmd, c[0])})

    rmd = read(os.path.join(d,"resolutions.md"))
    if rmd:
        by = {c[0]: c for c in rows(rmd, r'^F\d+$')}
        for f in findings:
            c = by.get(f["id"])
            if not c or len(c) < 5: continue
            # NOT named `by`: that is the row index above, and shadowing it
            # turned a dict into a list one line later.
            res_by = [u for u in (unwrap(x) for x in c[1].split(",")) if u]
            what = unwrap(c[2])
            rev, com = unwrap(c[3]), unwrap(c[4])
            # Section 4.1: no object whose fields are all empty -- a generator
            # renders one as an empty table row. A resolutions.md row that is
            # all dashes records that the finding is NOT resolved, and `null`
            # is how the data says that.
            if any((res_by, what, rev, com)):
                f["resolution"] = {"resolvedBy": res_by, "whatWasDone": what,
                                   "revision": rev, "commit": com}

    contributions=[]
    for c in rows(fmd, r'^`?[a-z0-9-]+-\d{8}-\d{6}`?$'):
        if len(c)>=3: contributions.append({"session":unwrap(c[0]),"date":c[1],"contribution":c[2]})

    return {
      "schemaVersion": 1, "updatedAt": NOW,
      "number": num, "bundleName": name, "kind": kind, "subKind": sub,
      "subject": title(fmd),
      "recordedOn": (h.get("Recorded",[""])[0].split(",")[0] or None),
      "recordedOccasion": (",".join(h.get("Recorded",[""])[0].split(",")[1:]).strip() or None),
      "recordedBy": dict(zip(("sessionBundle","sessionId"),
                             split_session(h.get("Session",[None])[0]))),
      "severity": h.get("Severity",[None])[0],
      "feltAt": h.get("Felt at",[]),
      "scope": h.get("Scope",[None])[0],
      "read": h.get("Read",[]),
      "progress": None,
      "ownership": None,   # computed in main() by scanning session manifests
      "lineage": None,
      "findings": findings, "decisions": decisions,
      "contributions": contributions, "edges": [],
      "indexNotes": None }

# ---------------------------------------------------------------------------
# Session bundle
# ---------------------------------------------------------------------------
def session_json(name):
    d = os.path.join("docs/sessions", name)
    mmd = read(os.path.join(d,"metadata.md"))
    fm  = read(os.path.join(d,"findings-manifest.md"))
    # As above: STATE- tags were removed at Revision 222. `handoff` is the one
    # state a session DECLARES, and it declares it in final-summary.md or in a
    # handoff-<stamp>.md, not in a filename.
    state = "handoff" if any(f.startswith("handoff-") for f in os.listdir(os.path.join(ROOT,d))) \
            and not os.path.exists(os.path.join(ROOT,d,"final-summary.md")) else None

    owners=[]
    if mmd:
        for c in rows(mmd, r'^\d{4}-\d{2}-\d{2}$'):
            if len(c) < 6: continue
            owners.append({"from": c[0], "until": unwrap(c[1]), "assistant": unwrap(c[2]),
                           "sessionId": unwrap(c[3]), "model": unwrap(c[4]),
                           "environment": unwrap(c[5]), "environmentNotes": None})
    transcript=None
    if mmd:
        m = re.search(r'(https://claude\.ai/code/\S+)', mmd)
        if m: transcript = m.group(1).rstrip("`.,")

    resources=[]
    if mmd:
        for c in rows(mmd, r'^[A-Z].*$'):
            if len(c)==2 and c[0] not in ("What","From"):
                # The cell is `path` -- commentary. `path` is atomic and takes
                # only the path; the rest is prose and keeps its own field.
                raw = c[1].strip()
                m2 = re.match(r'^`([^`]+)`\s*(?:[-\u2014\u2013]\s*)?(.*)$', raw)
                if m2:
                    resources.append({"what": c[0], "path": m2.group(1).strip(),
                                      "notes": (m2.group(2).strip() or None)})
                else:
                    resources.append({"what": c[0], "path": unwrap(raw), "notes": None})

    # A session records its end in final-summary.md, which the first extraction
    # run did not read -- three sessions came out `active` against a `closed`
    # tag because of it. That was an extraction bug, not a tree defect, and
    # section 9 step 3 is the step that tells them apart.
    ended = {"on":None,"reason":None,"revisions":[],"commits":[],"disposals":[]}
    fs = read(os.path.join(d,"final-summary.md"))
    if fs:
        m = re.search(r'\*\*Closed (\d{4}-\d{2}-\d{2})\*\*', fs) or \
            re.search(r'closed[^.\n]{0,20}?(\d{4}-\d{2}-\d{2})', fs, re.I)
        ended["on"] = m.group(1) if m else "unknown"
        ended["reason"] = "withdrawn" if re.search(r'\*\*State:\*\* *`?withdrawn', fs) else "closed"

    owned=[]
    if fm:
        for c in rows(fm, r'^\d{4}$'):
            owned.append({"number": c[0], "notes": unwrap(c[-1]) if len(c)>=7 else None})

    return {
      "schemaVersion": 1, "updatedAt": NOW,
      "bundleName": name, "createdOn": git_first_date(d),
      "owners": owners, "transcript": transcript,
      "scratchPath": None, "resources": resources,
      "ownedBundles": owned, "contributions": [],
      "declaredState": state if state=="handoff" else None,
      "indexNotes": None,
      "ended": ended }


# ---------------------------------------------------------------------------
# Derivation -- state-as-data section 4.4
#
# `progress` is COMPUTED and never stored. The ladder shrinks from eight rows to
# five: rows 1, 1b and 2 leave because they were never derivations at all --
# `unclaimed` and `transferred` are ownership, `superseded` is lineage, and each
# now has a field of its own instead of competing for one filename.
#
# This does NOT merge the two vocabularies and must not. The bundle set carries
# judgements no aggregation gives you: `resolved` needs AT LEAST ONE resolved,
# which has no finding-level analogue; row 4 sits above row 5 so a bundle of
# nothing but withdrawals is `withdrawn`, not `resolved`; and `reopened`
# dominates only when reopening is the whole of the live work. It is a bridge
# between two vocabularies, not an identity.
# ---------------------------------------------------------------------------
INERT = ("resolved", "withdrawn")

def derive_progress(findings):
    """Ladder rows 3-7. Returns (progress, why) -- the why names the witness,
    because 0043 F7 is that `analyzing` asserts nothing and a derivation bug
    always lands there looking plausible."""
    st = [f["status"] for f in findings]
    if not st:
        return "un-started", "no findings"
    if all(s == "un-started" for s in st):
        return "un-started", "every finding is un-started"
    if all(s == "withdrawn" for s in st):
        return "withdrawn", "every finding is withdrawn"
    if all(s in INERT for s in st) and any(s == "resolved" for s in st):
        return "resolved", f"every finding inert, {st.count('resolved')} resolved"
    if any(s == "reopened" for s in st) and all(s in INERT for s in st if s != "reopened"):
        return "reopened", f"{st.count('reopened')} reopened, every other finding inert"
    live = sorted(set(s for s in st if s not in INERT))
    return "analyzing", "live findings: " + ", ".join(f"{s}x{st.count(s)}" for s in live)

def derive_state(session):
    """Session states. `handoff` is a declaration -- a session says it handed
    on. The rest follow from what it owns and whether it ended."""
    if session.get("declaredState"):
        return session["declaredState"], "declared"
    ended = session.get("ended") or {}
    if ended.get("on"):
        # An end is decisive. A closed session may still LIST bundles: section 9
        # step 7 keeps a superseded bundle listed by the session that held it,
        # because that file is authoritative for who held a reading. Listing is
        # a historical fact, not live ownership.
        r = (ended.get("reason") or "").lower()
        return ("withdrawn", "ended, reason withdrawn") if "withdraw" in r else ("closed", f"ended {ended['on']}")
    if session.get("ownedBundles"):
        return "active", f"owns {len(session['ownedBundles'])} bundle(s), not ended"
    return "available", "owns nothing, not ended"


# ---------------------------------------------------------------------------
# --check: is the DATA complete against the MARKDOWN it came from?
#
# Every existing checker answers whether a document is well formed. None answers
# whether it is COMPLETE. That gap let 162 contaminated fields and 39 lost
# `Read:` bullets sit in 47 files while verify-session-findings.sh reported 0
# FAIL -- correctly, because the JSON was well formed. It was found by a person
# reading the output.
#
# "Completeness is not conformance" is already a written rule. This is the first
# thing that enforces it.
#
# Deliberately NOT a second parser. A second reader of the same markdown shares
# the first one's blind spots -- the bug being caught here was a regex that
# looked right. These are invariants a parser cannot satisfy by accident:
# presentation cannot survive into a value, and a count in the document must
# equal a length in the data.
# ---------------------------------------------------------------------------
ATOMIC = {
    # Values a renderer would add ornament TO. Nothing else is checked for it.
    "id", "number", "bundleName", "kind", "subKind", "status", "outcome",
    "statusReason", "reason", "basis", "asserted_by", "asserted_on",
    "recordedOn", "recordedOccasion", "decided", "revision", "commit",
    "from", "until", "on", "at", "sha", "assistant", "sessionId",
    "sessionBundle", "model", "schemaVersion", "updatedAt", "answersAsOf",
    "createdOn", "declaredState", "transcript", "scratchPath", "path",
    "ownership", "supersededBy", "supersedes", "voidedReason", "resolvedBy",
}

def check_completeness():
    import glob
    fails = []

    def bad(p, msg):
        fails.append(f"{p}: {msg}")

    for jp in sorted(glob.glob(os.path.join(ROOT, "docs/**/metadata.json"), recursive=True)):
        rel = os.path.relpath(jp, ROOT)
        d = json.load(open(jp))
        src = os.path.join(os.path.dirname(rel),
                           "findings.md" if "number" in d else "metadata.md")
        md = read(src)

        # 1. No presentation in any value, at any depth. One line, and it is the
        #    line that would have caught all 162.
        def walk(node, path=""):
            if isinstance(node, dict):
                for k, v in node.items(): walk(v, f"{path}.{k}" if path else k)
            elif isinstance(node, list):
                for i, v in enumerate(node): walk(v, f"{path}[{i}]")
            elif isinstance(node, str):
                leaf = path.split(".")[-1].split("[")[0]
                # Section 4.1's atomic/prose line. An ATOMIC value carries no
                # ornament: a renderer would ADD the backticks around a status.
                # A PROSE value -- a statement, a note, a why -- is markdown by
                # nature and its inline emphasis is part of the sentence. The
                # first draft of this check flagged 18 prose fields, which is
                # the same false-positive-on-first-run pattern as 0042 F4.
                if leaf in ATOMIC:
                    if "**" in node:
                        bad(rel, f"{path} carries a bold marker: {node[:48]!r}")
                    if node.startswith("`") or node.endswith("`"):
                        bad(rel, f"{path} carries a backtick: {node[:48]!r}")
                if node.strip() in ("-", "--", "—", ""):
                    bad(rel, f"{path} holds a dash or empty string where null belongs")
        walk(d)

        if md is None:
            continue

        # 2. Every bold field line in the markdown reaches a non-empty key. The
        #    map is explicit rather than derived, so a field nobody wired up is
        #    a failure and not a silent omission.
        FIELDMAP = {"Recorded": "recordedOn", "Session": "recordedBy",
                    "Severity": "severity", "Felt at": "feltAt",
                    "Scope": "scope", "Read": "read"}
        # ONLY the header block. `**Felt at:**` also appears inside individual
        # finding sections -- 0001 carries two at lines 93 and 109 -- and
        # searching the whole document reported a header field missing that the
        # header never had. The header ends at the first line that is neither a
        # bold field nor blank.
        hdr_lines = []
        started = False
        for ln in md.split("\n"):
            if ln.startswith("# "): started = True; continue
            if not started: continue
            if ln.startswith("**") or ln.strip() == "" or ln.startswith(("-", "*")):
                hdr_lines.append(ln); continue
            break
        hdr = "\n".join(hdr_lines)

        for label, key in FIELDMAP.items():
            present = re.search(r'^\*\*' + re.escape(label) + r':', hdr, re.M)
            got = d.get(key)
            if present and not got:
                bad(rel, f"markdown has **{label}:** and {key} is empty")

        # 3. A list in the document is a list of the same length in the data.
        #    This is what the Read: bug failed, and a count cannot be faked.
        for label, key in (("Read", "read"), ("Felt at", "feltAt")):
            m = re.search(r'^\*\*' + re.escape(label) + r':\*\*\s*$', hdr, re.M)
            if not m:
                continue
            tail = hdr[m.end():]
            n = 0
            for ln in tail.split("\n"):
                if ln.strip() == "" and n == 0: continue
                if re.match(r'^[-*] +\S', ln.strip()): n += 1
                elif n: break
                elif ln.strip(): break
            have = len(d.get(key) or [])
            if n != have:
                bad(rel, f"**{label}:** lists {n} bullet(s); {key} holds {have}")

        # 4. Row counts. A table row that did not become an object is the
        #    failure mode a well-formedness check cannot see.
        if "number" in d:
            for pat, key in ((r'^\| *F\d+ *\|', "findings"), (r'^\| *D\d+ *\|', "decisions")):
                n = len(re.findall(pat, md, re.M))
                if key == "decisions":
                    dm = read(os.path.join(os.path.dirname(rel), "decisions.md"))
                    n = len(re.findall(pat, dm, re.M)) if dm else 0
                have = len(d.get(key) or [])
                if n != have:
                    bad(rel, f"{n} {key} row(s) in markdown, {have} in data")

    for f in fails:
        print("  FAIL  " + f)
    print(f"\n  {'FAIL' if fails else 'OK'}: {len(fails)} completeness problem(s)")
    return 1 if fails else 0

# ---------------------------------------------------------------------------
def main():
    if "--check" in sys.argv:
        raise SystemExit(check_completeness())

    # ------------------------------------------------------------------
    # THE ONE-WAY GUARD
    #
    # state-as-data.md section 9 step 1 makes this a MIGRATION parser -- "the
    # third generation of the markdown parser 0043 F3 is about, and the last one
    # ever written". Step 5 flips authority: the markdown becomes a projection
    # generated FROM the JSON.
    #
    # Nothing stopped this script running after that flip, and running it then
    # parses generated markdown back into the data that generated it. A round
    # trip through a lossy renderer can only lose: anything the generator does
    # not emit is silently dropped from the source of truth on the next
    # extraction. That is worse than any bug the parser has had, because it
    # would look like a successful run.
    #
    # The generated-region markers of section 6.2 are the witness. If any exist,
    # the markdown is downstream and extraction is refused.
    # ------------------------------------------------------------------
    # Scoped to the files a generator WRITES. The first version searched all of
    # docs/ and fired on state-as-data.md, which documents the marker inside a
    # fenced example -- a guard refusing to run because the design describing it
    # mentions it. Fifth instrument in this repository to fail loudly against a
    # healthy tree on its first run.
    generated = subprocess.run(
        ["grep", "-rl", "--include=findings.md", "--include=decisions.md",
         "--include=resolutions.md", "--include=metadata.md",
         "--include=INDEX.md", "--include=findings-manifest.md",
         "<!-- generated:", os.path.join(ROOT, "docs")],
        capture_output=True, text=True).stdout.strip()
    if generated and "--force" not in sys.argv:
        n = len(generated.split("\n"))
        print(f"REFUSING: {n} document(s) carry generated-region markers, so the", file=sys.stderr)
        print("markdown is a projection of this data rather than its source.", file=sys.stderr)
        print("Extracting now would parse generated output back into the source", file=sys.stderr)
        print("of truth and silently drop whatever the generator does not emit.", file=sys.stderr)
        print("", file=sys.stderr)
        print("This script is single-use by design -- state-as-data.md section 9", file=sys.stderr)
        print("step 1. If you genuinely need it, --force, and say why in the", file=sys.stderr)
        print("manifest entry.", file=sys.stderr)
        raise SystemExit(2)
    written=[]
    bundles={}
    for tree in FINDING_TREES:
        base=os.path.join(ROOT,tree)
        if not os.path.isdir(base): continue
        for dirpath,dirnames,filenames in os.walk(base):
            if "findings.md" not in filenames: continue
            rel=os.path.relpath(dirpath, ROOT)
            parent=os.path.dirname(rel); name=os.path.basename(rel)
            if not re.match(r'^\d{4}-', name): continue
            j=bundle_json(parent, name)
            if j: bundles[j["number"]]=(rel,j)

    # provenance, once every bundle is loaded
    for num,(rel,j) in bundles.items():
        md = read(os.path.join(rel,"findings.md"))
        old = supersedes_target(md)
        if not old or old not in bundles: continue
        orel, oj = bundles[old]
        omd = read(os.path.join(orel,"findings.md"))
        sess = (j["recordedBy"]["sessionId"] or "unknown")
        j["edges"] = provenance(omd, md, old, num, sess, NOW[:10])
        j["lineage"] = {"supersedes": old, "on": None}
        oj["lineage"] = {"supersededBy": num, "on": None}

    # Ownership is COMPUTED by scanning the session manifests, never stored on
    # the bundle -- state-as-data section 6.1. findings-manifest.md is
    # authoritative for who owns a reading, so deriving from it makes the two
    # sides unable to disagree. A bundle no live session lists is `unclaimed`.
    #
    # A CLOSED session's listing does not confer ownership: section 9 step 7
    # keeps a superseded bundle listed by the session that held it, and a
    # closed session releases what it still owned. Both are historical facts.
    live_owned = set()
    sbase0 = os.path.join(ROOT, "docs/sessions")
    for nm in sorted(os.listdir(sbase0)):
        dd = os.path.join(sbase0, nm)
        if not os.path.isdir(dd): continue
        if os.path.exists(os.path.join(dd, "final-summary.md")): continue   # closed
        fmx = read(os.path.join("docs/sessions", nm, "findings-manifest.md"))
        if not fmx: continue
        for c in rows(fmx, r'^\d{4}$'): live_owned.add(c[0])
    # `unclaimed` means LIVE WORK NOBODY HOLDS, not merely "no owner". The
    # legend's row 1 is "never assigned since creation, or released back to the
    # queue" -- and a bundle whose reading is finished is not in any queue. A
    # `resolved` or `withdrawn` bundle needs no owner and marking it unclaimed
    # would advertise finished work as available.
    #
    # This surfaced by running the derivation against the tree: six bundles
    # came out `unclaimed` over rows reading `resolved`. Section 9 step 3 says a
    # difference is an extraction bug or a fact that was wrong -- this was a
    # third thing, a rule that had never been stated precisely because a human
    # applying it by hand never needed it to be.
    for num,(rel,j) in bundles.items():
        if (j.get("lineage") or {}).get("supersededBy"): continue
        prog,_ = derive_progress(j["findings"])
        if prog in ("resolved","withdrawn"): continue
        if num not in live_owned:
            j["ownership"] = "unclaimed"

    for num,(rel,j) in sorted(bundles.items()):
        p=os.path.join(rel,"metadata.json")
        if not DRY: open(os.path.join(ROOT,p),"w").write(json.dumps(j,indent=2,ensure_ascii=False)+"\n")
        written.append((p, len(j["findings"]), len(j["decisions"]), len(j["edges"])))

    sess_written=[]
    sbase=os.path.join(ROOT,"docs/sessions")
    for name in sorted(os.listdir(sbase)):
        d=os.path.join(sbase,name)
        if not os.path.isdir(d) or not os.path.exists(os.path.join(d,"metadata.md")): continue
        j=session_json(name)
        p=os.path.join("docs/sessions",name,"metadata.json")
        if not DRY: open(os.path.join(ROOT,p),"w").write(json.dumps(j,indent=2,ensure_ascii=False)+"\n")
        sess_written.append((p,len(j["owners"]),len(j["ownedBundles"])))

    print(f"{len(written)} findings bundles, {len(sess_written)} session bundles"
          + (" (dry run, nothing written)" if DRY else ""))
    tf=sum(w[1] for w in written); td=sum(w[2] for w in written); te=sum(w[3] for w in written)
    print(f"  {tf} findings · {td} decisions · {te} provenance edges")
    for p,f,dd,e in written:
        if e: print(f"  edges: {p.split('/')[-2][:46]:48} {e}")

if __name__ == "__main__":
    main()
