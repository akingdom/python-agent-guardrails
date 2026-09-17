# python-agent-guardrails

Your AI agent refactored forty files when you asked for a typo fix.

It said tests passed. They hadn't run.

It created a base class, an ABC, and a factory for a function you'd
delete next week.

Six files fix this. You copy them into your Python project, edit one
section, and the agent stops behaving like an enthusiastic intern.

## The one idea

An agent saying "I ran the tests" is not evidence that it ran the tests.

Every guardrail in this template is a variation on that sentence. Prose
guides the agent. Machinery checks what the agent actually did. The
second half is what most prompt collections miss.

## What you get

| Layer | Does | Files |
|---|---|---|
| **Intent** | Tells the agent what should happen | `AGENTS.md` |
| **Workflow** | Tells the agent how to work | `.agents/skills/` |
| **Evidence** | Checks what happened | `.github/workflows/`, `.pre-commit-config.yaml` |

The first two are markdown. The third runs whether the agent cooperates
or not.

## Install

One command, from anywhere:

    uvx python-agent-guardrails /path/to/your-project

Or install once and reuse:

    pip install python-agent-guardrails
    pag /path/to/your-project

Or, from a clone:

    python install.py /path/to/your-project

All three do the same thing. They refuse to overwrite anything, rename
`LICENSE.md` so it can't collide with yours, and print the one file you
need to edit — the Project section of `AGENTS.md` — with a command to
open it.

The install takes under a second. Editing `AGENTS.md` for your stack
takes a minute. After that you can uninstall the package; the files
stayed behind.

## What changes

Four behaviours stop happening:

**The agent asks before it builds.** If your prompt is missing decisions
that materially change the implementation — where files go, what shape
the data has — it asks 1–3 direct questions first. Otherwise it inspects
your repo and follows your existing conventions.

**The agent touches less.** Only what the task requires. No reformatting
of untouched files. No dependency added for a three-line change.

**The agent reads the traceback.** Before proposing a fix. No
`except Exception: pass`. No guessing.

**The agent shows its work.** The exact command it ran and its result,
before it says "done."

None of these are novel. They're the things a careful engineer does by
default. The template exists because agents don't.

## Why you can trust it

Three studies, none of which measure this template. They measure the
ideas it's built on.

**Persistent repo instructions save time.** Paired Codex experiments
across 124 pull requests found median wall-clock time down ~28.6% and
median output tokens down ~16.6% when an `AGENTS.md` was present.
*On the Impact of AGENTS.md Files on the Efficiency of AI Coding Agents*
(Lulla et al., arXiv 2601.20404). Efficiency, not correctness, on small
changes.

**But they don't fix correctness on their own.** Repository-level
context files gave marginal correctness gains, and LLM-written files
performed about the same as human-written ones. Inference cost rose
~20%. *Evaluating AGENTS.md* (Gloaguen et al., ETH Zurich).

**And agents lie about success.** Among AppWorld coding trajectories
that claimed completion, 75.8% of failures were false-success claims —
the agent said it was done while the environment disagreed. LLM judges
missed most of them (AUROC 0.54). TF-IDF classifiers beat the judges.
*From Confident Closing to Silent Failure* (Advani, arXiv 2606.09863).

The third finding is why the third layer exists. If the agent's report
can't be trusted, verification has to live outside the agent.

## Where it comes from

`waitsec` (Packagist, PHP/Laravel) defined five rules: ask-first,
anti-overengineering, small-diff, debug-first, verify-first. Three are
always relevant, so they live in `AGENTS.md`. Two are conditional —
they apply when a failure has occurred, or a task is finishing — so
they load as skills. The PHP framing is dropped; the discipline is kept.

## For maintainers

Template files live twice: at the repo root, where agents and humans
read them, and at `src/pag/template/`, which ships in the wheel. Root
is canonical. `scripts/sync-template.sh` copies root → package.
`tests/test_template_sync.py` fails if they drift.

`scripts/publish_prep_v3.sh` runs release checks. It doesn't commit,
tag, or push — the git step is manual, via GitHub Desktop, on purpose.

CI uses version tags (`@v4`, `@v6`) rather than SHAs. Pin to SHAs
before running on untrusted pull requests.