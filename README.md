# python-agent-guardrails

A minimal, human-curated, three-layer guardrails template for AI coding
agents working in Python repositories.

It is not a package. It is not a framework. It is a small set of files you
copy into a Python project so that AI agents (Claude Code, Cursor, Codex,
Cline, Gemini CLI, and others) behave more like disciplined engineers and
less like enthusiastic interns.

## Why three layers?

Guardrails fail when they are only prose. An agent saying "I ran the tests"
is not evidence that it ran the tests. Three primary findings inform this
template:

- *On the Impact of AGENTS.md Files on the Efficiency of AI Coding Agents*
  (Lulla et al., arXiv 2601.20404): persistent repository instructions
  reduced median wall-clock time by ~28.6% and median output tokens by
  ~16.6% in paired Codex experiments across 124 pull requests. The study
  measured efficiency, not correctness, and used a single agent on small
  PRs (under 100 LOC changes).

- *Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for
  Coding Agents?* (Gloaguen et al., ETH Zurich): repository-level context
  files gave marginal correctness gains; LLM-generated and human-written
  files performed similarly; inference cost rose roughly 20%. The format
  is an efficiency trade-off, not a correctness fix.

- *From Confident Closing to Silent Failure: Characterizing False Success
  in LLM Agents* (Advani, arXiv 2606.09863): among AppWorld coding
  trajectories that explicitly claimed completion, 75.8% of failures were
  false-success claims — the agent said it was done while the environment
  disagreed. LLM judges were unreliable at detecting them (AUROC 0.54 on
  AppWorld API-call traces). Lightweight TF-IDF classifiers outperformed
  the judges.

The implication: an instruction file is worth having (it is cheap, and it
measurably saves time), but no instruction file — however well written —
can substitute for independent verification. So this template separates
three jobs:

| Layer | Job                                                            | Files |
|-------|----------------------------------------------------------------|-------|
| 1     | **Intent** — what should happen                                | `AGENTS.md` |
| 2     | **Workflow** — how the agent should work                       | `.agents/skills/*/SKILL.md` |
| 3     | **Evidence** — what can independently establish what happened  | `.github/workflows/`, `.pre-commit-config.yaml` |

Prose guides. Skills provide procedure. Tests and tooling provide evidence.
Human review resolves what machines cannot establish.

## Two skills, not five

`waitsec`, the PHP/Laravel project this template draws from, defined five
core guardrails: ask-first, anti-overengineering, small-diff, debug-first,
verify-first. This template keeps only two of them as on-demand skills:

- ask-first, anti-overengineering, and small-diff are always relevant, so
  they live as numbered rules in `AGENTS.md`.
- debug-first and verify-first are conditional — they apply when a failure
  has occurred or a task is being finished — so they live as skills that
  load on demand.

This is deliberate. Skills are on-demand context; always-on rules belong
in the always-loaded file. It is a smaller design than waitsec's, not an
incomplete one.

## How to use this

From a clone of this repo, let the script do the copy:

    python install.py /path/to/your-project

It copies the six template files, refuses to overwrite anything that
already exists, and renames `LICENSE.md` to
`LICENSE-python-agent-guardrails.md` on the way so it won't collide with
your project's own licence. Run `python install.py -h` for usage, or
`--force` to overwrite existing files.

Or copy by hand. Copy `AGENTS.md`, `.agents/`, `.github/`, and
`.pre-commit-config.yaml` to the root of your Python project. You may also
copy `LICENSE.md`; if you do, please keep the link to the original repo,
or replace the file with your own licence.

Whichever path you took, the next step is the same:

**Edit the Project section** of `AGENTS.md` for your actual stack. The
values shipped in the template are placeholders.

Then:

- Copy `.agents/skills/` if your agent supports on-demand skills
  (Claude Code, Cursor, Gemini CLI, and others). Otherwise skip it;
  skills are optional depth, not required scaffolding.
- Copy `.github/workflows/verify.yml` and `.pre-commit-config.yaml` into
  your project. Adjust the commands to whatever your project actually runs.
- Run the checks once locally on a clean tree before the agent ever
  touches the repo. If they don't pass on a clean tree, they won't tell
  you anything useful when the agent starts editing.

## What this template deliberately does *not* do

- It does not install itself into your project. There is no `pip install`
  in your project's dependency list. `install.py` is a convenience for
  copying the files; the files are data, not something you import.
- It does not include a plugin system or a DSL.
- It does not auto-generate `AGENTS.md`. Human authorship is the point.
- It does not enforce diff size by file count. "Small diff" means
  proportional scope, not "fewer than N files."
- It does not treat the agent's own report as evidence of anything.
- It does not claim CI proves correctness. CI proves the configured checks
  passed. A test can pass because the wrong behaviour wasn't tested; a
  linter can pass while the feature is wrong; a type checker can pass
  while the algorithm is wrong. Human review remains the arbiter for
  intent that cannot be mechanically specified.

If you find yourself extending this template into a project of its own,
you have probably violated its own methodology. Keep it small.

## A note on this repo's own CI

This repository ships a minimal Python project (`pyproject.toml`, `src/`,
`tests/`) so its own CI runs something real. Two caveats:

- `mypy --strict` passes trivially against
  `src/template_selftest/__init__.py`, which is a docstring only. Type
  checking does not become meaningful until real code lands in that
  package. The package exists to make the template's own CI pass, not to
  be part of your project. Delete it when copying.
- The GitHub Actions in `.github/workflows/verify.yml` use version tags
  (`@v4`, `@v6`) rather than commit SHAs. For a repo that will run
  workflows on untrusted pull requests, pin to SHAs instead — see the
  upstream release pages for `actions/checkout` and `astral-sh/setup-uv`.

## Provenance

Assembled from a review of `waitsec` (Packagist, PHP/Laravel) and the
surrounding research on AGENTS.md, instruction-following, and false-success
behaviour in coding agents. The PHP/Laravel framing of `waitsec` is
discarded; the underlying engineering discipline is kept and adapted to
Python tooling.
