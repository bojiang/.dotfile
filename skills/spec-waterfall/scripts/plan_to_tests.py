#!/usr/bin/env python3
"""
Generate pytest skeletons from Allium plan obligations.
Filters to E2E-relevant categories, maps each obligation to a test function.

Project-specific knowledge (spec path, tests dir, rule/entity layer maps, tier
maps) comes from spec-waterfall.json — see the spec-waterfall skill.

Usage:
    plan_to_tests.py [spec_path] [--config path]   # print summary to stdout
    plan_to_tests.py --write                       # write test files + refresh README coverage
    plan_to_tests.py --diff                        # show what changed vs existing
    plan_to_tests.py --readme                      # refresh README coverage block only
"""
import hashlib
import json
import subprocess
import sys
import re
from pathlib import Path
from collections import defaultdict

from _config import load_config, positional_args

# Categories that produce meaningful E2E tests
E2E_CATEGORIES = {
    "rule_success",
    "rule_failure",
    "transition_edge",
    "transition_rejected",
    "transition_terminal",
    "when_presence",
    "when_clear",
    "invariant",
    "temporal",
    "surface_provides",
    "surface_exposure",
}

TIERS = ("seconds", "minutes", "hours")


def obligation_tier(ob: dict, cfg: dict) -> str:
    """Expected wall-clock tier: seconds (default) / minutes (out-of-band) / hours (temporal)."""
    if ob["category"] == "temporal":
        return "hours"
    deps = ob.get("dependencies") or {}
    dep_entities = set()
    for key in ("entities_created", "entities_read", "entities_written"):
        dep_entities.update(deps.get(key) or [])
    for entity, tier in cfg["tiers"]["entities"].items():
        if entity in dep_entities or entity in ob["id"]:
            return tier
    return "seconds"


def run_plan(spec_path: Path, cwd: Path) -> dict:
    result = subprocess.run(
        ["allium", "plan", str(spec_path)],
        capture_output=True, text=True, cwd=cwd,
    )
    if result.returncode != 0:
        sys.exit(
            f"allium plan failed (exit {result.returncode})\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        sys.exit(
            f"allium plan emitted non-JSON output\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )


def obligation_layer(ob: dict, cfg: dict) -> str:
    """Map an obligation to its test layer via the config's rule/entity maps."""
    desc = ob.get("description", "")
    ob_id = ob.get("id", "")
    layers = cfg["layers"]

    # Rule-based obligations
    for rule_name, layer in layers["rules"].items():
        if rule_name in ob_id or rule_name in desc:
            return layer

    # Entity-based obligations (transition, when)
    for entity, layer in layers["entities"].items():
        if entity in ob_id or entity in desc:
            return layer

    # Surface obligations
    if ob["category"].startswith("surface"):
        return layers["surfaces"]

    return layers["default"]


def obligation_to_test_name(ob: dict) -> str:
    """Generate a pytest function name from an obligation."""
    ob_id = ob["id"]
    # Clean up: rule-failure.UserSignsUp.1 → test_rule_failure_user_signs_up_1
    name = ob_id.replace(".", "_").replace("-", "_")
    name = re.sub(r'([A-Z])', r'_\1', name).lower().strip("_")
    name = re.sub(r'_+', '_', name)
    return f"test_{name}"


def obligation_to_docstring(ob: dict) -> str:
    """Generate a docstring from obligation description + spec ref."""
    return f'"""Obligation {ob["id"]}: {ob["description"]}"""'


def obligation_to_test_body(ob: dict) -> str:
    """Generate test body based on category."""
    cat = ob["category"]
    if cat == "rule_success":
        return "    # TODO: set up preconditions, invoke action, assert postconditions\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "rule_failure":
        return "    # TODO: violate one requires clause, assert rejection\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "transition_edge":
        return "    # TODO: put entity in source state, trigger transition, assert target state\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "transition_rejected":
        return "    # TODO: attempt undeclared transition, assert rejection\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "transition_terminal":
        return "    # TODO: put entity in terminal state, assert no outbound transitions possible\n    pytest.skip('skeleton — needs implementation')"
    elif cat in ("when_presence", "when_clear"):
        return "    # TODO: put entity in qualifying state, assert field present/absent\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "invariant":
        return "    # TODO: set up state, apply rules, assert invariant holds\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "temporal":
        return "    # TODO: advance past deadline, assert rule fires\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "surface_provides":
        return "    # TODO: verify operation available when guard true, hidden when false\n    pytest.skip('skeleton — needs implementation')"
    elif cat == "surface_exposure":
        return "    # TODO: verify each exposed field is accessible\n    pytest.skip('skeleton — needs implementation')"
    else:
        return "    pytest.skip('skeleton — needs implementation')"


def obligation_hash(ob: dict) -> str:
    """Hash an obligation's semantic content — changes when the spec rule changes."""
    key = f"{ob['id']}:{ob['category']}:{ob['description']}"
    return hashlib.sha256(key.encode()).hexdigest()[:12]


def load_manifest(manifest_path: Path) -> dict:
    """Load previous obligation manifest {test_name: {id, hash}}."""
    if manifest_path.exists():
        return json.loads(manifest_path.read_text())
    return {}


def build_manifest(obligations: list) -> dict:
    """Build obligation manifest with hashes that detect precondition changes."""
    # Count failure obligations per rule — a proxy for requires clause count
    failure_counts = defaultdict(int)
    for ob in obligations:
        if ob["category"] == "rule_failure":
            rule_name = ob["id"].rsplit(".", 1)[0]  # rule-failure.RuleName
            failure_counts[rule_name] += 1

    manifest = {}
    for ob in obligations:
        test_name = obligation_to_test_name(ob)
        # For success obligations, include failure count in hash
        # so that adding/removing a requires changes the success hash too
        extra = ""
        if ob["category"] == "rule_success":
            rule_key = f"rule-failure.{ob['id'].split('.', 1)[1]}"
            extra = f":failures={failure_counts.get(rule_key, 0)}"
        key = f"{ob['id']}:{ob['category']}:{ob['description']}{extra}"
        h = hashlib.sha256(key.encode()).hexdigest()[:12]
        manifest[test_name] = {"id": ob["id"], "hash": h}
    return manifest


README_BEGIN = "<!-- BEGIN GENERATED COVERAGE (plan_to_tests.py --readme) -->"
README_END = "<!-- END GENERATED COVERAGE -->"


def readme_scaffold(cfg: dict) -> str:
    try:
        spec_rel = cfg["spec"].relative_to(cfg["root"])
    except ValueError:
        spec_rel = cfg["spec"]
    return f"""# Autonomous QA

Spec-driven E2E suite. Test skeletons are generated from
`{spec_rel}` obligations by `plan_to_tests.py`
(see the spec-waterfall skill for the full pipeline).

## Layout

- `test_gen_<layer>.py` — generated skeletons, one test per obligation.
  Implement the TODO body, remove the `pytest.skip`, keep the function name
  (it is the obligation link).
- Other `test_*.py` — handwritten tests, not tracked by the coverage table
  below.
- `.obligation_manifest.json` — obligation → test mapping with drift hashes
  (`plan_to_tests.py --diff`).

## Execution tiers

Every generated test carries exactly one tier marker for expected wall-clock:

- `seconds` — synchronous request/response assertions (default lane)
- `minutes` — out-of-band pipeline assertions (async propagation)
- `hours` — temporal obligations (deadline-driven rules)

Tier assignment lives in `spec-waterfall.json` (`tiers.entities`), not in the
spec.

## Run

- `uv run pytest -m "not minutes and not hours"` — default lane
- `uv run pytest -m minutes` / `-m hours` — slow lanes
- `uv run pytest` — everything

## Coverage

Everything between the markers below is generated by
`plan_to_tests.py --readme` (also refreshed by `--write`).
Do not edit the numbers by hand.

{README_BEGIN}
{README_END}
"""


def spec_sections(spec_text: str) -> list:
    """Extract (offset, title) for each banner-comment section header in the spec."""
    sections = []
    for m in re.finditer(r"^-- =+\n-- (.+?)\n-- =+$", spec_text, re.MULTILINE):
        title = m.group(1).strip()
        title = re.sub(r"^RULES:\s*", "", title)
        if title.isupper():
            title = title.capitalize()
        sections.append((m.start(), title))
    return sections


def obligation_domain(ob: dict, sections: list) -> str:
    """Map an obligation to its spec section via source_span offset."""
    start = (ob.get("source_span") or {}).get("start", 0)
    domain = "(unsectioned)"
    for offset, title in sections:
        if offset <= start:
            domain = title
        else:
            break
    return domain


def parse_test_status(path: Path) -> dict:
    """Parse a generated test file → {test_name: 'implemented' | 'skipped'}."""
    if not path.exists():
        return {}
    text = path.read_text()
    status = {}
    matches = list(re.finditer(r"def (test_\w+)\(", text))
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[m.start():end]
        skipped = "skeleton — needs implementation" in body
        status[m.group(1)] = "skipped" if skipped else "implemented"
    return status


def build_readme_block(all_obs: list, e2e_obs: list, cfg: dict) -> str:
    """Render the generated coverage block (markers included)."""
    sections = spec_sections(cfg["spec"].read_text())
    test_status = {}
    for layer in cfg["layer_names"]:
        test_status.update(parse_test_status(cfg["tests_dir"] / f"test_gen_{layer}.py"))

    rows = {}
    for ob in e2e_obs:
        domain = obligation_domain(ob, sections)
        row = rows.setdefault(domain, defaultdict(int))
        row["obligations"] += 1
        row[obligation_tier(ob, cfg)] += 1
        st = test_status.get(obligation_to_test_name(ob))
        if st:
            row["skeletons"] += 1
            row[st] += 1

    lines = [
        README_BEGIN,
        "",
        f"Spec: `{cfg['spec'].name}` — {len(all_obs)} obligations total, "
        f"{len(e2e_obs)} E2E-relevant (skeleton-generated).",
        "",
        "| Domain | Obligations | Skeletons | Implemented | Skipped | seconds | minutes | hours |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    total = defaultdict(int)
    for domain, row in rows.items():
        for k, v in row.items():
            total[k] += v
        lines.append(
            f"| {domain} | {row['obligations']} | {row['skeletons']} | "
            f"{row['implemented']} | {row['skipped']} | "
            f"{row['seconds']} | {row['minutes']} | {row['hours']} |"
        )
    lines.append(
        f"| **Total** | {total['obligations']} | {total['skeletons']} | "
        f"{total['implemented']} | {total['skipped']} | "
        f"{total['seconds']} | {total['minutes']} | {total['hours']} |"
    )
    lines.append("")
    lines.append(README_END)
    return "\n".join(lines)


def write_readme(block: str, cfg: dict):
    """Replace the generated block in README.md, creating it from scaffold if absent."""
    readme_path = cfg["tests_dir"] / "README.md"
    if readme_path.exists():
        text = readme_path.read_text()
        if README_BEGIN not in text or README_END not in text:
            sys.exit(f"{readme_path} exists but lacks coverage markers; refusing to overwrite")
        pre = text.split(README_BEGIN)[0]
        post = text.split(README_END, 1)[1]
        readme_path.write_text(pre + block + post)
    else:
        readme_path.write_text(
            readme_scaffold(cfg).replace(f"{README_BEGIN}\n{README_END}", block)
        )
    print(f"Wrote {readme_path}")


def generate_test_file(layer: str, obligations: list, cfg: dict) -> str:
    """Generate a complete test file for a set of obligations."""
    lines = [
        f'"""',
        f'Auto-generated test skeletons from Allium spec obligations.',
        f'Layer: {layer}',
        f'Generated by plan_to_tests.py — do not edit obligation mapping manually.',
        f'Implement the TODO bodies, then remove the pytest.skip().',
        f'"""',
        f'import pytest',
        f'',
    ]

    # Group by rule/entity
    groups = defaultdict(list)
    for ob in obligations:
        # Extract group name from obligation id
        parts = ob["id"].split(".")
        group = parts[1] if len(parts) > 1 else parts[0]
        groups[group].append(ob)

    for group_name, obs in groups.items():
        # Capitalize word starts without lowercasing the rest ("ApiKey" -> "TestApiKey",
        # not str.title()'s "TestApikey").
        words = re.split(r"[_\-\s]+", group_name)
        class_name = "Test" + "".join(w[:1].upper() + w[1:] for w in words if w)
        lines.append(f"")
        lines.append(f"class {class_name}:")
        for ob in obs:
            test_name = obligation_to_test_name(ob)
            docstring = obligation_to_docstring(ob)
            body = obligation_to_test_body(ob)
            lines.append(f"")
            lines.append(f"    @pytest.mark.{obligation_tier(ob, cfg)}")
            lines.append(f"    def {test_name}(self):")
            lines.append(f"        {docstring}")
            # Body templates carry a 4-space indent; add 4 more to sit inside
            # the method (class 4 + def body 8).
            for body_line in body.splitlines():
                lines.append(f"    {body_line}")

    return "\n".join(lines) + "\n"


def main():
    cfg = load_config(sys.argv)
    positional = positional_args(sys.argv)
    spec_path = Path(positional[0]).resolve() if positional else cfg["spec"]
    cfg["spec"] = spec_path
    manifest_path = cfg["tests_dir"] / ".obligation_manifest.json"
    write_mode = "--write" in sys.argv
    diff_mode = "--diff" in sys.argv
    readme_mode = "--readme" in sys.argv

    data = run_plan(spec_path, cfg["root"])
    all_obs = data.get("obligations", [])

    # Filter to E2E-relevant
    e2e_obs = [ob for ob in all_obs if ob["category"] in E2E_CATEGORIES]

    # Split by layer
    by_layer = defaultdict(list)
    for ob in e2e_obs:
        by_layer[obligation_layer(ob, cfg)].append(ob)

    print(f"Total obligations: {len(all_obs)}")
    print(f"E2E-relevant: {len(e2e_obs)} (filtered from {len(all_obs)})")
    for layer in cfg["layer_names"]:
        print(f"  {layer} layer: {len(by_layer[layer])}")
    print()

    # Category breakdown of what we're generating
    cats = defaultdict(int)
    for ob in e2e_obs:
        cats[ob["category"]] += 1
    print("By category:")
    for cat, count in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"  {cat}: {count}")
    print()

    tiers = defaultdict(int)
    for ob in e2e_obs:
        tiers[obligation_tier(ob, cfg)] += 1
    print("By tier:")
    for tier in TIERS:
        print(f"  {tier}: {tiers[tier]}")
    print()

    contents = {
        layer: generate_test_file(layer, by_layer[layer], cfg)
        for layer in cfg["layer_names"]
    }

    if write_mode:
        cfg["tests_dir"].mkdir(parents=True, exist_ok=True)
        for layer, content in contents.items():
            path = cfg["tests_dir"] / f"test_gen_{layer}.py"
            path.write_text(content)
            print(f"Wrote {path} ({len(by_layer[layer])} obligations)")
        manifest_path.write_text(json.dumps(build_manifest(e2e_obs), indent=2) + "\n")
        print(f"Wrote {manifest_path}")
        write_readme(build_readme_block(all_obs, e2e_obs, cfg), cfg)
    elif readme_mode:
        write_readme(build_readme_block(all_obs, e2e_obs, cfg), cfg)
    elif diff_mode:
        old_manifest = load_manifest(manifest_path)
        new_manifest = build_manifest(e2e_obs)

        old_names = set(old_manifest.keys())
        new_names = set(new_manifest.keys())
        added = new_names - old_names
        removed = old_names - new_names
        modified = {
            name for name in old_names & new_names
            if old_manifest[name]["hash"] != new_manifest[name]["hash"]
        }

        if not old_manifest:
            print("No manifest found. Run --write first to establish baseline.")
        elif not added and not removed and not modified:
            print("No changes.")
        else:
            if added:
                for t in sorted(added):
                    print(f"  + {t}  ({new_manifest[t]['id']})")
            if modified:
                for t in sorted(modified):
                    print(f"  ~ {t}  ({new_manifest[t]['id']} — preconditions changed)")
            if removed:
                for t in sorted(removed):
                    print(f"  - {t}  ({old_manifest[t]['id']})")
            print(f"\n  {len(added)} added, {len(modified)} modified, {len(removed)} removed")
    else:
        # Print summary only
        print("Would generate:")
        for layer, content in contents.items():
            count = len(re.findall(r'def (test_\w+)', content))
            print(f"  test_gen_{layer}.py: {count} test functions")
        print()
        print("Run with --write to generate files, --diff to compare with existing.")


if __name__ == "__main__":
    main()
