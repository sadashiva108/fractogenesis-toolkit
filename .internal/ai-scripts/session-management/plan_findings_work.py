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


def derivation_table(sts):
    """Finding STATUSES in, bundle STANDING out. A translation, not an identity.

    The two vocabularies share no word as of Revision 233, which is what makes a
    bare value self-locating: `framing` is a finding, `analyzing` is a bundle.
    `state-as-data.md` 4.4 always called this "a bridge between two
    vocabularies"; until now four rows of it were identity and read as one set.
    """
    if not sts:
        return "untouched"
    if all(s == "un-started" for s in sts):
        return "untouched"
    if all(s == "withdrawn" for s in sts):
        return "retired"
    if all(s in INERT for s in sts) and "resolved" in sts:
        return "answered"
    if "reopened" in sts and all(s in INERT for s in sts if s != "reopened"):
        return "revisited"
    return "analyzing"


class Graph(object):
    def __init__(self, r):
        self.root = r
        self.bundles, self.sessions, self.edges = {}, {}, []
        for f in glob.glob(os.path.join(r, "docs/*-findings/**/metadata.json"), recursive=True):
            with io.open(f, encoding="utf-8") as fh:
                d = json.load(fh)
            d["_dir"] = os.path.relpath(os.path.dirname(f), r)
            d["_members"] = d.get("members") or []
            d["_progress"] = derivation_table([x.get("status") for x in d["_members"]])
            d["_wc"] = write_category(d.get("scope"))
            self.bundles[d["number"]] = d
            for e in d.get("edges") or []:
                e["_home"] = d["number"]
                self.edges.append(e)
        for f in glob.glob(os.path.join(r, "docs/sessions/*/metadata.json")):
            with io.open(f, encoding="utf-8") as fh:
                d = json.load(fh)
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
            if s.get("declaredState") in ("handoff", "closed", "dissolved"):
                continue
            owned = [self.bundles[str(ob.get("number"))[:4]]
                     for ob in (s.get("ownedBundles") or [])
                     if str(ob.get("number"))[:4] in self.bundles]
            open_f = sum(1 for b in owned for x in b["_members"]
                         if x.get("status") not in INERT)
            s["_open"] = open_f
            s["_bundles"] = len(owned)
            out[name] = s
        return out

    def cost(self, b):
        live = [x for x in b["_members"] if x.get("status") not in INERT]
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


# A CHOSEN number, not a measured one. `0048` records why: a session's length is
# recorded nowhere, and the only proxy available (rework against load) inverts.
# Every report that prints a capacity says which kind it is.
DEFAULT_CAPACITY = 20.0
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


def allocate(g, new_sessions=0, cap=DEFAULT_CAPACITY, queue=None, only_new=False):
    queue = queue if queue is not None else select(g)
    held = holds(g, queue)
    free = sorted(n for n in queue if n not in held)
    sess = {} if only_new else dict(g.live_sessions())
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
        for x in b["_members"]:
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
        sib = [x for x in b["_members"] if x.get("status") == "framing"]
        dec = b.get("decisions") or []
        cited = set()
        for d in dec:
            for fid in (d.get("members") or []):
                cited.add(fid)
        r["undecided"] = r["f"] not in cited
        r["gate"] = 1.0 if (r["undecided"] and len(dec) > 0
                            and all(x["id"] in cited or x["id"] == r["f"]
                                    for x in b["_members"])) else (0.5 if r["undecided"] else 0.0)
        r["wc"] = b["_wc"]
        r["gain"] = r["gate"] * len(sib) * 2 + b["_blast"] * 0.5 + (len(sib) - 1) * 0.3
        r["score"] = 0 if r["blocked"] else r["gain"] + WC[r["wc"]]
    return sorted(fr, key=lambda x: -x["score"])


# ------------------------------------------- derived state, written and checked
#
# `state-as-data.md` 4.4 said progress was derived and NEVER STORED. The owner
# reversed that on 2026-09-08: a reader should not have to run a derivation table to learn
# a bundle's status. That reintroduces the risk `0043` F2 is about -- a derived
# value written down is a second copy that can drift -- so the legend's condition
# applies: a copy is permitted "where a check fails when it drifts". Both fields
# are stamped by `stamp` and compared by `check`. Neither is authored by hand.

def bundle_standing(b):
    """Where this bundle stands. NOT `status` -- that word belongs to a finding.

    Standing is progress with ownership and lineage put back in, which is why it
    has two values progress does not: `assigned` where progress says `untouched`
    and somebody owns it, and the three declared values.

    Three vocabularies, three words: a finding has a **status**, a bundle has a
    **standing**, a session has a **state**. They were two words for three sets
    until Revision 233, and the two that shared one also share four of their
    values -- `un-started`, `resolved`, `reopened`, `withdrawn` -- so a value
    could not say which set it came from and a bundle file carried `status` at
    two nesting levels meaning two different things.

    Ownership and lineage outrank progress because they are not progress at all
    -- an unclaimed bundle is closed to everyone whatever its findings say, and a
    superseded reading is no longer authoritative whatever it concluded.
    """
    if (b.get("lineage") or {}).get("supersededBy"):
        return "superseded"
    if b.get("ownership"):
        return b["ownership"]
    p = bundle_progress(b)
    # Owned, and nobody has written to a finding yet. `untouched` is true of the
    # reading; `assigned` is the same fact with the owner put back in, and it is
    # the one a reader scanning an index wants. A bundle nobody owns never
    # reaches here -- it returned `unclaimed` above.
    if p == "untouched":
        return "assigned"
    return p


def bundle_progress(b):
    """The pure derivation over the finding rows, with nothing layered on it."""
    return derivation_table([x.get("status") for x in (b.get("members") or [])])


def bundle_is_terminal(b):
    return (bundle_standing(b) in ("answered", "retired", "superseded"))


def session_state(g, s):
    """available, active, closed, handoff or dissolved -- docs/legend.md.

    `declaredState` stays: it is what the OWNER declared, and a handoff or a
    withdrawal cannot be derived from what a session holds. `state` is the
    effective value, which is the declaration where there is one and the
    derivation where there is not.
    """
    if s.get("declaredState"):
        return s["declaredState"]
    owned = [g.bundles[str(ob.get("number"))[:4]]
             for ob in (s.get("ownedBundles") or [])
             if str(ob.get("number"))[:4] in g.bundles]
    if (s.get("ended") or {}).get("on"):
        return "closed"
    if not owned:
        return "available"
    return "closed" if all(bundle_is_terminal(b) for b in owned) else "active"


def stamp_derived(g, write=True):
    """Write status/progress onto every bundle and state onto every session."""
    changed = []
    for n, b in sorted(g.bundles.items()):
        want = {"standing": bundle_standing(b), "progress": bundle_progress(b)}
        if any(b.get(k) != v for k, v in want.items()):
            changed.append(("bundle", n, dict(want)))
            if write:
                _rewrite(os.path.join(g.root, b["_dir"], "metadata.json"), want)
    for name, s in sorted(g.sessions.items()):
        want = {"state": session_state(g, s)}
        if s.get("state") != want["state"]:
            changed.append(("session", name, dict(want)))
            if write:
                _rewrite(os.path.join(g.root, s["_dir"], "metadata.json"), want)
    return changed


def _rewrite(path, fields):
    """Set fields in place, preserving key order and adding new keys after
    the field they belong beside."""
    with io.open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    for k, v in fields.items():
        d[k] = v
    # keep `status` next to `progress`/`ownership` rather than appended at the end
    order = []
    for k in d:
        if k == "progress" and "standing" in d and "standing" not in order:
            order.append("standing")
        if k != "standing":
            order.append(k)
    out = dict((k, d[k]) for k in order if k in d)
    with io.open(path + ".tmp", "w", encoding="utf-8") as fh:
        fh.write(json.dumps(out, indent=2) + "\n")
    os.replace(path + ".tmp", path)


# ------------------------------------------------------- conformance detectors
FINDING_STATUSES = ("un-started", "framing", "decided", "resolved",
                    "reopened", "withdrawn")
# Two derived fields, two vocabularies that overlap where they mean the same
# thing. `untouched` belongs to progress alone -- it is true whoever owns the
# bundle. `assigned` belongs to standing alone -- it is an ownership statement,
# and a bundle nobody owns reads `unclaimed` instead.
BUNDLE_PROGRESS = ("untouched", "analyzing", "answered", "revisited", "retired")
BUNDLE_STANDINGS = ("assigned", "analyzing", "answered", "revisited", "retired",
                    "unclaimed", "transferred", "superseded")
OWNERSHIP = (None, "unclaimed", "transferred")
# The seven of docs/legend.md -> Decision outcomes. Six are bare words; the
# seventh, `replaced -> DX`, carries a pointer and is matched by prefix. Until
# 0047 F8 this line read `("accepted", "rejected")` with `refined` and
# `superseded` accepted by prefix -- two values Revision 233 RETIRED, and four
# the legend defines rejected. `proposed` is the default the legend stores
# rather than leaving empty, so the default value failed its own check.
OUTCOMES = ("proposed", "accepted", "rejected", "deferred", "retracted", "voided")
POINTER_OUTCOMES = ("replaced",)             # `replaced -> DX`, pointer required
KINDS = ("runbook", "cross-cutting", "instruction-set", "session-management")
# `genus` is what sort of bundle this is; `kind` stays the subject domain it has
# always been. Two shapes, four genera, and SHAPE IS DERIVED -- never stored,
# because nothing derivable is stored.
GENERA = ("findings", "commission", "charter", "remedy")
SHAPE = {"findings": "reasoning", "commission": "reasoning",
         "charter": "actionable", "remedy": "actionable"}
# A member id carries its genus in its prefix: a finding, a question, a task.
MEMBER_PREFIX = {"findings": "F", "commission": "Q", "charter": "T", "remedy": "T"}
# The five of docs/legend.md. A session's `state` was the one closed set with no
# constant and no check: `conformance` compared the stored value against the
# derivation and never against a vocabulary, so a state outside the five would
# have been reported as a disagreement rather than as a word that does not
# exist. 0047 F11.
# `dissolved`, not `withdrawn`: a session state may not share a word with a
# finding status. 0039 F27, carried out at Revision 273.
SESSION_STATES = ("available", "active", "closed", "handoff", "dissolved")

# Every closed set in this file, by the field that carries it. The suite asserts
# that no value appears in two of them except where the design says it must --
# `docs/legend.md`: "no word appears in both vocabularies, and a schema check
# asserts the two sets are disjoint." 0047 F8 built the check for outcomes; F11
# widened it to every pair. Add a set here when you add one above, or the guard
# silently stops covering it.
VOCABULARIES = {
    "finding.status":    set(FINDING_STATUSES),
    "dossier.standing":  set(BUNDLE_STANDINGS),
    "dossier.progress":  set(BUNDLE_PROGRESS),
    "dossier.ownership": set(x for x in OWNERSHIP if x),
    "dossier.genus":     set(GENERA),
    "dossier.kind":      set(KINDS),
    "dossier.shape":     set(SHAPE.values()),
    "session.state":     set(SESSION_STATES),
    "decision.outcome":  set(OUTCOMES) | set(POINTER_OUTCOMES),
}

# The overlaps the design intends, each licensed by a sentence in the legend.
# Anything not listed here is a defect, which is the point: the exception is
# declared once, in data, rather than argued each time someone reads the sets.
DECLARED_OVERLAPS = {
    # "standing is progress with ownership and lineage put back in"
    frozenset(("dossier.standing", "dossier.progress")):
        {"analyzing", "answered", "revisited", "retired"},
    # "`standing` -- if `ownership` is set, that value"
    frozenset(("dossier.standing", "dossier.ownership")):
        {"unclaimed", "transferred"},
}


def undeclared_overlaps(skip=()):
    """Every value in two vocabularies that the design does not license.

    `skip` names pairs to leave out, so a known and unowned defect can be
    excluded from the guarding test without the guard quietly widening to cover
    it. Returns {frozenset(pair): {values}}.
    """
    out = {}
    names = sorted(VOCABULARIES)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            pair = frozenset((a, b))
            if pair in skip:
                continue
            shared = VOCABULARIES[a] & VOCABULARIES[b]
            shared -= DECLARED_OVERLAPS.get(pair, set())
            if shared:
                out[pair] = shared
    return out


def shape(b):
    """Derived, never read from the record."""
    return SHAPE.get(b.get("genus") or "findings")


def is_clone(b):
    """A bundle re-reading one it supersedes.

    0047 F5: its findings are reset to `framing` while it carries the original's
    decisions and resolutions forward, so `decision ahead of its finding` and
    `resolution ahead of its finding` are what a correct clone looks like. Without
    this exemption the sweep reported 65 false positives out of 77 on its first
    run -- the fourth instrument here to fail loudly against a healthy tree.
    """
    for e in (b.get("edges") or []):
        if e.get("kind") in ("carried", "successor"):
            return True
    return bool((b.get("lineage") or {}).get("supersedes"))


def conformance(g):
    """Every comparison the six checkers do not make. Returns (code, bundle, detail)."""
    out = []
    owned = set()
    for s in g.sessions.values():
        for ob in (s.get("ownedBundles") or []):
            owned.add(str(ob.get("number"))[:4])
    for name, sess in sorted(g.sessions.items()):
        if sess.get("state") is None:
            out.append(("UNSTAMPED", name, "state is null -- run `stamp`"))
        elif sess["state"] not in SESSION_STATES:
            out.append(("VOCAB", name, "state %r" % sess["state"]))
        elif sess["state"] != session_state(g, sess):
            out.append(("STORED-DISAGREES", name,
                        "state says %r, the record derives %r"
                        % (sess["state"], session_state(g, sess))))
    for n, b in sorted(g.bundles.items()):
        fs = b["_members"]
        sts = [x.get("status") for x in fs]
        clone = is_clone(b)
        for x in fs:
            if x.get("status") not in FINDING_STATUSES:
                out.append(("VOCAB", n, "%s has status %r" % (x["id"], x.get("status"))))
        if b.get("ownership") not in OWNERSHIP:
            out.append(("VOCAB", n, "ownership %r" % b.get("ownership")))
        if b.get("kind") not in KINDS:
            out.append(("VOCAB", n, "kind %r" % b.get("kind")))
        gen = b.get("genus")
        if gen not in GENERA:
            out.append(("VOCAB", n, "genus %r" % gen))
        else:
            want = MEMBER_PREFIX[gen]
            for x in (b.get("members") or []):
                mid = x.get("id") or ""
                if not mid.startswith(want):
                    out.append(("MEMBER-PREFIX", n,
                                "%s is a %s member and should start %s"
                                % (mid, gen, want)))
        # A bundle closed to every session must hold nothing open to one.
        # `unclaimed` is that bundle. `transferred` is NOT: docs/legend.md and
        # section 10 both permit transferring a bundle that stands `analyzing`,
        # and such a bundle has findings past `un-started` by definition -- so
        # this reported a documented, permitted operation as a conformance
        # failure, once at Revision 248 and five times at Revision 261. It was
        # the last executable site of the retired gloss `transferred: handed to
        # a session that has not opened it`. 0047 F7.
        #
        # The half that remains rests on a rule nobody has decided: what happens
        # to a finding when its bundle is released is 0047 F1, and it is open.
        # The row is kept because the tree really does hold that state, and the
        # detail says the rule is undecided rather than asserting it.
        if b.get("ownership") == "unclaimed":
            live = [x["id"] for x in fs if x.get("status") != "un-started"]
            if live:
                out.append(("CLOSED-BUNDLE-LIVE-FINDING", n,
                            "%s is unclaimed but %s are past un-started"
                            " -- 0047 F1, which is undecided"
                            % (n, ",".join(live))))
        # ownership null and in no manifest: owned by nobody, or nobody said
        if b.get("ownership") is None and n not in owned \
           and b["_progress"] not in ("resolved", "withdrawn") \
           and not (b.get("lineage") or {}).get("supersededBy"):
            out.append(("ORPHAN", n, "ownership is null and no manifest lists it"))
        ids = set(x["id"] for x in fs)
        cited = set()
        for d in (b.get("decisions") or []):
            o = d.get("outcome") or ""
            if o not in OUTCOMES and not o.startswith(POINTER_OUTCOMES):
                out.append(("VOCAB", n, "%s outcome %r" % (d.get("id"), o)))
            fl = d.get("members") or []
            if not fl:
                out.append(("UNCITED-DECISION", n, "%s cites no member" % d.get("id")))
            for fid in fl:
                cited.add(fid)
                if fid not in ids:
                    out.append(("DANGLING-CITATION", n,
                                "%s cites %s, which does not exist" % (d.get("id"), fid)))
        if not clone:
            for x in fs:
                if x.get("status") in ("framing", "un-started") and x["id"] in cited:
                    if all(((d.get("outcome") or "") == "accepted")
                           for d in (b.get("decisions") or [])
                           if x["id"] in (d.get("members") or [])):
                        out.append(("DECISION-AHEAD-OF-FINDING", n,
                                    "%s is %s with every decision accepted"
                                    % (x["id"], x["status"])))
                if x.get("resolution") and x.get("status") not in INERT:
                    out.append(("RESOLUTION-AHEAD-OF-FINDING", n,
                                "%s is %s and carries a resolution"
                                % (x["id"], x["status"])))
        if b.get("progress") is None:
            out.append(("UNSTAMPED", n, "progress is null -- run `stamp`"))
        elif b["progress"] != bundle_progress(b):
            out.append(("STORED-DISAGREES", n,
                        "progress says %r, the finding rows derive %r"
                        % (b["progress"], bundle_progress(b))))
        if b.get("standing") is None:
            out.append(("UNSTAMPED", n, "standing is null -- run `stamp`"))
        elif b["standing"] != bundle_standing(b):
            out.append(("STORED-DISAGREES", n,
                        "standing says %r, the record derives %r"
                        % (b["standing"], bundle_standing(b))))
        # a citation to a bundle whose authority has moved (0046)
        for e in (b.get("edges") or []):
            t = g.bundles.get(str(e.get("to", "")).split("/")[0])
            if t and (t.get("lineage") or {}).get("supersededBy") \
               and e.get("kind") not in ("carried", "successor", "supersedes"):
                out.append(("EDGE-TO-SUPERSEDED", n,
                            "%s edge to %s, which is superseded" % (e.get("kind"), e.get("to"))))
    return out


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
        nf = sum(len(b["_members"]) for b in owned)
        dec = redone = 0
        for b in owned:
            for d in (b.get("decisions") or []):
                dec += 1
                o = (d.get("outcome") or "")
                if o and o != "accepted":
                    redone += 1
            for x in b["_members"]:
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
          % (len(g.bundles), sum(len(b["_members"]) for b in g.bundles.values()),
             len(g.edges), len(g.live_sessions())))
    print("  edge kinds: %s" % dict(Counter(e.get("kind") for e in g.edges)))
    print("  unclaimed:  %d bundles, %d findings, %.1f cost units"
          % (len(q), sum(len(b["_members"]) for b in q), sum(g.cost(b) for b in q)))
    drift = [(b["number"], x["id"], x["status"]) for b in q
             for x in b["_members"] if x.get("status") != "un-started"]
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
    if cap == "auto":
        cap, _ = derive_capacity(g)
        if cap is None:
            cap = DEFAULT_CAPACITY
            print("CAPACITY  %.1f cost units, CHOSEN -- nothing to derive from.\n" % cap)
        else:
            print("CAPACITY  %.1f cost units, DERIVED from rework against load.\n"
                  "          Read `capacity` before trusting it: the proxy inverts,"
                  " and `0048` records why.\n" % cap)
    elif cap is None:
        cap = DEFAULT_CAPACITY
        print("CAPACITY  %.1f cost units, CHOSEN not measured -- `0048`. Pass"
              " --capacity N or --capacity auto.\n" % cap)
    else:
        cap = float(cap)
        print("CAPACITY  %.1f cost units, given on the command line.\n" % cap)
    if excluded:
        print("FILTERED  %d of %d unclaimed bundles excluded by the selection\n"
              % (excluded, len(select(g))))
    if not q:
        print("Nothing selected. Widen the filter.")
        return
    if a.new_sessions >= 0:
        r = allocate(g, new_sessions=a.new_sessions, cap=cap, queue=q,
                     only_new=a.only_new)
    else:                                   # --new-sessions -1 : size it for me
        n = 0
        while True:
            r = allocate(g, new_sessions=n, cap=cap, queue=q, only_new=a.only_new)
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
          % (len(r["queue"]), sum(len(b["_members"]) for b in r["queue"].values()),
             sum(g.cost(b) for b in r["queue"].values())))
    stranded = 0
    for n, es in sorted(r["held"].items()):
        ready = len(r["queue"][n]["_members"])
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
                  % (len(bs), sum(len(g.bundles[b]["_members"]) for b in bs),
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
          % (sum(len(b["_members"]) for b in g.bundles.values()), len(fr), len(askable)))
    print("  dropped: %d not `framing`, %d in unclaimed bundles, %d blocked"
          % (sum(len(b["_members"]) for b in g.bundles.values()) - len(fr),
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


def cmd_stamp(g, a):
    changed = stamp_derived(g, write=not a.dry_run)
    verb = "would write" if a.dry_run else "wrote"
    print("STAMP  %s %d record(s)\n" % (verb, len(changed)))
    for kind, name, want in changed[:40]:
        print("  %-8s %-52s %s" % (kind, name, want))
    if len(changed) > 40:
        print("  ... and %d more" % (len(changed) - 40))
    if not changed:
        print("  Every derived field already agrees with what it derives from.")


def cmd_check(g, a):
    rows = conformance(g)
    by = defaultdict(list)
    for code, n, detail in rows:
        by[code].append((n, detail))
    print("CONFORMANCE  %d finding(s) across %d bundles\n" % (len(rows), len(g.bundles)))
    for code in sorted(by):
        print("  %s  (%d)" % (code, len(by[code])))
        for n, d in by[code][:10]:
            print("      %s  %s" % (n, d))
        if len(by[code]) > 10:
            print("      ... and %d more" % (len(by[code]) - 10))
        print()
    if not rows:
        print("  Nothing. Every comparison the six checkers do not make, holds.")
    print("  Superseding clones are exempt from the two ordering comparisons"
          " -- 0047 F5.")


def main():
    p = argparse.ArgumentParser(prog="plan-findings-work")
    p.add_argument("command",
                   choices=["graph", "allocate", "ask", "capacity", "check",
                            "stamp"])
    p.add_argument("--new-sessions", type=int, default=0,
                   help="how many new session bundles to allow; -1 sizes it")
    p.add_argument("--capacity", default=None,
                   help="cost units a session may hold: a number, or `auto` to "
                        "derive it. Omitted, a chosen default is used -- see 0048")
    p.add_argument("--dry-run", action="store_true",
                   help="stamp: report what would change and write nothing")
    p.add_argument("--only-new", action="store_true",
                   help="propose only new sessions; do not add to existing ones")
    p.add_argument("--only-kind", help="allocate only these kinds, comma separated")
    p.add_argument("--exclude-kind", help="never allocate these kinds")
    p.add_argument("--only", help="allocate only these bundle numbers")
    p.add_argument("--exclude", help="never allocate these bundle numbers")
    a = p.parse_args()
    g = Graph(root())
    {"graph": cmd_graph, "allocate": cmd_allocate, "ask": cmd_ask,
     "capacity": cmd_capacity, "check": cmd_check,
     "stamp": cmd_stamp}[a.command](g, a)


if __name__ == "__main__":
    main()
