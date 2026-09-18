# Benchmark Skill — Usage

Reproducible benchmark/experiment pipeline. Enforces script-only execution, frozen 4-stage pipeline, round-based iteration.

Skill definition: `skills/benchmark/SKILL.md`

## When to use
Testing, benchmarking, or evaluating anything that must be reproducible across sessions and people.

## Key invariants
- No hand-operated steps; all measurement through scripts
- 4 stages strictly sequential: collect_script -> collect_output -> analysis_script -> analysis_output
- Freeze (`.frozen` suffix) required before advancing to next stage
- Rounds are self-contained snapshots; never cross-reference files between rounds
- Raw data maximally retained in collect_output (save everything, not just what the report needs)
