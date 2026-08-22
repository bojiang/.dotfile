# spec-waterfall-skill — Usage

Skill entry: `skills/spec-waterfall/SKILL.md` (repo-relative in .dotfile).

## Pipeline invocation order
1. Ideation chat: `allium:elicit` / `allium:tend` (allium runs with cwd = config-file dir).
2. Author Allium user-story spec (no implementation; altitude rule).
3. Gate: `scripts/analyse_spec.py` — contradiction check must pass.
4. Branch A: agent implements from spec obligations. Branch B: `scripts/plan_to_tests.py` emits test skeletons, filled from spec text only.
5. Run tests; triage failures (impl bug / spec bug / test-misreads-spec); repeat until all E2E-relevant obligations pass.

## Per-project config: `spec-waterfall.json` at project root
Single home for ALL project-specific knowledge. Keys:
- `spec`, `tests_dir`
- `layers.default` / `layers.surfaces` / `layers.rules` / `layers.entities`
- `tiers.entities`
Paths resolve relative to the config file. One `test_gen_<layer>.py` is produced per distinct layer name.

## Project scaffolding
Instantiate from `skills/spec-waterfall/templates/`: `spec-waterfall.json`, `conftest.py`, `login_once.py`, `pyproject.toml`. Env vars are neutral QA_*: `QA_API_BASE_URL`, `QA_API_KEY`, `QA_CONSOLE_URL`, `QA_STORAGE_STATE`.
