# State Index

Project: dotfiles repo; hosts Claude Code global config (.claude/ symlinked into ~/.claude by init.sh).

## spec-waterfall-skill
Project-agnostic waterfall vibe-coding skill at `skills/spec-waterfall/`: ideation (allium) -> user-story spec -> contradiction gate -> independent derivation of implementation and tests from spec -> verify loop. Core invariants: tests derive from spec text only, never from implementation; spec is the only asset — derived artifacts are consumables (rework gate).
- [requirements/INDEX.md](spec-waterfall-skill/requirements/INDEX.md) — intent, core invariant, spec rules
- [usage/INDEX.md](spec-waterfall-skill/usage/INDEX.md) — pipeline invocation, per-project spec-waterfall.json keys, scaffolding
- [implementation/INDEX.md](spec-waterfall-skill/implementation/INDEX.md) — file map, generalization mechanism, verified sanitization status
- Known defects pending repair: plan_to_tests.py regeneration drops module preludes; its parser chokes on 3.12-only f-strings — see [backlog 003](../backlogs/003_plan-to-tests-regen-defects/INDEX.md)

## coding-agent-knowledge-persistence
State-keeper subagent + Stop-hook fuse that persists costly-and-stable conclusions into .agent/state/.
- [implementation/INDEX.md](coding-agent-knowledge-persistence/implementation/INDEX.md) — current mechanism, file map, design trade-offs/rejected alternatives, and hook/agent platform gotchas hit while building it
