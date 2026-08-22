#!/usr/bin/env python3
"""
Analyse Allium spec for state machine issues.
Runs `allium analyse`, parses findings, reports actionable items.

Usage:
    analyse_spec.py [spec_path] [--config path/to/spec-waterfall.json]
    # spec defaults to the config's `spec`; config defaults to ./spec-waterfall.json
"""
import json
import subprocess
import sys
from pathlib import Path

from _config import load_config, positional_args

# Findings that indicate state machine problems
STATE_MACHINE_CODES = {
    "allium.status.noExit": "NO EXIT — status has no rule that transitions out of it",
    "allium.status.unreachableValue": "UNREACHABLE — no rule ever assigns this status",
    "allium.status.deadlock": "DEADLOCK — entity can enter this state but never leave",
    "allium.transition.dead": "DEAD TRANSITION — declared edge has no witnessing rule",
    "allium.rule.missing_producer": "MISSING PRODUCER — rule requires a trigger nobody emits",
}

# Findings about spec completeness (useful but not blocking)
COMPLETENESS_CODES = {
    "allium.rule.unreachableTrigger": "UNREACHABLE TRIGGER — rule listens for event no surface provides",
    "allium.field.unused": "UNUSED FIELD — declared but never referenced",
    "allium.definition.unused": "UNUSED DEFINITION — declared but never referenced",
}


def run_analyse(spec_path: Path, cwd: Path) -> dict:
    result = subprocess.run(
        ["allium", "analyse", str(spec_path)],
        capture_output=True, text=True, cwd=cwd,
    )
    # allium exit codes: 0 = no findings, 1 = findings produced, 2 = usage error
    if result.returncode not in (0, 1):
        sys.exit(
            f"allium analyse failed (exit {result.returncode})\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        sys.exit(
            f"allium analyse emitted non-JSON output\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )


def classify(diagnostics: list) -> tuple[list, list, list]:
    """Split diagnostics into (state_machine, completeness, other)."""
    sm, comp, other = [], [], []
    for d in diagnostics:
        code = d.get("code", "")
        if code in STATE_MACHINE_CODES:
            sm.append(d)
        elif code in COMPLETENESS_CODES:
            comp.append(d)
        else:
            other.append(d)
    return sm, comp, other


def format_finding(d: dict, labels: dict) -> str:
    code = d.get("code", "?")
    label = labels.get(code, code)
    loc = d["location"]
    return f"  {label}\n    {loc['file']}:{loc['line']} — {d['message']}"


def main():
    cfg = load_config(sys.argv)
    positional = positional_args(sys.argv)
    spec_path = Path(positional[0]).resolve() if positional else cfg["spec"]
    if not spec_path.exists():
        print(f"Spec not found: {spec_path}", file=sys.stderr)
        sys.exit(1)

    data = run_analyse(spec_path, cfg["root"])
    diagnostics = data.get("diagnostics", [])
    sm, comp, other = classify(diagnostics)

    # State machine issues — these need decisions
    if sm:
        print(f"STATE MACHINE ISSUES ({len(sm)}):")
        print("Each needs a decision: fix the spec or confirm as design intent.\n")
        for d in sm:
            print(format_finding(d, STATE_MACHINE_CODES))
            print()
    else:
        print("STATE MACHINE: no issues found.\n")

    # Completeness — useful signals
    # Filter to just unreachable triggers (unused fields are noise)
    triggers = [d for d in comp if "unreachableTrigger" in d.get("code", "")]
    if triggers:
        print(f"UNREACHABLE TRIGGERS ({len(triggers)}):")
        print("Rules that listen for events no surface provides — may need surface updates.\n")
        for d in triggers:
            print(f"  {d['message']}")
        print()

    # Summary
    errors = [d for d in diagnostics if d["severity"] == "error"]
    if errors:
        print(f"ERRORS ({len(errors)}): spec has syntax/type errors, fix before proceeding.")
        for d in errors:
            print(f"  {d['location']['file']}:{d['location']['line']} — {d['message']}")
        sys.exit(1)

    print(f"Summary: {len(sm)} state machine issues, {len(triggers)} unreachable triggers, {len(errors)} errors")
    sys.exit(1 if sm else 0)


if __name__ == "__main__":
    main()
