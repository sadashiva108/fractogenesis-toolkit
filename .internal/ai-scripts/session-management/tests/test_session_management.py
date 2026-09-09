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
    Graph, derivation_table, conformance, allocate, select, frontier, rank, is_clone,
    FINDING_STATUSES, BUNDLE_STANDINGS, BUNDLE_PROGRESS, OUTCOMES,
    POINTER_OUTCOMES, KINDS, INERT, quality,
    bundle_standing, bundle_progress, session_state, stamp_derived)


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
    """docs/legend.md: read the derivation_table in order, first row that matches wins.

    Finding STATUSES go in, a bundle STANDING comes out. Since Revision 233 the
    two vocabularies share no word, so every assertion here is also a check that
    the translation happened rather than a value passing straight through.
    """

    def test_the_two_vocabularies_share_no_word(self):
        self.assertEqual(set(FINDING_STATUSES) & set(BUNDLE_STANDINGS), set())

    def test_every_finding_un_started(self):
        self.assertEqual(derivation_table(["un-started", "un-started"]), "untouched")

    def test_every_finding_withdrawn(self):
        self.assertEqual(derivation_table(["withdrawn", "withdrawn"]), "retired")

    def test_retired_outranks_answered(self):
        # Row 4 sits above row 5 so a bundle of nothing but withdrawals is
        # `retired`, not `answered`: nothing was carried through.
        self.assertEqual(derivation_table(["withdrawn"]), "retired")

    def test_answered_counts_withdrawn_as_finished(self):
        self.assertEqual(derivation_table(["resolved", "withdrawn"]), "answered")

    def test_answered_needs_at_least_one_resolved(self):
        self.assertNotEqual(derivation_table(["withdrawn", "withdrawn"]), "answered")

    def test_revisited_dominates_the_inert(self):
        self.assertEqual(derivation_table(["reopened", "resolved", "withdrawn"]), "revisited")

    def test_reopened_beside_anything_live_is_analyzing(self):
        # Row 6 fires only when reopening is the WHOLE of the live work.
        for other in ("framing", "decided", "un-started"):
            self.assertEqual(derivation_table(["reopened", other]), "analyzing", other)

    def test_anything_else_is_analyzing(self):
        self.assertEqual(derivation_table(["framing", "resolved"]), "analyzing")
        self.assertEqual(derivation_table(["decided"]), "analyzing")

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

    def test_seven_outcomes(self):
        # docs/legend.md -> Decision outcomes. Six bare words plus the one that
        # carries a pointer, which is matched by prefix rather than listed.
        self.assertEqual(sorted(OUTCOMES), sorted(
            ("proposed", "accepted", "rejected", "deferred", "retracted",
             "voided")))
        self.assertEqual(POINTER_OUTCOMES, ("replaced",))

    def test_outcomes_and_statuses_share_no_word(self):
        # docs/legend.md: "No word appears in both vocabularies, and a schema
        # check asserts the two sets are disjoint." Nothing asserted it until
        # 0047 F8; the legend has claimed this check since Revision 233.
        words = set(OUTCOMES) | set(POINTER_OUTCOMES)
        self.assertEqual(words & set(FINDING_STATUSES), set())
        self.assertEqual(words & set(BUNDLE_STANDINGS), set())
        self.assertEqual(words & set(BUNDLE_PROGRESS), set())

    def test_an_outcome_outside_the_vocabulary_is_caught(self):
        for o in ("in progress", "closed", "superseded → D5"):
            g = graph_of(F.bundle("0100", ("framing",),
                                  decisions=[F.decision("D1", ["F1"], o)]))
            self.assertIn("VOCAB", codes(g), o)
            g._fixture.close()

    def test_the_seven_legal_outcomes_pass(self):
        for o in ("proposed", "accepted", "rejected", "deferred", "retracted",
                  "voided", "replaced → D2"):
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

    def test_a_transferred_bundle_may_hold_worked_findings(self):
        # docs/legend.md: "A bundle may be transferred while it stands
        # `assigned`, `revisited` or `analyzing`", and section 10 says the same.
        # An `analyzing` bundle has findings past `un-started` by definition, so
        # a transfer of worked findings is permitted and not a failure.
        for statuses in (("framing",), ("decided", "resolved"),
                         ("reopened", "resolved")):
            g = graph_of(F.bundle("0100", statuses, ownership="transferred"))
            self.assertNotIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g), statuses)
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

    def test_0047_F7_a_transfer_of_worked_findings_is_not_a_failure(self):
        """Revision 248 transferred `0039` with 23 findings past `un-started`.

        The check reported it, and reported five more at Revision 261. Section
        10 permits transferring a bundle that stands `analyzing`, which has
        worked findings by definition, so the check refused an operation the
        instruction set allows -- the last executable site of a gloss the
        documents retired.
        """
        g = graph_of(F.bundle("0100", tuple(["framing"] * 23),
                              ownership="transferred"))
        self.assertNotIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g))
        g._fixture.close()

    def test_0047_F7_unclaimed_is_still_reported(self):
        """Only the `transferred` half went. `0001` is the live instance."""
        g = graph_of(F.bundle("0100", ("framing",), ownership="unclaimed"))
        rows = [r for r in conformance(g) if r[0] == "CLOSED-BUNDLE-LIVE-FINDING"]
        self.assertEqual(len(rows), 1)
        self.assertIn("0047 F1", rows[0][2])       # the rule it rests on is open
        g._fixture.close()

    def test_0047_F8_a_legend_outcome_is_not_a_vocabulary_failure(self):
        """`replaced -> DX` is one of the legend's seven and the check rejected it.

        Three live decisions carried it -- `0039` D1 and D4 and `0050` D1 --
        and each was reported VOCAB by the instrument that exists to validate
        them, while the two values Revision 233 retired passed.
        """
        for o in ("replaced → D13", "replaced → D5", "replaced → D2"):
            g = graph_of(F.bundle("0100", ("decided",),
                                  decisions=[F.decision("D1", ["F1"], o)]))
            self.assertNotIn("VOCAB", codes(g), o)
            g._fixture.close()

    def test_0047_F8_the_retired_outcomes_are_refused(self):
        """`refined -> DX` and `superseded -> DX` collapsed into `replaced -> DX`.

        The second was also a bundle standing, which is the disjointness the
        legend claims a check asserts.
        """
        for o in ("refined → D2", "superseded → D2"):
            g = graph_of(F.bundle("0100", ("decided",),
                                  decisions=[F.decision("D1", ["F1"], o)]))
            self.assertIn("VOCAB", codes(g), o)
            g._fixture.close()

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
        self.assertEqual(derivation_table(["resolved", "resolved", "framing"]), "analyzing")

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


class TestDerivedStateIsStoredAndChecked(unittest.TestCase):
    """Revision 232: status and progress are written down, so they can drift.

    The legend permits a stored copy of a derived value only where a check fails
    when it drifts. These are that check.
    """

    def test_assigned_is_standing_only_and_untouched_is_progress_only(self):
        owned = F.bundle("0100", ("un-started",), ownership=None)
        self.assertEqual(bundle_progress(owned), "untouched")
        self.assertEqual(bundle_standing(owned), "assigned")
        free = F.bundle("0101", ("un-started",), ownership="unclaimed")
        self.assertEqual(bundle_progress(free), "untouched")
        self.assertEqual(bundle_standing(free), "unclaimed")
        self.assertNotIn("assigned", BUNDLE_PROGRESS)
        self.assertNotIn("untouched", BUNDLE_STANDINGS)

    def test_standing_layers_ownership_over_progress(self):
        b = F.bundle("0100", ("framing",), ownership="unclaimed")
        self.assertEqual(bundle_standing(b), "unclaimed")
        self.assertEqual(bundle_progress(b), "analyzing")

    def test_lineage_outranks_ownership(self):
        b = F.bundle("0100", ("resolved",), ownership="unclaimed",
                     lineage={"supersededBy": "0101", "on": "2026-09-01"})
        self.assertEqual(bundle_standing(b), "superseded")

    def test_standing_is_progress_when_neither_applies(self):
        b = F.bundle("0100", ("resolved",), ownership=None)
        self.assertEqual(bundle_standing(b), bundle_progress(b))

    def test_a_null_standing_is_reported_as_unstamped(self):
        g = graph_of(F.bundle("0100", ("framing",), ownership=None))
        self.assertIn("UNSTAMPED", codes(g))
        g._fixture.close()

    def test_a_stored_value_that_drifts_is_caught(self):
        b = F.bundle("0100", ("resolved",), ownership=None)
        b["standing"] = "analyzing"          # a hand edit, or a stale stamp
        b["progress"] = "answered"
        g = graph_of(b)
        self.assertIn("STORED-DISAGREES", codes(g))
        g._fixture.close()

    def test_stamping_makes_the_check_pass(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0100", ("framing", "resolved"), ownership=None))
        t.add_session(F.session("s-20260908-000000", owned=("0100",)))
        g = Graph(t.root)
        self.assertIn("UNSTAMPED", codes(g))
        stamp_derived(g, write=True)
        self.assertNotIn("UNSTAMPED", codes(Graph(t.root)))
        self.assertNotIn("STORED-DISAGREES", codes(Graph(t.root)))
        t.close()

    def test_session_state_derives_when_nothing_is_declared(self):
        t = F.Tree()
        t.add_bundle(F.bundle("0100", ("framing",), ownership=None))
        t.add_bundle(F.bundle("0101", ("resolved",), ownership=None))
        t.add_session(F.session("empty-20260908-000000"))
        t.add_session(F.session("busy-20260908-000001", owned=("0100",)))
        t.add_session(F.session("done-20260908-000002", owned=("0101",)))
        g = Graph(t.root)
        self.assertEqual(session_state(g, g.sessions["empty-20260908-000000"]), "available")
        self.assertEqual(session_state(g, g.sessions["busy-20260908-000001"]), "active")
        self.assertEqual(session_state(g, g.sessions["done-20260908-000002"]), "closed")
        t.close()

    def test_a_declaration_wins_over_the_derivation(self):
        """handoff and withdrawn cannot be derived from what a session holds."""
        t = F.Tree()
        t.add_bundle(F.bundle("0100", ("framing",), ownership=None))
        t.add_session(F.session("s-20260908-000000", owned=("0100",), declared="handoff"))
        g = Graph(t.root)
        self.assertEqual(session_state(g, g.sessions["s-20260908-000000"]), "handoff")
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
