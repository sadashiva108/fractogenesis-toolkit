#!/usr/bin/env python3
"""Which documents may have gone stale, and which are certainly current.

Every edge in doc-currency.json is ASSERTED. Nothing is inferred from
similarity, filename or proximity -- an inferred edge is how a checker tells one
project's game engine that another project's intake docs need updating, and how
a real drift hides in a page of noise. An entry nobody wrote does not exist, and
that is the correct failure: it is visible in `--coverage`.
"""
import json, io, os, sys, hashlib, datetime, argparse

CONFIG = "doc-currency.json"
TIERS = ("critical", "normal")
REVIEW = ("manual", "auto")


def root():
    d = os.path.abspath(os.path.dirname(__file__))
    while d != "/" and not os.path.isdir(os.path.join(d, "docs")):
        d = os.path.dirname(d)
    return d


def cfg_path(r):
    return os.path.join(r, ".internal", "ai-scripts", "session-management", CONFIG)


def load(r):
    with io.open(cfg_path(r), encoding="utf-8") as fh:
        return json.load(fh)


def save(r, d):
    p = cfg_path(r)
    with io.open(p + ".tmp", "w", encoding="utf-8") as fh:
        fh.write(json.dumps(d, indent=2) + "\n")
    os.replace(p + ".tmp", p)


def digest(r, paths):
    """One digest over every source in a watch. Missing files count as content."""
    h = hashlib.sha256()
    for p in sorted(paths):
        full = os.path.join(r, p)
        h.update(p.encode("utf-8"))
        if os.path.isfile(full):
            with io.open(full, "rb") as fh:
                h.update(fh.read())
        else:
            h.update(b"<absent>")
    return h.hexdigest()[:16]


def evaluate(r, d):
    out = []
    for w in d["watches"]:
        cur = digest(r, w["sources"])
        missing = [p for p in w["sources"] + w["dependents"]
                   if not os.path.exists(os.path.join(r, p))]
        if w.get("sourceDigest") is None:
            state = "UNCONFIRMED"
        elif cur != w["sourceDigest"]:
            state = "DRIFTED"
        else:
            state = "current"
        out.append(dict(w=w, state=state, cur=cur, missing=missing))
    return out


def cmd_check(r, d, a):
    rows = evaluate(r, d)
    bad = [x for x in rows if x["state"] != "current"]
    print("DOC CURRENCY  %d watches, %d drifted, %d never confirmed\n"
          % (len(rows), len([x for x in rows if x["state"] == "DRIFTED"]),
             len([x for x in rows if x["state"] == "UNCONFIRMED"])))
    for x in sorted(rows, key=lambda y: (y["w"].get("tier") != "critical", y["w"]["id"])):
        w = x["w"]
        if x["state"] == "current" and not a.all:
            continue
        mark = "**" if w.get("tier") == "critical" else "  "
        print("%s %-18s %-11s %s" % (mark, w["id"], x["state"], w.get("why", "")))
        if x["state"] != "current":
            for p in w["dependents"]:
                print("       review: %s" % p)
            if w.get("review") == "manual":
                print("       MANUAL -- this one is not safe to confirm without reading it.")
        if x["missing"]:
            print("       MISSING: %s" % ", ".join(x["missing"]))
        print()
    if not bad:
        print("  Every watched document is current against its sources.")
    else:
        print("  Confirm one after reviewing it:")
        print("    ./bin/verify-doc-currency.sh --confirm <id>")
    return 1 if [x for x in bad if x["w"].get("tier") == "critical"] else 0


def cmd_coverage(r, d, a):
    """What is NOT watched. An unasserted edge is invisible, so name the gap."""
    watched = set()
    for w in d["watches"]:
        watched.update(w["sources"])
        watched.update(w["dependents"])
    roots = (".claude", ".github", "docs/architecture", "docs/ledgers", "docs/ideas")
    unwatched = []
    for base in roots:
        for dp, _, fns in os.walk(os.path.join(r, base)):
            for fn in fns:
                rel = os.path.relpath(os.path.join(dp, fn), r)
                if rel.endswith((".md", ".json", ".sh", ".py")) and rel not in watched:
                    unwatched.append(rel)
    for f in ("docs/legend.md", "README.md", "APPLY-MANIFEST.md", ".envrc"):
        if os.path.exists(os.path.join(r, f)) and f not in watched:
            unwatched.append(f)
    print("COVERAGE  %d files watched, %d not\n" % (len(watched), len(unwatched)))
    for p in sorted(unwatched):
        print("  unwatched  %s" % p)
    print("\n  An unwatched file is not protected. Add it to a watch, or accept it"
          "\n  deliberately -- the point is that the gap is visible rather than assumed.")
    return 0


def cmd_confirm(r, d, a):
    hit = [w for w in d["watches"] if w["id"] == a.confirm]
    if not hit:
        print("no watch with id %r" % a.confirm)
        return 2
    w = hit[0]
    w["sourceDigest"] = digest(r, w["sources"])
    w["confirmedAt"] = datetime.datetime.now().strftime("%Y-%m-%d")
    save(r, d)
    print("confirmed %s at %s (%s)" % (w["id"], w["confirmedAt"], w["sourceDigest"]))
    print("  This records that a person read %d dependent(s) and found them current."
          % len(w["dependents"]))
    return 0


def main():
    p = argparse.ArgumentParser(prog="verify-doc-currency")
    p.add_argument("--confirm", metavar="ID")
    p.add_argument("--coverage", action="store_true")
    p.add_argument("--all", action="store_true", help="show watches that are current too")
    a = p.parse_args()
    r = root()
    d = load(r)
    if a.confirm:
        sys.exit(cmd_confirm(r, d, a))
    if a.coverage:
        sys.exit(cmd_coverage(r, d, a))
    sys.exit(cmd_check(r, d, a))


if __name__ == "__main__":
    main()
