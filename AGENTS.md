# AGENTS.md

## Rules

1. **Ask only when necessary.**
   If an unresolved decision materially changes the implementation, ask 1-3
   direct questions. Otherwise inspect the repository, follow existing
   conventions, and proceed. Do not interrogate the developer about things
   the codebase already answers.

2. **Smallest complete change.**
   Touch only what the task requires. No unrelated refactors, no reformatting
   of untouched files, no new dependencies unless explicitly requested. A
   focused change can span source, test, and docs; "small" means proportional,
   not "fewest files."

3. **Inspect before inventing.**
   Search the repo and the standard library before adding a package or
   creating a new abstraction. If an existing helper, module, or convention
   already solves the problem, use it.

4. **Debug from evidence.**
   When something fails, read the full traceback before proposing a fix.
   Identify the exact failing line and condition. Never guess. Never silence
   errors with a bare `except:` or `except Exception: pass`.

5. **Verify the changed behaviour.**
   Run the narrowest meaningful check first, then broaden by risk. Report the
   exact command you ran and its result. Do not claim a task is complete
   without evidence. If tests fail, surface the failure — do not work around
   it silently.

## Project

Edit this section for this repository. The values below are placeholders.

- Python: `<supported version(s), e.g. 3.12+>`
- Package manager: `<uv / poetry / pdm / pip / pip-tools / other>`
- Testing: `<pytest / unittest / other>`
- Lint / format: `<tool(s), e.g. ruff / black + isort / flake8>`
- Types: `<mypy / pyright / none>`

Keep this section short. Put the minimum into the always-loaded context and
move conditional detail into `.agents/skills/`.

## About this file

This file is part of the python-agent-guardrails template. When you copy it
into a project, replace the Project section above. Do not auto-generate the
file; human authorship is what makes it pay off.
