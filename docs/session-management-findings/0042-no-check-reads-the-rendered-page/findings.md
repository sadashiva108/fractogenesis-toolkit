# No check reads the rendered page, and three revisions shipped defects that only the rendering showed

**Recorded:** 2026-09-06, while conforming the bundle documents to the header schema  
**Session:** `restore-apps-outstanding-20260903-000000` (`session_016EbjB7M527qEFqZFzpv2C9`)  
**Severity:** F1 is high. The repository's whole assurance surface is six checkers, and a class of defect passes all six by construction — not by oversight, but because none of them looks at the artefact a reader sees.  
**Felt at:** `bin/verify-doc-paths.sh`, `bin/verify-runbook-structure.sh`, `bin/verify-script-portability.sh`, `bin/verify-findings-counts.sh`, `bin/verify-findings-structure.sh`, `bin/verify-findings-headers.sh`  
**Scope:** cross-cutting in effect, session management in subject — the rule is about what a session must verify before handing work over, not about anything this project does  
**Relates to:** `0041` — its finding 2, *`verify-doc-paths.sh` gives false assurance*, is the same shape one level down: a check that passes while the thing it is trusted to cover is untested

## Findings

| # | Finding | Status |
|---:|---|---|
| F1 | Every checker reads the source; none reads what the source renders as | `un-started` |
| F2 | Three consecutive revisions shipped a rendering defect that all six checkers passed | `un-started` |
| F3 | A rendering check needs a markdown parser, which is a dependency the repository does not have | `un-started` |
| F4 | The audit that did find these ran outside the repository and was never committed | `un-started` |

## F1 — Every checker reads the source; none reads what the source renders as

All six validators operate on the markdown file as text: `grep`, `awk`, line
patterns, table shapes counted by pipe characters. Not one of them renders the
document and inspects the result.

Markdown is not a display of its source. It joins consecutive lines into a
paragraph, consumes asterisks as emphasis, interprets a bracketed word as an HTML
tag, and treats an indented block as code or not depending on the renderer. **A
file can be correct as text and wrong as a page**, and every check the repository
has is on the wrong side of that line.

This is not a gap in coverage that more rules would close. `verify-findings-headers.sh`
was extended in Revisions 202 and 203 until it made 877 assertions about the
header block, and it still cannot see the defect that made the header unreadable,
because the defect is not in the file.

## F2 — Three consecutive revisions shipped a rendering defect that all six checkers passed

| Revision | What shipped | What the checkers said |
|---|---|---|
| 201 | Header fields written as consecutive lines. Markdown joined all five into one run-on paragraph with the field names buried in it | all clean |
| 202 | The schema example fenced by four-space indentation. A renderer processed it as live markdown: backticks became inline code, `## Contributions` became a heading, `<where the fix lands>` was swallowed as an HTML tag | all clean |
| 203 | The same example fenced with ` ``` ` but tagged `markdown`. A renderer read that tag as *render this as markdown* and interpreted it again | all clean |

Each was found by **the owner opening the page**. Not one was found by a session,
and not one could have been: the sessions ran the checks, the checks passed, and
the checks were the only evidence available.

The second and third are the sharper instance. **The document was a
specification, and it rendered as the defect it specifies against** — twice, by
two different mechanisms, with a checker added after the first one that did not
catch the second.

## F3 — A rendering check needs a markdown parser, which is a dependency the repository does not have

This is why the finding is recorded rather than fixed, and the decision is the
owner's.

The repository is documentation plus shell and Python, with **no build system, no
CI, and no declared runtime dependency beyond a POSIX userland**. Its portability
floor is macOS stock Bash 3.2 with BSD tools. A CommonMark parser in that
environment does not exist, and a partial one written in `awk` would be a second
implementation of markdown whose disagreements with the real renderer are exactly
the defects it is meant to catch.

The options, none costed:

- **A Python checker with a parser dependency** — `markdown-it-py` or equivalent,
  installed per-session. Correct, and it puts a package requirement on a
  repository that has kept to none.
- **A checker that runs when a parser is present and skips when it is not** —
  no new hard dependency, and a check that silently does nothing is close to
  worse than no check.
- **Leave it to a person.** Make *"open the page before handing it over"* an
  instruction rather than a check, and accept that it will be skipped.
- **Reduce the surface instead**: forbid the constructs whose rendering is
  renderer-dependent, and check for those by pattern. This is what Revisions 202
  and 203 actually did — no indented blocks, no `markdown` fence tag — and F2
  records that it caught each defect one revision after it shipped.

## F4 — The audit that did find these ran outside the repository and was never committed

The sweep that established the tree renders correctly — all 135 markdown files
rendered and their output tested for one field per rendered line, required tables
with the right columns, cell counts matching their headers, placeholders not
swallowed as tags, and no literal markdown surviving into the prose — ran in a
session's own workspace against a copy, using a parser installed there.

**It is not in `bin/` and nothing records how to reproduce it.** The next session
that wants the same assurance has no way to obtain it, and the current claim that
the tree renders clean rests on a run nobody else can repeat. That is the same
defect `0041` finding 3 names in another form: the fix existed, and the record of
it did not.

Worth noting against F3: that audit's own first run reported 131 failures, of
which **128 were bugs in the audit** — a regex matching `<thead>` when it meant
`<th>`. A rendering check is not free of the problem it is checking for.

<!-- historical: bin/verify-findings-counts.sh -->
<!-- historical: bin/verify-findings-headers.sh -->
<!-- historical: bin/verify-findings-structure.sh -->
