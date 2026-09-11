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
    ordering_exemptions, RE_READING,
    FINDING_STATUSES, BUNDLE_STANDINGS, BUNDLE_PROGRESS, OUTCOMES,
    POINTER_OUTCOMES, SESSION_STATES, VOCABULARIES, DECLARED_OVERLAPS,
    undeclared_overlaps, KINDS, INERT, quality,
    GENERA, SHAPE, MEMBER_PREFIX, shape,
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

    # ------------------------------------------------------------------
    # The exhaustive partition -- 0041 D7's precondition, and 0043 F7's
    # answer.
    #
    # F7: "the derived bundle status has an else branch that asserts
    # nothing, so a derivation bug always lands there." state-as-data.md
    # section 7 says the fixtures must be bundles that each land on a NAMED
    # row, plus at least one landing on `analyzing` FOR A STATED REASON
    # rather than by falling through.
    #
    # Hand-picked fixtures pin the cases somebody thought of. This does not
    # need anybody to think of them: `derivation_table` reads only set
    # membership -- all() and `in`, never a count -- so the presence set IS
    # the whole input, and a six-value vocabulary has 63 non-empty ones.
    # Enumerating them proves the table over its entire domain.
    #
    # THE ELSE BRANCH DOES ASSERT SOMETHING AND NOBODY HAD WRITTEN IT DOWN.
    # Measured here: `analyzing` holds exactly when there is a `framing` or
    # `decided` member, OR an `un-started` member beside one that is not.
    # 48 combinations by the first clause and 7 by the second, 55 in all.
    #
    # The second clause is why this is enumerated rather than argued. The
    # first characterisation attempted was "a live member, and nothing
    # else" -- plausible, tidy, and wrong on seven combinations, caught in
    # seconds by this loop. That is F7's own claim demonstrated on the
    # session writing its answer.
    # ------------------------------------------------------------------
    STATUSES = ("un-started", "framing", "decided",
                "resolved", "reopened", "withdrawn")

    def _combinations(self):
        import itertools
        for r in range(1, len(self.STATUSES) + 1):
            for c in itertools.combinations(self.STATUSES, r):
                yield c

    def test_the_derivation_partitions_every_presence_combination(self):
        # Pinning the SHAPE of the partition. A derivation bug moves a
        # combination from one row to another and these counts move with it,
        # including one that lands in `analyzing` and looks plausible there.
        from collections import Counter
        got = Counter(derivation_table(list(c)) for c in self._combinations())
        self.assertEqual(dict(got), {
            "untouched": 1,
            "retired": 1,
            "answered": 2,
            "revisited": 4,
            "analyzing": 55,
        })
        self.assertEqual(sum(got.values()), 63)

    def test_analyzing_is_a_positive_condition_with_two_witnesses(self):
        # 0043 F7 answered. Not "anything else" -- this, over the whole
        # domain. A bug that sends a combination into `analyzing` fails here
        # because no witness is present for it.
        live = {"framing", "decided"}
        for c in self._combinations():
            s = set(c)
            witness = bool(s & live) or ("un-started" in s and s != {"un-started"})
            self.assertEqual(derivation_table(list(c)) == "analyzing", witness, c)

    def test_each_named_row_holds_over_the_whole_domain(self):
        # The four rows that already state a positive condition, asserted
        # against every combination rather than one example each.
        inert = {"resolved", "withdrawn"}
        for c in self._combinations():
            s, got = set(c), derivation_table(list(c))
            if s == {"un-started"}:
                self.assertEqual(got, "untouched", c)
            elif s == {"withdrawn"}:
                self.assertEqual(got, "retired", c)
            elif s <= inert and "resolved" in s:
                self.assertEqual(got, "answered", c)
            elif "reopened" in s and (s - {"reopened"}) <= inert:
                self.assertEqual(got, "revisited", c)

    def test_an_empty_member_list_is_untouched_and_that_is_deliberate(self):
        # A bundle with no members at all. `untouched` rather than
        # `analyzing`, which the enumeration above cannot reach because it
        # starts at one status, so it is pinned separately.
        self.assertEqual(derivation_table([]), "untouched")

    def test_progress_is_never_stored(self):
        # state-as-data.md 4.4: progress is derived, ownership and lineage declared.
        g = graph_of(F.bundle("0100", ("framing",)))
        self.assertIsNone(g.bundles["0100"]["progress"])
        self.assertEqual(g.bundles["0100"]["_progress"], "analyzing")
        g._fixture.close()


class TestGenusAndShape(unittest.TestCase):
    """The genus is stored; the shape is derived from it and never stored.

    Revision 270 introduced both. These assert the properties the rename was
    made to protect, because a rename nothing guards is a rename that comes
    undone the first time somebody adds a genus and forgets half of it.
    """

    def test_four_genera(self):
        self.assertEqual(len(GENERA), 4)
        self.assertEqual(set(GENERA),
                         {"findings", "commission", "charter", "remedy"})

    def test_every_genus_has_a_shape_and_a_prefix(self):
        """A genus the maps do not cover is the half-added genus this guards."""
        for g in GENERA:
            self.assertIn(g, SHAPE, "%s has no shape" % g)
            self.assertIn(g, MEMBER_PREFIX, "%s has no member prefix" % g)
        self.assertEqual(set(SHAPE), set(GENERA))
        self.assertEqual(set(MEMBER_PREFIX), set(GENERA))

    def test_two_shapes_and_they_are_not_genera(self):
        """`reasoning` and `actionable` are shapes and never appear as a genus,
        which is Revision 243's tier-1 rule: no value shared between two sets."""
        self.assertEqual(set(SHAPE.values()), {"reasoning", "actionable"})
        self.assertFalse(set(SHAPE.values()) & set(GENERA))

    def test_no_shape_word_is_also_a_status_standing_or_outcome(self):
        other = set(FINDING_STATUSES) | set(BUNDLE_STANDINGS) \
            | set(BUNDLE_PROGRESS) | set(OUTCOMES) | set(GENERA)
        self.assertFalse(set(SHAPE.values()) & other)

    def test_shape_is_derived_not_read(self):
        """A bundle carrying a stored shape is ignored: the map decides."""
        b = F.bundle("0001", genus="commission")
        b["shape"] = "actionable"
        self.assertEqual(shape(b), "reasoning")

    def test_a_genus_outside_the_set_is_caught(self):
        b = F.bundle("0001", ("framing",))
        b["genus"] = "undertaking"
        self.assertIn("VOCAB", codes(graph_of(b)))

    def test_a_member_prefix_that_disagrees_with_the_genus_is_caught(self):
        """A commission holding `F1` says two things about what it is."""
        b = F.bundle("0001", ("framing",), genus="commission")
        b["members"][0]["id"] = "F1"
        self.assertIn("MEMBER-PREFIX", codes(graph_of(b)))

    def test_a_conformant_commission_is_clean_of_both(self):
        b = F.bundle("0001", ("framing",), genus="commission")
        self.assertEqual([m["id"] for m in b["members"]], ["Q1"])
        c = codes(graph_of(b))
        self.assertNotIn("VOCAB", c)
        self.assertNotIn("MEMBER-PREFIX", c)

    def test_an_actionable_bundle_holds_tasks(self):
        for gen in ("charter", "remedy"):
            b = F.bundle("0001", ("framing",), genus=gen)
            self.assertEqual([m["id"] for m in b["members"]], ["T1"])
            self.assertEqual(shape(b), "actionable")

    def test_the_derivation_does_not_care_which_genus(self):
        """Standing derives from member statuses alone -- that is what makes the
        genus cheap. `0037` answered on findings must answer on tasks too."""
        for gen in GENERA:
            b = F.bundle("0001", ("resolved", "resolved"),
                         genus=gen, ownership=None)
            self.assertEqual(bundle_progress(b), "answered")


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

    def test_five_session_states(self):
        """`dissolved`, not `withdrawn` -- 0039 F27, Revision 273.

        This assertion pinned `withdrawn` and had to move with the rename, which
        is the pattern Revision 268 named: a test can hold a defect in place as a
        contract. It is kept as a contract on the SET, not on the word, because a
        sixth state added without a decision is what it exists to catch.
        """
        self.assertEqual(sorted(SESSION_STATES), sorted(
            ("available", "active", "closed", "handoff", "dissolved")))

    def test_every_vocabulary_is_in_the_disjointness_set(self):
        # The guard covers what this dict lists and nothing else, so a set added
        # to the module and not to the dict is a guard that silently narrowed.
        # 0047 F11: for four revisions the check covered three vocabularies of
        # five, and the pair it did not cover was the broken one.
        for name, expected in (("finding.status", FINDING_STATUSES),
                               ("dossier.standing", BUNDLE_STANDINGS),
                               ("dossier.progress", BUNDLE_PROGRESS),
                               ("session.state", SESSION_STATES),
                               ("decision.outcome", OUTCOMES),
                               ("dossier.kind", KINDS)):
            self.assertIn(name, VOCABULARIES, name)
            self.assertTrue(set(expected) <= VOCABULARIES[name], name)


    def test_no_undeclared_overlap_between_vocabularies(self):
        """Every pair, and nothing is excused.

        docs/legend.md: "no word appears in both vocabularies, and a schema
        check asserts the two sets are disjoint." This is that check, over every
        pair of closed sets in the module, minus only the overlaps
        DECLARED_OVERLAPS licenses.

        It carried an exclusion until Revision 273. `withdrawn` was both a
        finding status and a session state, so the rule was broken in the
        document that states it -- `0039` F27 -- and `docs/legend.md` was not
        the instruments session's to change. The pair was skipped here by name
        and asserted separately under `expectedFailure`, so the suite reported
        the defect without going red for it. Revision 273 renamed the session
        value to `dissolved`; the skip and that second test are both gone, and
        this one now covers the whole surface. A NEW overlap fails here
        immediately.
        """
        found = undeclared_overlaps()
        self.assertEqual(found, {}, "undeclared overlap: %s" % found)

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
    """docs/legend.md: readability is a property of the MEMBER, not of ownership.

    There was a check here asserting that a bundle closed to every session holds
    nothing open to one. Both halves of it are gone: `transferred` at Revision
    268 -- section 10 permits transferring a bundle that stands `analyzing` --
    and `unclaimed` at Revision 289, when Revision 287 took `unclaimed` out of
    the legend's *nothing is readable* row. `0047` F7 and F1.
    """

    def test_no_ownership_value_makes_a_worked_member_a_failure(self):
        for own in (None, "unclaimed", "transferred"):
            for statuses in (("framing",), ("decided", "resolved"),
                             ("reopened", "resolved")):
                g = graph_of(F.bundle("0100", statuses, ownership=own))
                self.assertNotIn("CLOSED-BUNDLE-LIVE-FINDING", codes(g),
                                 (own, statuses))
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

    def test_0047_F1_an_unclaimed_bundle_is_exempt_and_counted(self):
        """Nobody may clear the row, so it is not reported -- and not silent.

        `docs/legend.md` since Revision 287: moving a member to `decided` or
        `resolved` is the owner's act, and an `unclaimed` bundle has no owner.
        `0001` F1 is `framing` with six accepted decisions and **cannot** be
        moved by anyone until the bundle is assigned. That is `0047` F2's drift,
        and it turns out not to be drift.
        """
        g = graph_of(F.bundle("0100", ("framing",), ownership="unclaimed",
                              decisions=[F.decision("D1", ["F1"])]))
        self.assertNotIn("DECISION-AHEAD-OF-FINDING", codes(g))
        frozen, cloned, unowned = ordering_exemptions(g)
        self.assertEqual(len(unowned), 1)
        self.assertEqual((frozen, cloned), ([], []))
        g._fixture.close()

    def test_0047_F1_an_owned_bundle_in_the_same_state_is_still_reported(self):
        """The exemption is ownership, not the shape. An owned bundle whose
        decisions are all accepted while the member sits in `framing` is drift,
        and stays reported."""
        g = graph_of(F.bundle("0100", ("framing",), ownership=None,
                              decisions=[F.decision("D1", ["F1"])]),
                     sessions=[F.session("a-session-20260908-000000",
                                         owned=["0100"], state="active")])
        self.assertIn("DECISION-AHEAD-OF-FINDING", codes(g))
        self.assertEqual(ordering_exemptions(g)[2], [])
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

    def test_0047_F11_a_session_state_outside_the_five_is_caught(self):
        """A session's `state` was the one closed set with no vocabulary check.

        `conformance` compared the stored value against the derivation and never
        against a word list, so `owned` -- a state retired at Revision 180 and
        still present in four tag files at `1c48deb` -- would have been reported
        as a disagreement rather than as a word that does not exist.
        """
        g = graph_of(F.bundle("0100", ("framing",), ownership=None),
                     sessions=[F.session("a-session-20260908-000000",
                                         owned=["0100"], state="owned")])
        rows = [r for r in conformance(g) if r[0] == "VOCAB"]
        self.assertTrue(any("state" in d for _, _, d in rows), rows)
        g._fixture.close()

    def test_0047_F11_a_legal_session_state_is_clean(self):
        for st in SESSION_STATES:
            g = graph_of(F.bundle("0100", ("framing",), ownership=None),
                         sessions=[F.session("a-session-20260908-000000",
                                             owned=["0100"], state=st)])
            rows = [d for c, _, d in conformance(g) if c == "VOCAB"]
            self.assertFalse([d for d in rows if "state" in d], (st, rows))
            g._fixture.close()

    def test_0047_F9_a_superseded_bundle_is_exempt_and_counted(self):
        """Its rows could never be cleared: writable by none, section 9.

        Eight of the eleven RESOLUTION-AHEAD rows standing at Revision 280 were
        in `0031` and `0032`, both superseded. A number that can only rise is
        not a signal -- so the rows go, and the suppression is COUNTED rather
        than asserted in a footer.
        """
        b = F.bundle("0100", ("framing", "framing"), ownership=None,
                     resolutions=("F1", "F2"),
                     lineage={"supersededBy": "0101", "on": None})
        g = graph_of(b)
        self.assertNotIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        frozen, cloned, unowned = ordering_exemptions(g)
        self.assertEqual(len(frozen), 2)
        self.assertEqual((cloned, unowned), ([], []))
        g._fixture.close()

    def test_0047_F10_a_clone_is_exempt_only_while_it_is_being_re_read(self):
        """The exemption used to be the whole bundle for its whole life.

        A clone that closed its re-reading and later acquired a genuine defect
        was the one bundle in the tree nothing would report.
        """
        for st in RE_READING:
            g = graph_of(F.bundle("0100", (st,), ownership=None,
                                  resolutions=("F1",),
                                  edges=[F.edge("carried", "0100/F1", "0090/F1", "derived")]))
            self.assertNotIn("RESOLUTION-AHEAD-OF-FINDING", codes(g), st)
            self.assertEqual(len(ordering_exemptions(g)[1]), 1, st)
            g._fixture.close()
        # past the re-reading window, the same clone is on its own
        g = graph_of(F.bundle("0100", ("decided",), ownership=None,
                              resolutions=("F1",),
                              edges=[F.edge("carried", "0100/F1", "0090/F1", "derived")]))
        self.assertIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        self.assertEqual(ordering_exemptions(g)[1], [])
        g._fixture.close()

    def test_0047_F10_a_reopened_member_keeps_its_resolution(self):
        """docs/legend.md: a reopened member is one put back in play and
        "NOTHING IS REVERTED" -- so the resolution row stands by design, in any
        bundle, clone or not. Reporting it is reporting the procedure being
        followed. No member in the tree is `reopened`, which is why nothing
        noticed: the same shape as F8's four never-written outcomes.
        """
        g = graph_of(F.bundle("0100", ("reopened",), ownership=None,
                              resolutions=("F1",)))
        self.assertNotIn("RESOLUTION-AHEAD-OF-FINDING", codes(g))
        self.assertEqual(ordering_exemptions(g), ([], [], []))  # not an exemption: not a hit
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
