---
name: debug-first
description: Use when a test fails, a traceback appears, or runtime
  behaviour does not match expectations. Read evidence before proposing a fix.
---

# Skill: Debug-First (Python)

## When to use

- A traceback or error message is present.
- A test is failing.
- Runtime behaviour does not match the specification.

## Procedure

1. **Isolate.** Run the failing test alone, with a long traceback:

   ```bash
   uv run pytest tests/path/to/test_file.py::test_name --tb=long -x
   ```

2. **Read the full traceback.** Identify the exception type, the file and
   line where it was raised, and the call stack that led there. Do not skim.

3. **Explain the failure in plain language.** What was the code trying to do?
   What actually happened? Why did the exception occur?

4. **Reproduce minimally.** If the failure is not already captured by a test,
   write a small one that fails for the same reason. This becomes the target.

5. **Fix the root cause, not the symptom.** Change only the code responsible
   for the failure. Prefer the smallest change that makes the failing test
   pass without weakening the assertion.

6. **Re-run.** Run the failing test to confirm the fix. Then broaden
   verification according to the risk and scope of the change — see the
   `verify-first` skill. A change to a leaf module may need only its own
   tests; a change to shared code should run the full suite.

## Anti-patterns (do not do these)

- Wrapping the failure in `try / except` to make it "go away."
- Adding `time.sleep()` to hide a race condition instead of explaining it.
- Editing the test's assertion to match the buggy output.
- Rewriting surrounding code "while you're in there."
