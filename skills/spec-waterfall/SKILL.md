---
name: spec-waterfall
description: Formal-spec waterfall for vibe coding. Use when turning a product idea or change request into working, test-verified code — ideation chat → Allium user-story spec (no implementation) → independently derived implementation and tests → verification loop until all obligations pass. Also for regenerating/executing the spec-derived test suite after a spec change.
---

# Spec Waterfall

A waterfall development pipeline anchored in a formal spec. The top is an
ideation chat between the product owner and the AI. The middle is a formal
definition containing only user stories — no implementation. Implementation and
tests are both derived from that definition, independently. Tests verify the
implementation until everything converges.

Requires the `allium` CLI (spec analysis and test-plan generation). The Python
environment is managed by `uv`.

## Waterfall

```
Ideation (product owner ↔ AI · PRD / ticket / discussion / code)
  ↓ allium:elicit (new spec) or allium:tend (evolve)   ← global reconciliation
Formal spec — user stories only, no implementation
  ↓ analyse_spec.py                        ← state-machine contradiction gate
  ├─→ Implementation                       ← agent implements obligations
  └─→ plan_to_tests.py → test skeletons    ← agent fills bodies from the spec
  ↓ execute tests against the implementation
Verification loop — fix implementation / spec / tests, until all obligations green
```

Every artifact traces to its source. Source changes → downstream regenerates.

The two derivation branches are independent by design: **tests are never written
from the implementation, and the implementation never reads the tests.** The
spec is their only shared parent — that is what makes a green run meaningful.

## Stage 0 — Ideation

Input is intent, in whatever form it arrives: a chat with the product owner, a
PRD, a ticket, a discussion thread, or existing code. Any one source suffices.

Turn intent into spec:

- New system or feature area → `allium:elicit` (structured discovery session).
- Change to an existing spec → `allium:tend`. Reconcile **globally**, not as a
  local patch: check whether the change renames or splits entities, alters or
  contradicts existing rules/surfaces/invariants, and update every affected
  definition so the spec stays one coherent model. If the source contradicts
  the current spec, surface the contradiction to the user before continuing.

When the source is **code**, do not hand code facts to the spec directly — code
is the source most likely to smuggle implementation detail into the model.
First translate each fact into user-observable behavior, then apply the
altitude rule (below) to every new entity field, rule, and surface. Example of
the failure mode: the backend splits a user-visible balance across two internal
ledgers, but the user sees one number — the spec models one balance; the ledger
split stays out.

## Stage 1 — Definition

The spec describes **user stories / user critical paths**, not product design
and not implementation:

- Entities model what the user interacts with
- Rules model user actions and system responses (happy path + error paths)
- Surfaces model UI/API boundaries (what's visible, what's actionable, under
  what conditions)
- Invariants model guarantees the user relies on

Keep everything in a single spec file — `allium:tend`'s global reconciliation
is strongest within one file — until it approaches ~1800 lines or a new major
topic area lands. Then split into per-topic modules (`use` imports; `analyse`
takes the directory, `plan` runs per module and the pipeline scripts must learn
to merge).

### Altitude rule

The model (entities, rules, surfaces, invariants) may only reference what a
user can observe or act on through the product's UI or public API. Internal
mechanisms — DB columns, caches, crons, infra labels/secrets, third-party
internals — never enter the model. They may appear in `@guidance` prose only,
and only when they explain user-perceivable timing or consistency (e.g. "a
balance change takes minutes to affect API 401s"); pure mechanism inventory
belongs in backlog notes, not the spec.

Litmus tests, applied to every new field / `requires` / `ensures`:

- **Rename test**: if the internal component were renamed or replaced, would
  the user see anything change? No → it is implementation; keep it out.
- **Observability test**: could an E2E test verify this through the UI or
  public API? No → it cannot be an obligation; drop it or demote it to
  `@guidance`.

### Contradiction gate

Run `analyse_spec.py` after every spec edit. It finds deadlocks, unreachable
states, dead transitions, missing exit paths — spec bugs that no amount of
testing will catch, because both derivation branches would inherit them. If
state machine issues are found, fix the spec (or confirm as design intent)
before anything flows downstream.

## Stage 2 — Derivation

Two branches, derived independently from the spec.

### Implementation branch

The agent implements from the spec's obligations:

1. `allium plan` output (via `plan_to_tests.py`, summary mode) enumerates the
   obligations; each rule, transition, and surface guard is an implementation
   unit.
2. Implement in spec order: entities → rules (happy paths, then each `requires`
   rejection) → surfaces → invariants.
3. Reference the spec rule name in the implementation unit (commit message,
   module docstring, or route handler comment) so traceability survives.
4. Never look at the generated tests while implementing.

### Test branch

Mechanical derivation, then agent completion:

1. `plan_to_tests.py --write` generates one test skeleton per E2E-relevant
   obligation: each rule with N `requires` clauses yields N rejection tests,
   each transition graph yields rejected-transition tests, each `when` field
   yields presence/absence tests. The spec defines happy paths; the derivation
   produces the failure paths.
2. The agent implements skeleton bodies **from the spec text only** — the
   obligation's description and its source rule. Never from the implementation.
3. Existing implemented tests are not overwritten on regeneration (manual
   merge); `--diff` shows which obligations changed.

## Stage 3 — Verification loop

Run the derived tests against the implementation. Triage every failure into
exactly one of three buckets:

- **Implementation bug** — the spec and test agree, the code doesn't. Fix the
  code. (The common case; the loop stays in this stage.)
- **Spec bug** — the failure reveals a contradiction or a wrong story. Go back
  to Stage 1 (`allium:tend` + contradiction gate), then re-derive both
  branches.
- **Test misreads the spec** — the test asserts something the spec doesn't
  say. Fix the test against the spec text; the implementation is not evidence.

**Convergence criterion**: every E2E-relevant obligation's test passes. The
coverage table (`plan_to_tests.py --readme`) is the progress report.

## Scripts

Both scripts live in this skill's `scripts/` directory and read per-project
configuration from `spec-waterfall.json` (see Configuration).

| Script | Input | Output | When to run |
|--------|-------|--------|-------------|
| `analyse_spec.py` | spec (from config) | State machine issues (fix or confirm) | After every spec edit |
| `plan_to_tests.py` | spec | Obligation/tier summary (default), skeletons (`--write`), diff (`--diff`) | After spec edit, before implementing |
| `plan_to_tests.py --diff` | spec + `.obligation_manifest.json` | Added/modified/removed test list | To check if tests are in sync with spec |
| `plan_to_tests.py --readme` | spec + generated test files | Coverage table in the tests dir README | Auto-run by `--write`; run standalone after implementing skeletons |

## Configuration

Each project carries one `spec-waterfall.json` at its root (pass another
location with `--config`). All paths are relative to the config file:

- `spec` — path to the `.allium` spec
- `tests_dir` — where skeletons, manifest, and README are generated
- `layers.default` — layer for obligations nothing else claims
- `layers.surfaces` — layer for surface obligations
- `layers.rules` / `layers.entities` — map rule/entity names to a layer; every
  distinct layer name gets its own `test_gen_<layer>.py`
- `tiers.entities` — map entities materialized by out-of-band pipelines to
  `minutes` (temporal obligations are `hours` automatically)

Layer and tier semantics live in the config, not in the spec — the spec stays
at user altitude. `templates/spec-waterfall.json` is a starting point.

## Project onboarding

1. Copy `templates/spec-waterfall.json` to the project root; fill in paths and
   layer/tier maps as the spec grows.
2. Instantiate `templates/conftest.py`, `templates/login_once.py`, and
   `templates/pyproject.toml` into the tests dir; adapt fixtures to the
   project's API and auth.
3. `uv sync && uv run playwright install chromium` in the tests dir (skip
   playwright if the project has no browser layer).
4. Provide the environment: `QA_API_BASE_URL`, `QA_API_KEY`, `QA_CONSOLE_URL`,
   `QA_STORAGE_STATE` — whichever the project's layers need.

## Test layers

Layers partition obligations by how they are exercised. The common two:

- **API layer** — HTTP client against the deployed API. Fast, no browser.
  Framework: pytest + httpx.
- **Browser layer** — headless Playwright Chromium against the deployed UI.
  Framework: pytest + playwright.

Run API-style layers first (fast feedback), browser layers second.

## Browser auth flow

For products behind SSO, automated login is usually not possible.

1. First-time: run `uv run login_once.py` — opens a headed Chromium; the user
   completes SSO manually; `uv run login_once.py --save` exports cookies to the
   storage-state file (`QA_STORAGE_STATE`).
2. All test runs are **headless**, reusing the saved storage state. No window,
   no focus stealing.
3. When tests fail with a redirect to the login page → the session expired;
   prompt the user to re-run `login_once.py`.

## DOM discovery protocol

For UIs without `data-testid` attributes, before writing selectors:

1. Navigate to the page headlessly
2. Probe candidate elements with `page.locator(sel).count()`
3. Use `expect().to_be_visible()` failures to get aria snapshots of the page
   structure
4. For component-library widgets (selects, popovers), target the visible input
   class and then the option text; avoid dropdown-container classes that also
   match hidden popovers

## Execution tiers

Every generated test carries exactly one tier marker for expected wall-clock:

- `seconds` — synchronous request/response assertions (default lane)
- `minutes` — out-of-band pipeline assertions (async propagation: metrics,
  usage, billing)
- `hours` — temporal obligations (deadline-driven rules)

Handwritten tests are unmarked and run in the default lane. Run lanes with
pytest markers: `uv run pytest -m "not minutes and not hours"` for the default
lane, `-m minutes` / `-m hours` for the slow lanes. Coverage numbers in the
tests dir README are generated — never hand-edit them.

## Traceability

Each test class/method and each implementation unit references its spec source:

```python
class TestApiAuthFailures:
    """Spec rules: RevokedKeyRejected, UnknownKeyRejected"""
```

The report maps both directions: failed test → obligation ID → spec rule →
user story ("what broke → which user story is affected"), and spec rule →
implementation unit ("what must change if this story changes").
