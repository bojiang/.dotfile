# spec-waterfall-skill — Implementation

Skill lives at `skills/spec-waterfall/` (latest: commit 0184952, pushed).

## File map
- `SKILL.md` — the waterfall procedure, incl. the Rework gate (sections: Waterfall invariants, Stage 2 test branch item 3, Stage 3, Rework gate with Question 1 / Question 2 / Rework log).
- `scripts/_config.py` — shared loader for `spec-waterfall.json` (used by both scripts below).
- `scripts/analyse_spec.py` — spec contradiction gate.
- `scripts/plan_to_tests.py` — emits test skeletons per layer (one `test_gen_<layer>.py` per distinct layer name); skeletons filled from spec text only, never from implementation.
- `templates/` — `spec-waterfall.json`, `conftest.py`, `login_once.py`, `pyproject.toml` (neutral QA_* env vars).

## Rework gate (SKILL.md, commit 0184952)
Two ordered questions per verification failure:
- Q1 return-to-which-stage: implementation bug (stay Stage 3) / test-misreads-spec (rewrite test body from spec text) / spec bug (return to Stage 1). Three mandatory spec-bug signals that MUST NOT be absorbed in Stage 2/3: impl and test each correct in isolation but contradictory; one obligation unsatisfiable without breaking another; fix requires a concept absent from the spec.
- Q2 rewrite-or-modify: default rewrite. Patch allowed only if local to the single failing obligation, touching no interface/shared state/other obligation's artifact. Hard fuse: same obligation failing after 2 patch attempts -> delete the unit and re-derive from spec text WITHOUT reading the old implementation.
- After spec rework: every obligation reported added/modified by `plan_to_tests.py --diff` gets test body AND implementation unit deleted and re-derived, no merging; untouched obligations keep artifacts.
- Fuse state: `.rework_log.json` in tests_dir, one entry per obligation (patch count + rework events); count resets on test pass or manifest hash change; every triage starts by reading it. Convention only — pipeline scripts unchanged. File-backed deliberately: AI self-reporting of patch counts is unreliable.
- Coherence fix: Stage 2 test-branch "manual merge" wording replaced by reference to the rework gate.

## Generalization mechanism
Scripts are generic engines; zero project knowledge is hardcoded. Everything project-specific lives in one per-project `spec-waterfall.json` at the project root; paths resolve relative to the config file; allium runs with cwd = config dir.

## Sanitization status (verified 2026-08-22, do not re-verify)
Complete. Grep sweep over `skills/` for source-project traces (mcloud|modular|yatai|bentoml|lago|stripe|mantine|gemma|CENG-|mise|google sso|staging-api|model garden|playground) is CLEAN.
- Imported original `skills/mcloud-autonomous-qa/` (untracked) deleted from this repo.
- `CHANGELOG.md` dropped entirely (all source-project history).
- Originals remain external at `/Users/bjiang/works/mcloud/modularcloud/tests/autonomous-qa/` (pipeline scripts + MCloud handwritten tests — the handwritten tests were deliberately NOT migrated).
