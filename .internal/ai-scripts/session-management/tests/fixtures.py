#!/usr/bin/env python3
"""Synthetic trees shaped like the real one.

Every field here appears in a real `metadata.json`; the values are invented so a
test can build a tree that is wrong on purpose without touching the record. The
shapes are taken from docs/architecture/state-as-data.md sections 4.2 and 4.3.
"""
import json, io, os, shutil, tempfile

TREES = ("runbook-findings", "cross-cutting-findings",
         "instruction-set-findings", "session-management-findings")


def finding(fid, status="un-started", resolution=None, updated=None):
    return {"id": fid, "statement": "a statement for %s" % fid, "status": status,
            "statusReason": None, "statusNote": None, "updatedAt": updated,
            "sectionHeading": "%s -- a heading" % fid,
            "reopened": None, "withdrawn": None, "resolution": resolution}


def decision(did, members=None, outcome="accepted"):
    return {"id": did, "decision": "a decision", "members": members or [],
            "decided": "2026-09-08", "outcome": outcome,
            "sectionHeading": "%s -- a heading" % did}


def edge(kind, frm, to, basis="asserted", why="because"):
    return {"kind": kind, "from": frm, "to": to, "why": why, "reason": None,
            "basis": basis, "asserted_by": "test", "asserted_on": "2026-09-08"}


def bundle(number, statuses=("un-started",), kind="session-management",
           ownership="unclaimed", decisions=None, edges=None, lineage=None,
           resolutions=None, subject=None, genus="findings"):
    fs = []
    prefix = {"findings": "F", "commission": "Q",
              "charter": "T", "remedy": "T"}[genus]
    for i, st in enumerate(statuses, 1):
        res = None
        if resolutions and ("%s%d" % (prefix, i)) in resolutions:
            res = {"resolvedBy": "D1", "what": "done", "revision": 1, "commit": "abc1234"}
        fs.append(finding("%s%d" % (prefix, i), st, resolution=res))
    return {"schemaVersion": 1, "updatedAt": "2026-09-08T00:00:00-04:00",
            "number": number, "bundleName": "%s-a-bundle" % number,
            "genus": genus, "kind": kind,
            "subKind": None, "subject": subject or "a subject for %s" % number,
            "recordedOn": "2026-09-08", "recordedOccasion": "a test",
            "recordedBy": {"sessionBundle": "a-session-20260908-000000",
                           "sessionId": "session_test"},
            "severity": "a sentence about severity",
            "feltAt": ["somewhere"], "scope": "session management",
            "read": ["something"], "progress": None, "ownership": ownership,
            "lineage": lineage, "members": fs, "decisions": decisions or [],
            "contributions": [], "edges": edges or [], "indexNotes": None}


def session(name, owned=(), ended_on=None, declared=None):
    return {"schemaVersion": 1, "updatedAt": "2026-09-08T00:00:00-04:00",
            "bundleName": name, "createdOn": "2026-09-08",
            "owners": [{"from": "2026-09-08", "until": None, "assistant": "Claude",
                        "sessionId": "session_test", "model": "claude-opus-5",
                        "environment": "test"}],
            "transcript": None, "scratchPath": None, "resources": [],
            "ownedBundles": [{"number": n, "notes": None} for n in owned],
            "contributions": [], "declaredState": declared, "indexNotes": None,
            "ended": {"on": ended_on, "reason": None}}


class Tree(object):
    """A throwaway repository root holding docs/ only."""

    def __init__(self):
        self.root = tempfile.mkdtemp(prefix="sm-fixture-")
        for t in TREES:
            os.makedirs(os.path.join(self.root, "docs", t))
        os.makedirs(os.path.join(self.root, "docs", "sessions"))

    def add_bundle(self, b, tree="session-management-findings"):
        d = os.path.join(self.root, "docs", tree, b["bundleName"])
        os.makedirs(d, exist_ok=True)
        with io.open(os.path.join(d, "metadata.json"), "w", encoding="utf-8") as fh:
            fh.write(json.dumps(b, indent=2))
        return self

    def add_session(self, s):
        d = os.path.join(self.root, "docs", "sessions", s["bundleName"])
        os.makedirs(d, exist_ok=True)
        with io.open(os.path.join(d, "metadata.json"), "w", encoding="utf-8") as fh:
            fh.write(json.dumps(s, indent=2))
        return self

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)
