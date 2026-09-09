# The toolkit's own documents have no currency watches

**Recorded:** 2026-09-09, from a session-management bundle that decided this and should not have.  
**Session:** `assurance-coverage-20260908-204724`  
**Severity:** moderate. Eleven references and five architecture records describe machinery that changes without them, and one — `master-directory-reference.md` — is cited by 31 documents, so a stale one misleads broadly.  
**Felt at:** `references/` (11 files, none watched); `docs/architecture/restore-repos-clone-plan.md`, `restore-docker-teardown-and-test.md`, `sign-off-consolidation.md`, `time-machine-run-index.md`; `docs/ledgers/evidence-conformance.md`  
**Scope:** the toolkit set. The watches live in `.internal/ai-scripts/session-management/doc-currency.json`, but which of the toolkit's documents earn one is `.github/toolkit-instructions.md`'s to decide.  
**Relates to:** `0053` — its D2 decided these watches from a session-management bundle and D5 withdrew that scope; this is where they belong  
**Relates to:** `0050` — its F5 is why the gap was invisible: `--coverage` did not sweep `references/` at all until Revision 255

**Read:**

- all eleven `references/*.md`, opened one at a time
- the five unwatched architecture records and `docs/ledgers/evidence-conformance.md`
- `.internal/ai-scripts/session-management/doc-currency.json` and `doc_currency.py`
- inbound citation counts for each, across every tracked Markdown file

Recorded by the session that did the reading. **Not owned** — the toolkit set
governs it and the owner assigns.

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Eleven reference documents describe machinery that changes without them, and none is watched | `un-started` |
| F2 | Four architecture records and one ledger describe toolkit machinery and are unwatched | `un-started` |
| F3 | Whether a document goes stale was tested by what it names, and the relationship runs the other way | `un-started` |

## F1 — the references describe the machinery and nothing watches them

Every one of the eleven was opened on 2026-09-09. Each describes something that
changes without it:

| Reference | Describes | Cited by |
|---|---|---:|
| `artifact-config-reference.md` | `.internal/artifact-config.sh`, `reimage.env` | 5 |
| `backup-file-reference.md` | what the pre-image backup scripts produce | 6 |
| `backup-strategy-guide.md` | destination and safety rules behind `backup-*.md` | 3 |
| `certificate-types-guide.md` | the concepts `stage-certs-keychain.md` Step 5 and Supplemental Reference send you to | 1 |
| `environment-variable-reference.md` | which runbook owns each `reimage.env` key | 5 |
| `master-directory-reference.md` | the whole `$REIMAGE_ARTIFACT_ROOT` map | **31** |
| `reimage-prep-evidence.md` | what Phase 4 and 6 generate | 4 |
| `reimaged-system-evidence.md` | what Phases 8, 9, 13, 14 generate | 5 |
| `restore-file-reference.md` | the restore-side files and evidence | 4 |
| `restore-strategy-guide.md` | the bootstrap problem and the jump drive | 6 |
| `toolkit-environment-reference.md` | `$FRACTOGENESIS_HOME`, `reimage.env`, `.envrc` | 9 |

**`master-directory-reference.md` is cited by 31 documents.** A stale directory
map is followed by every runbook that points at it.

## F2 — the architecture records and one ledger

`restore-repos-clone-plan.md`, `restore-docker-teardown-and-test.md`,
`sign-off-consolidation.md` and `time-machine-run-index.md` all open with
*plan, not built* or *design, not started*. **That does not exempt them.** Each
was written against how the scripts behave today, so a plan whose premises moved
is stale even though nothing was built — and a plan is read at the moment
somebody finally builds it, which is the worst moment to discover it describes an
older tree.

`docs/ledgers/evidence-conformance.md` is a survey of the sign-off helper, the
templates and the state capture, and `docs/INDEX.md` says a ledger is
*re-derived and replaced wholesale*. Nothing tells anyone when to re-derive it.

**The four date-stamped ledgers are not in scope**: their filenames fix them to a
day and they are records of a migration that happened.

## F3 — the test was run in the wrong direction

The reading that produced this bundle first asked, of each document, **does it
name any file in this repository**. That is what a document points *at*.

**A reference is cited by runbooks and rarely names them.** On that test
`references/certificate-types-guide.md` named zero files and was declared
permanently unwatchable — and `stage-certs-keychain.md` cites it twice. The owner
caught it.

**The same test had already contradicted itself and nobody noticed**:
`backup-strategy-guide.md` also names zero files and had been watched on other
grounds. Two documents, identical measurement, opposite verdicts, in one sitting.

**The direction that decides staleness is inbound**: what cites this, and does
that thing change. Recorded as its own finding because it is the method, and a
later session repeating the outbound test will reach the same wrong answers.
