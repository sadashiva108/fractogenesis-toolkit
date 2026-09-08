#!/usr/bin/env python3
"""Contracts and regressions for the session management framework.

Two kinds of test and the difference matters:

  CONTRACTS   assert what docs/legend.md, .github/session-management-instructions.md
              and docs/architecture/state-as-data.md SAY. If a contract changes,
              one of these fails and the change is deliberate rather than silent.

  REGRESSIONS assert that a defect the tree actually suffered cannot come back.
              Every one names where it came from -- a revision, a bundle, or a
              run. None is hypothetical.

Fixtures only. No test reads the real tree, so a test can be wrong on purpose.
"""
import os, sys, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import fixtures as F                                          # noqa: E402
from plan_findings_work import (                              # noqa: E402
    Graph, ladder, conformance, allocate, select, frontier, rank, is_clone,
    FINDING_STATUSES, OUTCOMES, KINDS, INERT, quality)


def codes(g):
    return sorted(set(c for c, _, _ in conformance(g)))


def graph_of(*bundles, **kw):
    t = F.Tree()
    for b in bundles:
        t.add_bundle(b)
    for s in kw.get("sessions", ()):
        t.add_session(s)
    g = Graph(t.root)
    g._fixture = t
    return g


# ---------------------------------------------------------------- CONTRACTS
class TestLadder(unittest.TestCase):
    """docs/legend.md: read the ladder in order, first row that matches wins."""

    def test_every_finding_un_started(self):
        self.assertEqual(ladder(["un-started", "un-started"]), "un-started")

    def test_every_finding_withdrawn(self):
        self.assertEqual(ladder(["withdrawn", "withdrawn"]), "withdrawn")

    def test_withdrawn_outranks_resolved(self):
        # Row 4 sits above row 5 so a bundle of nothing but withdrawals is
        # `withdrawn`, not `resolved`: nothing was carried through.
        self.assertEqual(ladder(["withdrawn"]), "withdrawn")

    def test_resolved_counts_withdrawn_as_finished(self):
        self.assertEqual(ladder(["resolved", "withdrawn"]), "resolved")

    def test_resolved_needs_at_least_one_resolved(self):
        self.assertNotEqual(ladder(["withdrawn", "withdrawn"]), "resolved")

    def test_reopened_dominates_the_inert(self):
        self.assertEqual(ladder(["reopened", "resolved", "withdrawn"]), "reopened")

    def test_reopened_beside_anything_live_is_analyzing(self):
        # Row 6 fires only when reopening is the WHOLE of the live work.
        for other in ("framing", "decided", "un-started"):
            self.assertEqual(ladder(["reopened", other]), "analyzing", other)

    def test_anything_else_is_analyzing(self):
        self.assertEqual(ladder(["framing", "resolved"]), "analyzing")
        self.assertEqual(ladder(["decided"]), "analyzing")

    def test_progress_is_never_stored(self):
        # state-as-data.md 4.4: progress is derived, ownership and lineage declared.
        g = graph_of(F.bundle("0100", ("framing",)))
        self.assertIsNone(g.bundles["0100"]["progress"])
        self.assertEqual(g.bundles["0100"]["_progress"], "analyzing")
        g._fixture.close()


class TestVocabulary(unittest.TestCase):
    """The closed sets. A value outside one is a defect, not a variant."""

    def test_six_finding_statuses(self):
        self.assertEqual(len(FINDING_STATUSES), 6)
        for s in ("un-started", "framing", "decided", "resolved",
                  "reopened", "withdrawn"):
            self.assertIn(s, FINDING_STATUSES)

    def test_inert_is_resolved_or_withdrawn(self):
        self.assertEqual(INERT, {"resolved", "withdrawn"})

    def test_four_kinds(self):
        self.assertEqual(sorted(KINDS), sorted(
            ("runbook", "cross-cutting", "instruction-set", "session-management")))

    def test_an_outcome_outside_the_vocabulary_is_caught(self):
        # Revision 230 found `replaced -> DX` in two decisions. Section 11
        # defines accepted, rejected, refined -> DX and superseded -> DX.
        g = graph_of(F.bundle("0100", ("framing",),
                              decisions=[F.decision("D1", ["F1"], "replaced → D5")]))
        self.assertIn("VOCAB", codes(g))
        g._fixture.close()

    def test_the_four_legal_outcomes_pass(self):
        for o in ("accepted", "rejected", "refined → D2", "superseded → D2"):
            g = graph_of(F.bundle("0100", ("decided",),
                                  decisions=[F.decision("D1", ["F1"], o)]))
            self.assertNotIn("VOCAB", codes(g), o)
            g._fixture.close()


class TestPermissionShape(unittest.TestCase):
    """docs/legend.md: a bundle closed to every session holds nothing open to one."""

    def test_unclaimed_with_a_framing_finding_is_caught(self):
        g = graph_of(F.bundle("0100", ("framing",), ownership="unclaimed"))
        self.assertIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g))
        g._fixture.close()

    def test_unclaimed_with_only_un_started_is_clean(self):
        g = graph_of(F.bundle("0100", ("un-started", "un-started")))
        self.assertNotIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g))
        g._fixture.close()

    def test_transferred_is_treated_the_same(self):
        g = graph_of(F.bundle("0100", ("framing",), ownership="transferred"))
        self.assertIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g))
        g._fixture.close()


class TestCrossFileAgreement(unittest.TestCase):
    """Section 11: every F cited exists, and every decision cites one."""

    def test_a_decision_citing_nothing_is_caught(self):
        g = graph_of(F.bundle("0100", ("framing",), decisions=[F.decision("D1")]))
        self.assertIn("UNCITED-DECISION", codes(g))
        g._fixture.close()

    def test_a_decision_citing_a_finding_that_does_not_exist_is_caught(self):
        g = graph_of(F.bundle("0100", ("framing",),
                              decisions=[F.decision("D1", ["F9"])]))
        self.assertIn("DANGLING-CITATION", codes(g))
        g._fixture.close()

    def test_a_resolution_on_a_live_finding_is_caught(self):
        g = graph_of(F.bundle("0100", ("framing",), ownership=None,
                              resolutions=("F1",)))
        self.assertIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        g._fixture.close()

    def test_a_resolution_on_a_resolved_finding_is_clean(self):
        g = graph_of(F.bundle("0100", ("resolved",), ownership=None,
                              resolutions=("F1",)))
        self.assertNotIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        g._fixture.close()


# --------------------------------------------------------------- REGRESSIONS
class TestRegressions(unittest.TestCase):

    def test_0047_F5_a_superseding_clone_is_exempt(self):
        """The sweep's first run reported 77 hits of which 65 were correct.

        0037-0041 are clones: findings reset to `framing`, carrying the
        originals' decisions and resolutions forward. Without the exemption the
        retrofit would be pointed at records that are already right.
        """
        clone = F.bundle("0100", ("framing", "framing"), ownership=None,
                         decisions=[F.decision("D1", ["F1"]), F.decision("D2", ["F2"])],
                         resolutions=("F1", "F2"),
                         edges=[F.edge("carried", "0100/F1", "0090/F1", "derived")])
        self.assertTrue(is_clone(clone))
        g = graph_of(clone)
        self.assertNotIn("DECISION-AHEAD-OF-FINDING", codes(g))
        self.assertNotIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        g._fixture.close()

    def test_0047_F5_a_bundle_that_is_not_a_clone_is_not_exempt(self):
        plain = F.bundle("0100", ("framing",), ownership=None,
                         decisions=[F.decision("D1", ["F1"])], resolutions=("F1",))
        self.assertFalse(is_clone(plain))
        self.assertIn("RESOLUTION-AHEAD-OF-FINDING", codes(graph_of(plain)))

    def test_0047_F2_accepted_decisions_that_never_moved_the_finding(self):
        """0001 F1 carried six accepted decisions and stayed `framing`."""
        g = graph_of(F.bundle("0100", ("framing",), ownership=None,
                              decisions=[F.decision("D%d" % i, ["F1"])
                                         for i in range(1, 7)]))
        self.assertIn("DECISION-AHEAD-OF-FINDING", codes(g))
        g._fixture.close()

    def test_R197_a_bundle_does_not_read_resolved_while_a_row_is_live(self):
        """Revision 197 found four `resolved` bundles whose rows never moved."""
        self.assertEqual(ladder(["resolved", "resolved", "framing"]), "analyzing")

    def test_R229_a_session_with_ended_on_null_is_live(self):
        """`ended` is always present as an object. `if ended:` saw zero of seven."""
        t = F.Tree()
        t.add_session(F.session("live-20260908-000000", ended_on=None))
        t.add_session(F.session("done-20260908-000001", ended_on="2026-09-01"))
        t.add_session(F.session("gone-20260908-000002", declared="handoff"))
        g = Graph(t.root)
        live = g.live_sessions()
        self.assertIn("live-20260908-000000", live)
        self.assertNotIn("done-20260908-000001", live)
        self.assertNotIn("gone-20260908-000002", live)
        t.close()

    def test_R229_capacity_is_respected_after_local_search(self):
        """Greedy alone claimed eight new sessions, used two, left four over."""
        t = F.Tree()
        for i in range(8):
            t.add_bundle(F.bundle("01%02d" % i, ("un-started",) * 3, ownership="unclaimed"))
        t.add_session(F.session("live-20260908-000000"))
        g = Graph(t.root)
        r = allocate(g, new_sessions=4, cap=8.0)
        self.assertIsNotNone(r)
        worst = max(r["parts"]["load"].values())
        self.assertLessEqual(worst, 8.0 * 2,
                             "local search left a session at %.1f against a cap of 8" % worst)
        t.close()

    def test_R229_proposed_session_names_are_distinct(self):
        """Two proposals were given the same kind, stamp and directory."""
        t = F.Tree()
        for i in range(6):
            t.add_bundle(F.bundle("02%02d" % i, ("un-started",) * 2, ownership="unclaimed"))
        t.add_session(F.session("live-20260908-000000"))
        g = Graph(t.root)
        r = allocate(g, new_sessions=3, cap=4.0)
        clusters = {}
        for b, n in r["assign"].items():
            clusters.setdefault(n, []).append(b)
        names = ["%s-%s" % (g.bundles[sorted(v)[0]]["kind"], sorted(v)[0])
                 for k, v in clusters.items() if k.startswith("<new-")]
        self.assertEqual(len(names), len(set(names)), names)
        t.close()

    def test_0046_an_edge_into_a_superseded_bundle_is_caught(self):
        """0039 F8 cited 0028, superseded two days after that text was written."""
        old = F.bundle("0090", ("resolved",), ownership=None,
                       lineage={"supersededBy": "0100", "on": "2026-09-01"})
        new = F.bundle("0100", ("framing",), ownership=None,
                       decisions=[F.decision("D1", ["F1"])],
                       edges=[F.edge("constrains", "0100/F1", "0090/F1")])
        g = graph_of(old, new)
        self.assertIn("EDGE-TO-SUPERSEDED", codes(g))
        g._fixture.close()

    def test_0046_a_lineage_edge_into_a_superseded_bundle_is_expected(self):
        old = F.bundle("0090", ("resolved",), ownership=None,
                       lineage={"supersededBy": "0100", "on": "2026-09-01"})
        new = F.bundle("0100", ("framing",), ownership=None,
                       decisions=[F.decision("D1", ["F1"])],
                       edges=[F.edge("carried", "0100/F1", "0090/F1", "derived")])
        g = graph_of(old, new)
        self.assertNotIn("EDGE-TO-SUPERSEDED", codes(g))
        g._fixture.close()


class TestAllocator(unittest.TestCase):

    def _queue(self, n=4, ownership="unclaimed"):
        t = F.Tree()
        for i in range(n):
            t.add_bundle(F.bundle("03%02d" % i, ("un-started",) * 2,
                                  ownership=ownership))
        t.add_session(F.session("live-20260908-000000"))
        return t

    def test_the_queue_is_ownership_not_progress(self):
        t = self._queue()
        t.add_bundle(F.bundle("0399", ("framing",), ownership=None))
        g = Graph(t.root)
        self.assertNotIn("0399", select(g))
        self.assertEqual(len(select(g)), 4)
        t.close()

    def test_filters_narrow_the_queue(self):
        t = self._queue()
        t.add_bundle(F.bundle("0399", ("un-started",), kind="runbook",
                              ownership="unclaimed"))
        g = Graph(t.root)
        self.assertEqual(len(select(g, only_kind=["runbook"])), 1)
        self.assertNotIn("0399", select(g, skip_kind=["runbook"]))
        self.assertEqual(sorted(select(g, only=["0300"])), ["0300"])
        self.assertNotIn("0300", select(g, skip=["0300"]))
        t.close()

    def test_a_bundle_blocked_from_outside_is_held_not_assigned(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0400", ("framing",), ownership=None))
        t.add_bundle(F.bundle("0401", ("un-started",), ownership="unclaimed",
                              edges=[F.edge("blocks", "0400/F1", "0401/F1")]))
        t.add_session(F.session("live-20260908-000000"))
        g = Graph(t.root)
        r = allocate(g, new_sessions=0)
        self.assertIn("0401", r["held"])
        self.assertNotIn("0401", r["assign"])
        t.close()

    def test_the_allocator_assigns_nothing_it_only_proposes(self):
        t = self._queue()
        g = Graph(t.root)
        before = {n: b.get("ownership") for n, b in g.bundles.items()}
        allocate(g, new_sessions=1)
        after = {n: b.get("ownership") for n, b in Graph(t.root).bundles.items()}
        self.assertEqual(before, after, "allocate() mutated the tree")
        t.close()


class TestInterviewer(unittest.TestCase):

    def test_only_framing_is_on_the_frontier(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0500", ("framing", "decided", "un-started",
                                       "resolved", "withdrawn"), ownership=None))
        g = Graph(t.root)
        fr = frontier(g)
        self.assertEqual([r["f"] for r in fr], ["F1"])
        t.close()

    def test_a_framing_finding_in_an_unclaimed_bundle_is_not_askable(self):
        """Allocation strictly precedes inquiry."""
        t = F.Tree()
        t.add_bundle(F.bundle("0500", ("framing",), ownership="unclaimed"))
        g = Graph(t.root)
        fr = frontier(g)
        self.assertEqual(len(fr), 1)
        self.assertFalse(fr[0]["owned"])
        t.close()

    def test_a_blocked_finding_scores_zero(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0600", ("framing",), ownership=None))
        t.add_bundle(F.bundle("0601", ("framing",), ownership=None,
                              edges=[F.edge("blocks", "0600/F1", "0601/F1")]))
        g = Graph(t.root)
        top = rank(g, frontier(g))
        blocked = [r for r in top if r["id"] == "0601/F1"][0]
        self.assertEqual(blocked["score"], 0)
        t.close()


class TestQualityReport(unittest.TestCase):

    def test_rework_counts_only_outcomes_that_are_not_accepted(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0700", ("resolved", "resolved"), ownership=None,
                              decisions=[F.decision("D1", ["F1"], "accepted"),
                                         F.decision("D2", ["F2"], "rejected")]))
        t.add_session(F.session("s-20260908-000000", owned=("0700",)))
        g = Graph(t.root)
        row = quality(g)[0]
        self.assertEqual(row["decisions"], 2)
        self.assertEqual(row["rework"], 1)
        t.close()


if __name__ == "__main__":
    unittest.main(verbosity=2)
