#!/usr/bin/env python3
"""Retrofit every findings bundle onto the genus schema -- Revision 270.

Two changes, one pass, idempotent:

  * `genus` is added immediately before `kind`, defaulting to `findings`. It
    says what SORT of bundle this is. `kind` is untouched and still means the
    subject domain.
  * `findings[]` becomes `members[]`, on the bundle and in every decision's
    citation array, because a commission holds questions and an actionable
    bundle holds tasks: an array named for one species cannot name the genus.

The shape -- `reasoning` or `actionable` -- is DERIVED from the genus and is
never written here, because nothing derivable is stored.

Run it twice and the second run reports zero. That is the point: after a rebase,
re-run rather than redo by hand.

    migrate-genus-and-members.py --check    say what would change, write nothing
    migrate-genus-and-members.py            do it
    migrate-genus-and-members.py --verify   derive every bundle and print a
                                            fingerprint, for before/after diffing

The fingerprint is the round trip `state-as-data.md` section 9 step 2 asks for,
narrowed to a field: standing, progress, ownership, every member id with its
status, and every decision's outcome and citations. Take it before, take it
after, and `diff`. A migration that changes a single derived value is a
migration that lost something.
"""

import argparse
import collections
import glob
import io
import json
import os
import sys

PATTERN = "docs/*-findings/**/metadata.json"
DEFAULT_GENUS = "findings"


def repo_root():
    """Self-locate: walk up from this file until APPLY-MANIFEST.md is beside us."""
    d = os.path.dirname(os.path.abspath(__file__))
    while d != "/":
        if os.path.exists(os.path.join(d, "APPLY-MANIFEST.md")):
            return d
        d = os.path.dirname(d)
    sys.stderr.write("cannot locate the repository root\n")
    raise SystemExit(2)


def bundle_files(root):
    return sorted(glob.glob(os.path.join(root, PATTERN), recursive=True))


def load(path):
    with io.open(path, encoding="utf-8") as fh:
        return json.load(fh, object_pairs_hook=collections.OrderedDict)


def migrate(d):
    """Return (new_document, [what changed]). Key order is preserved."""
    notes = []
    out = collections.OrderedDict()
    for k, v in d.items():
        if k == "genus":
            continue                      # re-inserted in position below
        if k == "kind":
            if "genus" not in d:
                notes.append("genus added")
            out["genus"] = d.get("genus") or DEFAULT_GENUS
            out["kind"] = v
        elif k == "findings":
            notes.append("findings[] -> members[]")
            out["members"] = v
        elif k == "decisions":
            decs = []
            for dec in v:
                nd = collections.OrderedDict()
                for dk, dv in dec.items():
                    if dk == "findings":
                        nd["members"] = dv
                        notes.append("%s citations -> members" % dec.get("id"))
                    else:
                        nd[dk] = dv
                decs.append(nd)
            out["decisions"] = decs
        else:
            out[k] = v
    if "genus" not in out:                 # a document with no `kind` at all
        out["genus"] = d.get("genus") or DEFAULT_GENUS
        notes.append("genus added (no kind field)")
    return out, notes


def fingerprint(root):
    rows = []
    for f in bundle_files(root):
        d = load(f)
        items = d.get("members") or d.get("findings") or []
        rows.append("%s|%s|%s|%s|%d|%s" % (
            d.get("number"), d.get("standing"), d.get("progress"),
            d.get("ownership"), len(items),
            ",".join("%s:%s" % (x.get("id"), x.get("status")) for x in items)))
        for dec in (d.get("decisions") or []):
            cites = dec.get("members") or dec.get("findings") or []
            rows.append("%s|DEC|%s|%s|%s" % (
                d.get("number"), dec.get("id"), dec.get("outcome"), ",".join(cites)))
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true",
                    help="report what would change and write nothing")
    ap.add_argument("--verify", action="store_true",
                    help="print the derivation fingerprint and exit")
    ap.add_argument("--root", default=None, help="repository root (default: self-located)")
    a = ap.parse_args()
    root = a.root or repo_root()

    if a.verify:
        print("\n".join(fingerprint(root)))
        return 0

    files = bundle_files(root)
    if not files:
        sys.stderr.write("no bundle metadata.json under %s\n" % PATTERN)
        return 2

    touched, clean = [], 0
    for f in files:
        d = load(f)
        new, notes = migrate(d)
        if not notes:
            clean += 1
            continue
        touched.append((os.path.relpath(f, root), notes))
        if not a.check:
            tmp = f + ".tmp"
            with io.open(tmp, "w", encoding="utf-8") as fh:
                fh.write(json.dumps(new, indent=2) + "\n")
            os.replace(tmp, f)

    verb = "would migrate" if a.check else "migrated"
    print("MIGRATE  %s %d of %d bundle(s); %d already conformant"
          % (verb, len(touched), len(files), clean))
    for name, notes in touched[:8]:
        print("  %-64s %s" % (name[:64], "; ".join(sorted(set(notes)))[:60]))
    if len(touched) > 8:
        print("  ... and %d more" % (len(touched) - 8))
    if not touched:
        print("\n  Nothing to do. Run it again after a rebase; it stays quiet.")
    else:
        print("\n  Take --verify before and after and diff them. A derived value\n"
              "  that moved is a migration that lost something.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
