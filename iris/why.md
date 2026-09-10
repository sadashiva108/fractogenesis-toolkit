# Why — what IRIS is for, and why not just use the assistant

> **Role.** The argument. What goes wrong without it, what each part answers, and
> when not to bother.
>
> **Authoritative for** nothing. It explains; the rules live elsewhere.

Read this if you are wondering why a conversation with an assistant needs a
filing system. The short answer is that it doesn't — **a conversation needs
nothing. A second conversation needs all of this.**

## Contents

- [1. The six failures](#1-the-six-failures)
- [2. Why model a session at all](#2-why-model-a-session-at-all)
- [3. Why Prism](#3-why-prism)
- [4. Why Lumen](#4-why-lumen)
- [5. Why retrace decisions not taken](#5-why-retrace-decisions-not-taken)
- [6. Why not just use the assistant](#6-why-not-just-use-the-assistant)
- [7. What it costs](#7-what-it-costs)
- [8. When not to use it](#8-when-not-to-use-it)

---

## 1. The six failures

Not hypotheticals. Each one is a thing that happened, repeatedly, to the person
who built this.

**Lateral context is lost.** The path taken survives in the transcript.
Everything considered and set aside evaporates — not because anyone decided
against it, but because nobody wrote it down. What survives is deep and narrow,
and the things lost are exactly what a fresh session most needs: the adjacent
problem noticed in passing, the approach weighed and dropped, the reason a scope
was drawn where it was.

**A rename leaves a broken mess.** Not every reference gets updated, and nothing
says which ones were *meant* to stay. In this repository 37 files carry citations
that **must not** be repaired, because repairing them would falsify a record of
its own moment — and telling those apart from the seven that must be repaired was
itself a decision somebody had to make.

**Instructions are followed halfway, again and again.** Wasted cycles to get
something half decent. This is usually diagnosed as the assistant not listening.
It is more often that the rules live in four places, two of them disagree, and
nothing said which wins.

**"How did I get here?" is not a question version control answers.** Git answers
*what did this look like before*. Nothing answers *what did we consider, and why
is it not what we did*.

**Several sessions collide.** Two assistants editing one working tree produce a
diff neither can be committed out of, and validator numbers that belong to
whoever else was writing.

**The output is a pile of paper nobody can read later.** Artifacts accumulate and
none of them is a resource — a stack on the desk rather than a memory.

[&#8593; Contents](#contents)

## 2. Why model a session at all

**A session is where context dies.** It is the only object with a boundary, an
owner and an end, so it is the only thing that can be asked *what did it know
when it decided that*. Without it, *how did I get here* has no subject.

**Why several.** One session cannot hold the whole record, and one that tries is
running on a summary of a summary — which is what produces the half-decent
output above. And parallel work on disjoint subjects is the only way to add
throughput when the bottleneck is one person. **The collision machinery exists
because several is the design**, not as a workaround: compose in a scratch copy,
take numbers at apply time, hand over a patch.

**Why assign.** Ownership is what makes *who may close this* answerable. Without
it every decision belongs to everyone and therefore to nobody, and the record
fills with contradictory half-decisions. `framing` is open to every session on
purpose; **closing the deciding is one hand.** That single asymmetry is what stops
the knot forming.

[&#8593; Contents](#contents)

## 3. Why Prism

**The scarce resource is the owner's attention, not compute.** Prism is a
scheduler for a human bottleneck, and its objective is *fewest things that come
back to you* — not *most work dispatched*.

It reasons over the graph: which dossiers block which, which share a surface,
which one decision would answer two of. Without it the queue is ordered by
whatever was noticed last, which is the order that maximises interruptions.

[&#8593; Contents](#contents)

## 4. Why Lumen

*My instructions seem ignored, lots of wasted cycles* is **a question-selection
failure, not an obedience failure.** Lumen picks the one question whose answer
unblocks the most, with the smallest sufficient context, and turns N vague
exchanges into one precise one.

**And it refuses to fake a ranking.** Asked for the next question with four
candidates tied, it printed:

```text
** TIE -- the ranker did not settle this. Say so rather than presenting an order.
```

A tool that declines to invent a preference is the difference between a scheduler
and a slot machine. Most of what an assistant gets wrong is not the answer; it is
answering confidently when the inputs did not determine one.

[&#8593; Contents](#contents)

## 5. Why retrace decisions not taken

**Because version control answers a different question and people mistake it for
this one.** A diff is a log of the path taken. This is a map of the space the path
went through.

**And everyone misses it because the cost is invisible when you choose and total
when you return.** At the moment of deciding, the eight rejected options are
obvious and writing them down feels like busywork. Six weeks later they are
unrecoverable, and the first thing anyone does — you, or an assistant with no
memory at all — is re-litigate them badly.

**A decision without its rejected alternatives is an assertion.** That sentence is
the whole framework compressed. Everything else is machinery for making it hold.

[&#8593; Contents](#contents)

## 6. Why not just use the assistant

**You should, for most things.** The assistant is better than this at almost
everything. What it cannot do is remember, and what it cannot do is be two
people.

| The assistant alone | With IRIS |
|---|---|
| holds the reasoning **in the conversation** | holds it in a record that outlives the conversation |
| starts each session knowing nothing about the last | starts by reading what the last one decided **and rejected** |
| will happily re-decide a settled question | a settled question has an owner, a decision and its alternatives |
| answers confidently when the inputs are tied | Lumen says the inputs are tied |
| one worker, one context window | several sessions, disjoint subjects, a merge discipline |
| you check everything | checks with published baselines check what they can, and **say what they do not examine** |

**The honest version of the pitch:** IRIS does not make the assistant smarter. It
makes the *second* assistant as informed as the first, which is the only lever
that compounds.

[&#8593; Contents](#contents)

## 7. What it costs

Stated plainly, because a document that only lists benefits is an advertisement.

- **Ceremony per decision.** A decision costs a row, a section and its rejected
  alternatives. On a small change that is more writing than the change.
- **A vocabulary to learn**, and it is not guessable — four closed sets, four
  genera, two shapes.
- **Discipline nothing enforces.** The central permissions are keyed on which
  session is acting, and **no instrument can see a session.** They are conventions
  held by sessions choosing to follow them, and that is written down rather than
  papered over.
- **A second lifecycle to keep honest** for every genus added. The first took
  thirty revisions and four instruments that failed loudly on healthy trees
  before it settled.
- **The temptation to route everything through it**, so that readings become
  tickets and the thinking — the thing it is *for* — thins out.

[&#8593; Contents](#contents)

## 8. When not to use it

- **A one-sitting task.** If it will not outlive the conversation, the
  conversation is the right container.
- **Work with no rejected alternatives.** If there was only ever one way to do it,
  there is no rationale to capture and the ceremony buys nothing.
- **Anything where the artifact is the record.** Code with good tests, a document
  with a clear history — those already answer *how did I get here*.

**The test is one question: will someone need to know why this was not done the
other way?** If yes, it belongs in the record. If no, do the work and move on.

[&#8593; Contents](#contents)
