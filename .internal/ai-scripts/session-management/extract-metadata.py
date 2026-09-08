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
    fields accumulate -- 0043 F6: a scalar cannot be widened back into a list."""
    fields={}
    seen=False
    for ln in md.split("\n"):
        if ln.startswith("# "): seen=True; continue
        if not seen: continue
        m = re.match(r'^\*\*([A-Z][^:*]*)[:*]', ln)
        if not m:
            if ln.strip()=="" : continue
            if not ln.startswith("**"): break
            continue
        name=m.group(1).strip()
        val=ln[m.end():].lstrip(": ").rstrip()
        val=re.sub(r'\s{2,}$','',val)
        fields.setdefault(name,[]).append(val.strip())
    return fields

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

    tag = None
    for f in sorted(os.listdir(os.path.join(ROOT,d))):
        if f.startswith("STATUS-"): tag = f[len("STATUS-"):]

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
            f["resolution"] = {"resolvedBy": [x.strip() for x in c[1].split(",") if x.strip()],
                               "whatWasDone": c[2],
                               "revision": unwrap(c[3]), "commit": unwrap(c[4])}

    contributions=[]
    for c in rows(fmd, r'^`?[a-z0-9-]+-\d{8}-\d{6}`?$'):
        if len(c)>=3: contributions.append({"session":unwrap(c[0]),"date":c[1],"contribution":c[2]})

    return {
      "schemaVersion": 1, "updatedAt": NOW,
      "number": num, "bundleName": name, "kind": kind, "subKind": sub,
      "subject": title(fmd),
      "recordedOn": (h.get("Recorded",[""])[0].split(",")[0] or None),
      "recordedOccasion": (",".join(h.get("Recorded",[""])[0].split(",")[1:]).strip() or None),
      "recordedBy": {"sessionBundle": None, "sessionId": unwrap(h.get("Session",[None])[0])},
      "severity": h.get("Severity",[None])[0],
      "feltAt": h.get("Felt at",[]),
      "scope": h.get("Scope",[None])[0],
      "read": h.get("Read",[]),
      "progress": None,
      "ownership": tag if tag in ("unclaimed","transferred") else None,
      "lineage": None,
      "declaredTag": tag,
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
    state = None
    for f in sorted(os.listdir(os.path.join(ROOT,d))):
        if f.startswith("STATE-"): state = f[len("STATE-"):]

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
            if len(c)==2 and c[0] not in ("What","From"): resources.append({"what":c[0],"path":unwrap(c[1])})

    owned=[]
    if fm:
        for c in rows(fm, r'^\d{4}$'):
            owned.append({"number": c[0], "notes": (c[-1] if len(c)>=7 else None)})

    return {
      "schemaVersion": 1, "updatedAt": NOW,
      "bundleName": name, "createdOn": git_first_date(d),
      "owners": owners, "transcript": transcript,
      "scratchPath": None, "resources": resources,
      "ownedBundles": owned, "contributions": [],
      "declaredState": state if state=="handoff" else None,
      "declaredTag": state,
      "indexNotes": None,
      "ended": {"on":None,"reason":None,"revisions":[],"commits":[],"disposals":[]} }

# ---------------------------------------------------------------------------
def main():
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
