#!/usr/bin/env python3
"""
check-metadata-completeness.py -- is the DATA complete against the MARKDOWN?

Every other checker answers whether a document is well formed. None answers
whether it is COMPLETE. That gap let 162 contaminated fields and 39 lost `Read:`
bullets sit in 47 files while verify-session-findings.sh reported 0 FAIL --
correctly, because the JSON was well formed. It was found by a person reading
the output.

"Completeness is not conformance" is a written rule. This is the thing that
enforces it.

CLASSIFICATION: .internal/ai-scripts/session-management/ helper. Not a bin/
entrypoint: `./bin/verify-session-findings.sh completeness` is the callsite, by
way of check-completeness.sh in this directory.

WHY THIS IS ITS OWN FILE, as of Revision 299
--------------------------------------------
It was the second half of `extract-metadata.py`, whose first half regenerated
every metadata.json by parsing the markdown. `0050` D3 retired that half and
separated this one, on three measurements: one run rewrote 66 of 66 records and
destroyed 740 recorded values, of which `plan-findings-work.sh stamp` restores
120 and 620 do not come back; `genus` was 54 of the 620, a field the parser was
written before and has never emitted, so a run reverted Revision 271's
migration; and `check-completeness.sh` exec'd that file on every routine
verification run, which put one argv token between the safe invocation and the
destructive one. `DRY` was `"--dry-run" in sys.argv`, so anything that was not
exactly `--dry-run` or `--check` ran live.

Splitting the file is what removes that distance. There is nothing in this one
that writes.

Deliberately NOT a second parser of the markdown. A second reader shares the
first one's blind spots -- the bug this was built to catch was a regex that
looked right. These are invariants a parser cannot satisfy by accident:
presentation cannot survive into a value, and a count in the document must equal
a length in the data.

Usage:
  ./bin/verify-session-findings.sh completeness

Exit codes:
  0  the data is complete against the markdown it came from
  1  at least one record is not
"""
import json, os, re, sys

# THREE levels up: this sits in .internal/ai-scripts/session-management/, so the
# repo root is three parents away. Moving a script between depths without
# changing this line is a failure this repository has already hit.
#
# It self-locates rather than asking git, which is the convention every other
# entrypoint here follows and is also a hazard removed: the file this was split
# out of ran `git rev-parse` to find the root, and git takes a lock to read. On
# a mounted connected folder that lock cannot be cleaned up, and what is left
# behind blocks the owner's next commit.
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))


def read(p):
    try:
        return open(os.path.join(ROOT, p)).read()
    except (IOError, OSError):
        return None


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
            # [FQT], not F: a member id carries its genus in its prefix --
            # F a finding, Q a question, T a task. Matching only F counted a
            # commission's members as zero against three in the data. 0039 F31.
            for pat, key in ((r'^\| *[FQT]\d+ *\|', "members"), (r'^\| *D\d+ *\|', "decisions")):
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

if __name__ == "__main__":
    raise SystemExit(check_completeness())
