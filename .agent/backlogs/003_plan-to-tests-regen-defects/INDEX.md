# 003 — plan_to_tests.py regeneration defects

Date: 2026-08-28
Status: pending — defects confirmed in production use, repair not yet implemented

## Summary

Two defects in `skills/spec-waterfall/scripts/plan_to_tests.py`, both hit during
the chill workspace backlog 091 Stage 3 run (2026-08-28). Workarounds are
recorded in chill's state
(`.agent/state/agent-os/kernel-mvp/usage/plan-to-tests-regeneration.md`); this
backlog tracks fixing the tool itself.

## Defect 1 — `--write` regeneration drops the module prelude

Regeneration preserves implemented test BODIES (per-obligation methods) but
rewrites each file from the template. Everything module-level outside the class
— `import json`, `from conftest import ...` / `from qa_helpers import ...`
lines, module constants, module helper `def`s (e.g.
`assert_indistinguishable_login_rejections`) — is silently discarded.
`py_compile` still passes, so damage surfaces only at runtime as `NameError`.
Observed blast radius: first 091 QA run went 124 failed / 41 errors from this
alone (suite was 163 preserved bodies).

## Defect 2 — parse step crashes on 3.12-only f-strings

The body-preservation pass parses existing files with `compile()` under the
skill venv (Python 3.11; `requires-python >=3.11`). Test suites run under their
own venvs (chill autonomous-qa: 3.12), so bodies legally containing 3.12-only
f-string quote nesting (`f"{d["k"]}"`) crash `--write`/`--diff` outright with
`SyntaxError: f-string: unmatched '['`.

## Repair plan

1. Prelude preservation: when the target file exists, carry over its module
   prelude verbatim (everything between the generated header/`import pytest`
   and the first `class`); the generator owns only the obligation-mapped class
   and method skeletons. Acceptance: regenerating over a suite with implemented
   bodies produces zero diff outside obligation-mapped methods.
2. Parser version: parse existing files with a grammar at least as new as the
   newest supported test-suite Python — simplest is bumping the skill env to
   `requires-python >=3.12` (verify both scripts run on 3.12); alternatively
   parse via the tests-dir venv's interpreter. Acceptance: a preserved body
   containing `f"{d["k"]}"` no longer crashes regeneration.
3. Regression tests for both in `scripts/test_plan_to_tests.py`: one file with
   prelude imports + module helper def surviving `--write`; one file with a
   3.12 f-string body surviving `--diff`.

## Workaround in force until fixed

- After any regeneration: restore preludes from git history and re-add imports
  (chill used an AST-driven fixer: used-but-unbound names mapped against
  conftest/qa_helpers top-level defs, fixtures excluded).
- Keep authored test bodies 3.11-parseable (single quotes inside double-quoted
  f-strings).
