# Resolutions — superseding a bundle whose session is gone

**Bundle:** `0040-superseding-a-bundle-whose-session-is-gone`  
**Session:** `assurance-coverage-20260908-204724`  
**Resolved:** 2026-09-09

Every row closes against Revision 200, which restored the supersession procedure
after Revision 198 dropped it. The work was done before this bundle was assigned;
these rows record where it landed, so the status has something behind it.

## Resolutions

| Finding | Resolved by | What was done | Revision | Commit |
|---|---|---|---|---|
| F1 | D1 | `.github/session-management-instructions.md` gained section 9, *Superseding a bundle* — nine numbered steps, the three prohibitions, and the provenance gates. The term is defined where a session performing it will read it | 200 | `4626eb4` |
| F2 | D1 | Section 9 states that a bundle is superseded from any status, names the settled-bundle-with-no-owner case as the one an earlier rule left unhandled, and rules that the superseding session does not take ownership | 200 | `4626eb4` |
| F3 | D1 | Section 9's *"Three things it must NOT do"* carries all three prohibitions F3 reasoned out during Revision 183 | 200 | `4626eb4` |
| F4 | D1 | Section 9 step 5 fixes the index form: the Status cell becomes the link to the replacement, always a link, never the bare word | 200 | `4626eb4` |

**The `Scope:` line in `findings.md` names `.github/copilot-instructions.md`
§4c**, which Revision 191 split. The reading is not edited; this table is the
record of where the fix actually landed. `0041` D5 is the rule that made these
rows name a file and a construct rather than a section number.
