---
name: benchmark
description: Reproducible benchmark/experiment pipeline. Use when testing, benchmarking, or evaluating anything that must be reproducible across sessions and people. Enforces script-only execution (no hand-operated steps), frozen pipeline stages, and full raw data retention.
---

# Benchmark

All measurement through scripts. No hand-operated steps. Every run reproducible by anyone.

## Structure

```
benchmarks/
  001_<objective>/
    GOAL.md
    round-001-yyyy-mm-dd-HH-MM/
      ROUND.md
      1_collect_script/
        run.sh
        scratch_output/
      2_collect_output/
        run-001-yyyy-mm-dd-HH-MM/
          invoke.sh            # sh invoke.sh reproduces this exact run
          ...raw data...
        run-002-.../
          invoke.sh
          ...
      3_analysis_script/
        analyze.sh
        scratch_output/
      4_analysis_output/
        run-001-yyyy-mm-dd-HH-MM/
          invoke.sh
          ...report...
```

## Rules

- Frozen = directory renamed with `.frozen` suffix. Output dirs require their script dir frozen first.
- Each round is self-contained. Want to change anything frozen → new round (copy scripts, regenerate outputs).
- Same collect data, different analysis → new round with `2_collect_output` symlinked to the source round's.
- Raw data: per-record, never pre-aggregated. Capture more than the report needs, but not so much it drags the experiment.
- `invoke.sh` uses relative paths only. No absolute paths, no environment variables.

