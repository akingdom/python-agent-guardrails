---
name: verify-first
description: Use before declaring any task complete. Run the narrowest
  meaningful check first, then broaden. Report the exact command and result.
---

# Skill: Verify-First (Python)

## When to use

Before reporting that a task is done. Also before asking a human to review a
change.

## Procedure

1. **Pick the narrowest meaningful check.** For a behaviour change, that is
   usually the specific test (or a small subset) that exercises the changed
   behaviour — not the whole suite.

   ```bash
   uv run pytest tests/path/to/test_file.py -k "relevant_thing" -x
   ```

2. **Run it. Read the output.** "Tests pass" is not a result. The result is
   which tests ran, which passed, which failed, and the assertion messages.

3. **Broaden according to risk.** If the change touches shared code, public
   APIs, or anything else with a wide blast radius, run the full suite.

   ```bash
   uv run pytest
   ```

4. **Run the linter and type checker if the project uses them.**

   ```bash
   uv run ruff check .
   uv run ruff format --check .
   uv run mypy .
   ```

5. **Report the exact commands and their output.** Do not summarise.
   "I ran `uv run pytest tests/test_x.py::test_y` — 1 passed" is a claim
   someone else can verify. "I tested it" is not.

## What verification does *not* establish

Passing tests do not prove the change implements the user's intent. They
only prove the tests pass. If a test can pass because the wrong behaviour
wasn't tested, add the missing test before claiming success.

CI provides independent mechanical evidence that the configured checks
passed. It does not establish that the change implements the user's intent
— only a check that encodes that intent can do that. Human review remains
the arbiter for intent that cannot be mechanically specified.
