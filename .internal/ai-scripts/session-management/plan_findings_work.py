#!/usr/bin/env python3
"""Allocation and inquiry over the findings graph.

Implements docs/architecture/allocation-and-inquiry.md sections 3, 4 and 5
against the metadata.json state defined in docs/architecture/state-as-data.md.
Reads only; every subcommand prints a proposal. The owner assigns.
"""
import json, io, os, sys, glob, itertools, datetime, argparse
from collections import Counter, defaultdict

# ---------------------------------------------------------------- 3. the graph
INERT = {"resolved", "withdrawn"}
HARD = {"blocks", "evidences", "co-decides", "contradicts", "duplicates"}
W = {"co-decides": 6, "contradicts": 6, "duplicates": 6, "blocks": 4, "evidences": 4,
     "constrains": 3, "generalises": 3, "successor": 3, "carried": 2,
     "shares-surface": 2, "relates-to": 1, "supersedes": 1}
WC = {"record": 1.0, "toolkit": 1.6, "evidence": 2.2}


def root():
    d = os.path.abspath(os.path.dirname(__file__))
    while d != "/" and not os.path.isdir(os.path.join(d, "docs")):
        d = os.path.dirname(d)
    return d


def write_category(scope):
    s = (scope or "").lower()
    if "artifact" in s or "evidence" in s or "volume" in s:
        return "evidence"
    if any(k in s for k in ("bin/", ".internal/", "instruction", "runbook",
                            ".github", "script", "template", "lint", "check")):
        return "toolkit"
    return "record"


def ladder(sts):
    if not sts:
        return "un-started"
    if all(s == "un-started" for s in sts):
        return "un-started"
    if all(s == "withdrawn" for s in sts):
        return "withdrawn"
    if all(s in INERT for s in sts) and "resolved" in sts:
        return "resolved"
    if "reopened" in sts and all(s in INERT for s in sts if s != "reopened"):
        return "reopened"
    return "analyzing"


class Graph(object):
    def __init__(self, r):
        self.root = r
        self.bundles, self.sessions, self.edges = {}, {}, []
        for f in glob.glob(os.path.join(r, "docs/*-findings/**/metadata.json"), recursive=True):
            d = json.load(io.open(f, encoding="utf-8"))
            d["_dir"] = os.path.relpath(os.path.dirname(f), r)
            d["_findings"] = d.get("findings") or []
            d["_progress"] = ladder([x.get("status") for x in d["_findings"]])
            d["_wc"] = write_category(d.get("scope"))
            self.bundles[d["number"]] = d
            for e in d.get("edges") or []:
                e["_home"] = d["number"]
                self.edges.append(e)
        for f in glob.glob(os.path.join(r, "docs/sessions/*/metadata.json")):
            d = json.load(io.open(f, encoding="utf-8"))
            d["_dir"] = os.path.relpath(os.path.dirname(f), r)
            self.sessions[d["bundleName"]] = d
        # blast radius: how many OTHER bundles name this one anywhere in their data
        blob = {n: json.dumps(b) for n, b in self.bundles.items()}
        for n, b in self.bundles.items():
            b["_blast"] = sum(1 for m, t in blob.items() if m != n and n in t)

    def owner_of(self, num):
        for name, s in self.sessions.items():
            for ob in s.get("ownedBundles") or []:
                if str(ob.get("number") or ob.get("bundle") or ob) [:4]== num:
                    return name
        return None

    def live_sessions(self):
        out = {}
        for name, s in self.sessions.items():
            # `ended` is always present as an object; `ended.on` is what says so.
            if (s.get("ended") or {}).get("on"):
                continue
            # a session that has handed off or closed takes no new work
            if s.get("declaredState") in ("handoff", "closed", "withdrawn"):
                continue
            owned = [self.bundles[str(ob.get("number"))[:4]]
                     for ob in (s.get("ownedBundles") or [])
                     if str(ob.get("number"))[:4] in self.bundles]
            open_f = sum(1 for b in owned for x in b["_findings"]
                         if x.get("status") not in INERT)
            s["_open"] = open_f
            s["_bundles"] = len(owned)
            out[name] = s
        return out

    def cost(self, b):
        live = [x for x in b["_findings"] if x.get("status") not in INERT]
        return round(len(live) * WC[b["_wc"]], 2)


# ------------------------------------------------------------- 4. the allocator
def holds(g, queue):
    h = {}
    for e in g.edges:
        if e.get("kind") not in HARD:
            continue
        fb, tb = str(e["from"]).split("/")[0], str(e["to"]).split("/")[0]
        if fb == tb or tb not in queue or fb in queue:
            continue
        src = g.bundles.get(fb)
        if src and src["_progress"] not in ("resolved", "withdrawn"):
            h.setdefault(tb, []).append(e)
    return h


DEFAULT_CAPACITY = 22.0     # cost units before a session is too long to add to
NEW_SESSION_SETUP = 3.0     # a new session is not free: bundle, prompt, cold read


def score(g, assign, sess, cap=DEFAULT_CAPACITY, w=(1.0, 1.5, 2.0, 1.0, 0.5, 4.0)):
    w_keep, w_pull, w_tree, w_split, w_load, w_over = w
    keep = split = pull = tree = 0.0
    for e in g.edges:
        fb, tb = str(e["from"]).split("/")[0], str(e["to"]).split("/")[0]
        k = e.get("kind")
        if fb in assign and tb in assign and fb != tb:
            if assign[fb] == assign[tb]:
                keep += W.get(k, 1)
            elif k == "shares-surface":
                split += W.get(k, 1)
        for x, y in ((fb, tb), (tb, fb)):
            if x in assign and y not in assign and y in g.bundles:
                o = g.owner_of(y)
                if o and assign[x] == o:
                    pull += W.get(k, 1)
    home = {}
    for n, s in sess.items():
        kinds = Counter(g.bundles[str(ob.get("number"))[:4]]["kind"]
                        for ob in (s.get("ownedBundles") or [])
                        if str(ob.get("number"))[:4] in g.bundles)
        home[n] = kinds.most_common(1)[0][0] if kinds else None
    for b, n in assign.items():
        if home.get(n) == g.bundles[b]["kind"]:
            tree += 1
    load = {n: sess[n].get("_open", 0) * 0.25 for n in sess}
    for b, n in assign.items():
        load[n] += g.cost(g.bundles[b])
    imb = max(load.values()) - min(load.values()) if load else 0
    # Overflow is superlinear: past capacity, one more bundle costs more than the
    # last. This is the term that makes a new session preferable to a long one.
    over = sum(((load[n] - cap) ** 2) / cap for n in load if load[n] > cap)
    setup = sum(NEW_SESSION_SETUP for n in sess if n.startswith("<new-")
                and any(v == n for v in assign.values()))
    return (w_keep * keep + w_pull * pull + w_tree * tree
            - w_split * split - w_load * imb - w_over * over - setup), \
        dict(keep=keep, pull=pull, tree=tree, split=split, imb=round(imb, 2),
             over=round(over, 2), load=load, cap=cap)


def select(g, only_kind=None, skip_kind=None, only=None, skip=None):
    q = {n: b for n, b in g.bundles.items() if b.get("ownership") == "unclaimed"}
    if only:
        q = {n: b for n, b in q.items() if n in only}
    if skip:
        q = {n: b for n, b in q.items() if n not in skip}
    if only_kind:
        q = {n: b for n, b in q.items() if b.get("kind") in only_kind}
    if skip_kind:
        q = {n: b for n, b in q.items() if b.get("kind") not in skip_kind}
    return q


def allocate(g, new_sessions=0, cap=DEFAULT_CAPACITY, queue=None):
    queue = queue if queue is not None else select(g)
    held = holds(g, queue)
    free = sorted(n for n in queue if n not in held)
    sess = dict(g.live_sessions())
    for i in range(new_sessions):
        sess["<new-%d>" % (i + 1)] = {"_open": 0, "_bundles": 0, "ownedBundles": []}
    names = sorted(sess)
    if not names:
        return None
    best = None
    if len(names) ** len(free) <= 400000:
        for combo in itertools.product(names, repeat=len(free)):
            a = dict(zip(free, combo))
            s = score(g, a, sess, cap=cap)
            if best is None or s[0] > best[0][0]:
                best = (s, a)
    else:
        # Above the exact-search ceiling: longest-processing-time first, then
        # local search. Greedy alone packs badly -- it fills the session that
        # scores best for one bundle and leaves the rest over capacity.
        a = {}
        for b in sorted(free, key=lambda x: -g.cost(g.bundles[x])):
            cand = [(score(g, dict(a, **{b: n}), sess, cap=cap)[0], n) for n in names]
            a[b] = max(cand)[1]
        cur = score(g, a, sess, cap=cap)[0]
        for _ in range(200):                # move one bundle at a time, best-first
            gain, mv = 0.0, None
            for b in free:
                for n in names:
                    if a[b] == n:
                        continue
                    t = dict(a)
                    t[b] = n
                    d = score(g, t, sess, cap=cap)[0] - cur
                    if d > gain:
                        gain, mv = d, (b, n)
            if not mv:
                break
            a[mv[0]] = mv[1]
            cur += gain
        best = (score(g, a, sess, cap=cap), a)
    return dict(queue=queue, held=held, sess=sess, assign=best[1],
                score=best[0][0], parts=best[0][1])


# ------------------------------------------------------------ 5. the interviewer
def frontier(g):
    out = []
    blocked = set()
    for e in g.edges:
        if e.get("kind") in ("blocks", "evidences"):
            src = g.bundles.get(str(e["from"]).split("/")[0])
            if src and src["_progress"] not in ("resolved", "withdrawn"):
                blocked.add(str(e["to"]))
    for n, b in g.bundles.items():
        owned = b.get("ownership") is None
        for x in b["_findings"]:
            fid = "%s/%s" % (n, x["id"])
            if x.get("status") != "framing":
                continue
            out.append(dict(id=fid, b=n, f=x["id"], stmt=x.get("statement", ""),
                            owned=owned, blocked=fid in blocked, bundle=b,
                            updated=x.get("updatedAt")))
    return out


def rank(g, fr):
    for r in fr:
        b = r["bundle"]
        sib = [x for x in b["_findings"] if x.get("status") == "framing"]
        dec = b.get("decisions") or []
        cited = set()
        for d in dec:
            for fid in (d.get("findings") or []):
                cited.add(fid)
        r["undecided"] = r["f"] not in cited
        r["gate"] = 1.0 if (r["undecided"] and len(dec) > 0
                            and all(x["id"] in cited or x["id"] == r["f"]
                                    for x in b["_findings"])) else (0.5 if r["undecided"] else 0.0)
        r["wc"] = b["_wc"]
        r["gain"] = r["gate"] * len(sib) * 2 + b["_blast"] * 0.5 + (len(sib) - 1) * 0.3
        r["score"] = 0 if r["blocked"] else r["gain"] + WC[r["wc"]]
    return sorted(fr, key=lambda x: -x["score"])


# ---------------------------------------------- 5a. capacity, derived from rework
def quality(g):
    """Per session: how much it held, and how much of what it decided came back.

    Rework signals, all already recorded by the schema: a decision whose Outcome
    is rejected/refined/superseded, a finding that went reopened, a bundle that
    was superseded. Nothing new is captured for this.
    """
    rows = []
    for name, sess in g.sessions.items():
        owned = [g.bundles[str(ob.get("number"))[:4]]
                 for ob in (sess.get("ownedBundles") or [])
                 if str(ob.get("number"))[:4] in g.bundles]
        if not owned:
            continue
        load = sum(g.cost(b) for b in owned)
        nf = sum(len(b["_findings"]) for b in owned)
        dec = redone = 0
        for b in owned:
            for d in (b.get("decisions") or []):
                dec += 1
                o = (d.get("outcome") or "")
                if o and o != "accepted":
                    redone += 1
            for x in b["_findings"]:
                if x.get("status") == "reopened" or x.get("reopened"):
                    redone += 1
            if (b.get("lineage") or {}).get("supersededBy"):
                redone += 1
        rows.append(dict(name=name, bundles=len(owned), findings=nf,
                         load=round(load, 1), decisions=dec, rework=redone,
                         rate=(redone / float(dec) if dec else 0.0)))
    return sorted(rows, key=lambda r: r["load"])


def derive_capacity(g, target=0.25):
    """The largest observed load whose rework rate is still under `target`.

    Deliberately conservative: it returns the largest CLEAN session's load, not
    a fitted curve, because seven sessions is an argument and not a sample.
    """
    rows = [r for r in quality(g) if r["decisions"] >= 2]
    clean = [r for r in rows if r["rate"] <= target]
    if not clean:
        return None, rows
    return max(r["load"] for r in clean), rows


# ------------------------------------------------------------------- reporting
def stamp():
    return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")


def cmd_graph(g, a):
    q = [b for b in g.bundles.values() if b.get("ownership") == "unclaimed"]
    print("GRAPH  %d bundles  %d findings  %d edges  %d live sessions"
          % (len(g.bundles), sum(len(b["_findings"]) for b in g.bundles.values()),
             len(g.edges), len(g.live_sessions())))
    print("  edge kinds: %s" % dict(Counter(e.get("kind") for e in g.edges)))
    print("  unclaimed:  %d bundles, %d findings, %.1f cost units"
          % (len(q), sum(len(b["_findings"]) for b in q), sum(g.cost(b) for b in q)))
    drift = [(b["number"], x["id"], x["status"]) for b in q
             for x in b["_findings"] if x.get("status") != "un-started"]
    if drift:
        print("  ** %d findings are live inside unclaimed bundles (0047 F1):" % len(drift))
        for n, f, s in drift[:8]:
            print("       %s/%s is `%s`" % (n, f, s))
        if len(drift) > 8:
            print("       ... and %d more" % (len(drift) - 8))


def split_arg(v):
    return [x.strip() for x in v.split(",") if x.strip()] if v else None


def cmd_allocate(g, a):
    q = select(g, only_kind=split_arg(a.only_kind), skip_kind=split_arg(a.exclude_kind),
               only=split_arg(a.only), skip=split_arg(a.exclude))
    excluded = len(select(g)) - len(q)
    cap = a.capacity
    if cap is None:
        cap, rows = derive_capacity(g)
        if cap is None:
            cap = DEFAULT_CAPACITY
            print("CAPACITY  no session yet has 2+ decisions and a clean record; "
                  "falling back to the default %.0f\n" % cap)
        else:
            print("CAPACITY  %.1f cost units, derived: the largest load any session "
                  "carried while keeping its rework rate at or under 25%%.\n"
                  "          Seven sessions is an argument, not a sample -- "
                  "run `capacity` to see the rows.\n" % cap)
    if excluded:
        print("FILTERED  %d of %d unclaimed bundles excluded by the selection\n"
              % (excluded, len(select(g))))
    if not q:
        print("Nothing selected. Widen the filter.")
        return
    if a.new_sessions >= 0:
        r = allocate(g, new_sessions=a.new_sessions, cap=cap, queue=q)
    else:                                   # --new-sessions -1 : size it for me
        n = 0
        while True:
            r = allocate(g, new_sessions=n, cap=cap, queue=q)
            if not r:
                break
            if all(v <= cap for v in r["parts"]["load"].values()) or n >= 8:
                break
            n += 1
        used = len(set(v for v in r["assign"].values() if v.startswith("<new-")))
        print("AUTO-SIZED  %d new session(s) proposed; %d allowed before the search "
              "stopped. Capacity %.1f cost units.\n" % (used, n, cap))
    if not r:
        print("no live sessions and no new ones requested; pass --new-sessions N")
        return
    print("QUEUE  %d bundles, %d findings, %.1f cost units"
          % (len(r["queue"]), sum(len(b["_findings"]) for b in r["queue"].values()),
             sum(g.cost(b) for b in r["queue"].values())))
    stranded = 0
    for n, es in sorted(r["held"].items()):
        ready = len(r["queue"][n]["_findings"])
        stranded += ready
        print("  HOLD %s (%d ready) <- %s from %s" % (n, ready, es[0]["kind"], es[0]["from"]))
    print("  held %d, held-back ready findings %d" % (len(r["held"]), stranded))
    print("\nPROPOSAL  score %.2f  keep %.0f pull %.0f tree %.0f split %.0f imbalance %.2f"
          % (r["score"], r["parts"]["keep"], r["parts"]["pull"], r["parts"]["tree"],
             r["parts"]["split"], r["parts"]["imb"]))
    over = [n for n, v in r["parts"]["load"].items() if v > r["parts"]["cap"]]
    if over:
        print("  OVER CAPACITY (%.0f): %s" % (r["parts"]["cap"], ", ".join(sorted(over))))
    by = defaultdict(list)
    for b, n in r["assign"].items():
        by[n].append(b)
    for n in sorted(by):
        s = r["sess"][n]
        print("  %-48s %s" % (n, ", ".join(sorted(by[n]))))
        print("  %-48s   holds %d open, load %.2f"
              % ("", s.get("_open", 0), r["parts"]["load"][n]))
    newnames = [n for n in by if n.startswith("<new-")]
    if newnames:
        print("\nNEW SESSION BUNDLES TO CREATE")
        st = stamp()
        for n in sorted(newnames):
            bs = sorted(by[n])
            kinds = Counter(g.bundles[b]["kind"] for b in bs)
            # the lowest bundle number keeps two clusters of one kind apart
            title = "%s-%s" % (kinds.most_common(1)[0][0], bs[0])
            print("  docs/sessions/%s-%s/" % (title, st))
            print("      %d bundles, %d findings, load %.1f: %s"
                  % (len(bs), sum(len(g.bundles[b]["_findings"]) for b in bs),
                     r["parts"]["load"][n], ", ".join(bs)))
    if newnames:
        print("\n  DRY RUN -- nothing here exists yet. For each new bundle:")
        for n in sorted(newnames):
            bs = sorted(by[n])
            # clone when the cluster pulls hard on one existing session's work;
            # create when it does not, because a clone inherits customisations
            pulls = Counter()
            for e in g.edges:
                fb, tb = str(e["from"]).split("/")[0], str(e["to"]).split("/")[0]
                for x, y in ((fb, tb), (tb, fb)):
                    if x in bs and y in g.bundles and y not in r["assign"]:
                        o = g.owner_of(y)
                        if o:
                            pulls[o] += W.get(e.get("kind"), 1)
            kinds = Counter(g.bundles[b]["kind"] for b in bs)
            title = "%s-%s" % (kinds.most_common(1)[0][0], bs[0])
            if pulls:
                src, wt = pulls.most_common(1)[0]
                print("    CLONE  %s-<stamp>" % title)
                print("           from %s (pull %d) -- it inherits that session's"
                      % (src, wt))
                print("           prompt and customisations, which is what a clone is for")
            else:
                print("    CREATE %s-<stamp>" % title)
                print("           no edge ties it to an existing session's work,"
                      " so a clone would inherit context it does not need")
            print("           bundles: %s" % ", ".join(bs))
        print("\n  The owner creates these, assigns the bundles, and commits and"
              " pushes.\n  Nothing above has been written. This tool never assigns.")

    print("\n  edges kept inside one session:")
    kept = 0
    for e in g.edges:
        fb, tb = str(e["from"]).split("/")[0], str(e["to"]).split("/")[0]
        if fb != tb and fb in r["assign"] and tb in r["assign"] \
           and r["assign"][fb] == r["assign"][tb]:
            print("    %-12s %s -> %s" % (e["kind"], e["from"], e["to"]))
            kept += 1
    if not kept:
        print("    none -- no edge joins two queued bundles")


def cmd_ask(g, a):
    fr = frontier(g)
    ranked = rank(g, fr)
    askable = [r for r in ranked if r["owned"] and not r["blocked"]]
    print("FRONTIER  %d findings in the tree, %d `framing`, %d askable"
          % (sum(len(b["_findings"]) for b in g.bundles.values()), len(fr), len(askable)))
    print("  dropped: %d not `framing`, %d in unclaimed bundles, %d blocked"
          % (sum(len(b["_findings"]) for b in g.bundles.values()) - len(fr),
             len([r for r in fr if not r["owned"]]),
             len([r for r in fr if r["blocked"]])))
    if not askable:
        print("\n  Nothing to ask. Allocate first -- only an owned, read bundle is askable.")
        return
    print("\nNEXT QUESTION")
    top = askable[0]
    print("  %s  score %.2f (gate %.1f, blast %d, %s)"
          % (top["id"], top["score"], top["gate"], top["bundle"]["_blast"], top["wc"]))
    print("  %s" % top["stmt"])
    print("\n  why this one, against the runners-up:")
    for r in askable[1:4]:
        print("    %-10s %.2f  %s" % (r["id"], r["score"], r["stmt"][:64]))
    if len(askable) > 1 and abs(askable[0]["score"] - askable[1]["score"]) < 0.01:
        print("\n  ** TIE -- the ranker did not settle this. Say so rather than presenting an order.")


def cmd_capacity(g, a):
    cap, rows = derive_capacity(g)
    print("SESSION SIZE AGAINST REWORK  -- every column is already recorded\n")
    print("  %-46s %6s %5s %5s %5s %6s" % ("session", "load", "bnd", "fnd", "dec", "rework"))
    for r in rows:
        print("  %-46s %6.1f %5d %5d %5d %5d (%.0f%%)"
              % (r["name"][:46], r["load"], r["bundles"], r["findings"],
                 r["decisions"], r["rework"], 100 * r["rate"]))
    print()
    if cap is None:
        print("  No session yet has 2+ decisions and a rework rate at or under 25%.")
        print("  There is nothing to derive a limit from; the default stands.")
    else:
        print("  DERIVED CAPACITY %.1f cost units -- the largest load carried while"
              % cap)
        print("  rework stayed at or under 25 per cent.")
        print()
        print("  READ THE COLUMN, NOT THE NUMBER. Rework FALLS as load rises here:")
        print("  the two largest sessions are the two cleanest. On this evidence")
        print("  decision quality does not degrade with size, and a capacity that")
        print("  claims otherwise is a preference wearing a measurement.")
        print()
        print("  What that means: THE DATUM FOR THE REAL LIMIT IS NOT RECORDED.")
        print("  A session gets 'too long' in turns and context, and neither is in")
        print("  any record here. Until a session logs its own length, a capacity")
        print("  is a judgement -- so set it with --capacity and say it was chosen.")
    print("\n  Read this as an argument, not a measurement. %d sessions with any"
          " decisions\n  at all is too few to fit a curve to, and the rework signals"
          " count what\n  came back, not what should have." % len(rows))


def main():
    p = argparse.ArgumentParser(prog="plan-findings-work")
    p.add_argument("command", choices=["graph", "allocate", "ask", "capacity"])
    p.add_argument("--new-sessions", type=int, default=0,
                   help="how many new session bundles to allow; -1 sizes it")
    p.add_argument("--capacity", type=float, default=None,
                   help="cost units a session may hold; omitted, it is derived")
    p.add_argument("--only-kind", help="allocate only these kinds, comma separated")
    p.add_argument("--exclude-kind", help="never allocate these kinds")
    p.add_argument("--only", help="allocate only these bundle numbers")
    p.add_argument("--exclude", help="never allocate these bundle numbers")
    a = p.parse_args()
    g = Graph(root())
    {"graph": cmd_graph, "allocate": cmd_allocate, "ask": cmd_ask,
     "capacity": cmd_capacity}[a.command](g, a)


if __name__ == "__main__":
    main()
