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
import ast
import hashlib
import json
import subprocess
import sys
import re
import textwrap
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
        return "# TODO: set up preconditions, invoke action, assert postconditions\npytest.skip('skeleton — needs implementation')"
    elif cat == "rule_failure":
        return "# TODO: violate one requires clause, assert rejection\npytest.skip('skeleton — needs implementation')"
    elif cat == "transition_edge":
        return "# TODO: put entity in source state, trigger transition, assert target state\npytest.skip('skeleton — needs implementation')"
    elif cat == "transition_rejected":
        return "# TODO: attempt undeclared transition, assert rejection\npytest.skip('skeleton — needs implementation')"
    elif cat == "transition_terminal":
        return "# TODO: put entity in terminal state, assert no outbound transitions possible\npytest.skip('skeleton — needs implementation')"
    elif cat in ("when_presence", "when_clear"):
        return "# TODO: put entity in qualifying state, assert field present/absent\npytest.skip('skeleton — needs implementation')"
    elif cat == "invariant":
        return "# TODO: set up state, apply rules, assert invariant holds\npytest.skip('skeleton — needs implementation')"
    elif cat == "temporal":
        return "# TODO: advance past deadline, assert rule fires\npytest.skip('skeleton — needs implementation')"
    elif cat == "surface_provides":
        return "# TODO: verify operation available when guard true, hidden when false\npytest.skip('skeleton — needs implementation')"
    elif cat == "surface_exposure":
        return "# TODO: verify each exposed field is accessible\npytest.skip('skeleton — needs implementation')"
    else:
        return "pytest.skip('skeleton — needs implementation')"


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

- `test_gen_<layer>_<group>.py` — generated skeletons, one small file per
  obligation group and one test per obligation.
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


def generated_test_paths(tests_dir: Path) -> list[Path]:
    """Return only files owned by this generator."""
    paths = []
    for path in sorted(tests_dir.glob("test_gen_*.py")):
        if "Auto-generated test skeletons from Allium spec obligations." in path.read_text()[:500]:
            paths.append(path)
    return paths


def build_readme_block(all_obs: list, e2e_obs: list, cfg: dict) -> str:
    """Render the generated coverage block (markers included)."""
    sections = spec_sections(cfg["spec"].read_text())
    test_status = {}
    for path in generated_test_paths(cfg["tests_dir"]):
        test_status.update(parse_test_status(path))

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


def obligation_group(ob: dict) -> str:
    parts = ob["id"].split(".")
    return parts[1] if len(parts) > 1 else parts[0]


def snake_name(value: str) -> str:
    value = re.sub(r"([A-Z])", r"_\1", value).lower().strip("_")
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return re.sub(r"_+", "_", value).strip("_")


def class_name(group: str) -> str:
    words = re.split(r"[_\-\s]+", group)
    return "Test" + "".join(word[:1].upper() + word[1:] for word in words if word)


def generated_test_filename(layer: str, group: str) -> str:
    return f"test_gen_{snake_name(layer)}_{snake_name(group)}.py"


def _indent(text: str, spaces: int) -> list[str]:
    prefix = " " * spaces
    return [prefix + line if line else "" for line in text.splitlines()]


def _is_tier_decorator(source: str) -> bool:
    return source in {f"pytest.mark.{tier}" for tier in TIERS}


def load_preserved_tests(tests_dir: Path) -> dict:
    """Read editable function details without retaining generated mapping text."""
    preserved = {}
    for path in generated_test_paths(tests_dir):
        source = path.read_text()
        lines = source.splitlines()
        tree = ast.parse(source, filename=str(path))
        nodes = [
            node
            for container in tree.body
            if isinstance(container, ast.ClassDef)
            for node in container.body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
        ]
        for node in nodes:
            if not node.name.startswith("test_") or not node.body or node.end_lineno is None:
                continue
            first = node.body[0]
            is_docstring = (
                isinstance(first, ast.Expr)
                and isinstance(first.value, ast.Constant)
                and isinstance(first.value.value, str)
            )
            body_start = first.end_lineno if is_docstring else first.lineno - 1
            header = textwrap.dedent(
                "\n".join(lines[node.lineno - 1:first.lineno - 1])
            ).rstrip()
            body = textwrap.dedent(
                "\n".join(lines[body_start:node.end_lineno])
            ).rstrip()
            decorators = []
            for decorator in node.decorator_list:
                decorator_source = ast.get_source_segment(source, decorator)
                if decorator_source and not _is_tier_decorator(decorator_source):
                    decorators.append(decorator_source)
            if node.name in preserved:
                sys.exit(f"Duplicate generated test function: {node.name}")
            preserved[node.name] = {
                "header": header,
                "body": body,
                "decorators": decorators,
            }
    return preserved


def preservable_tests(old_manifest: dict, new_manifest: dict, existing: dict) -> dict:
    return {
        name: existing[name]
        for name in existing.keys() & old_manifest.keys() & new_manifest.keys()
        if old_manifest[name].get("hash") == new_manifest[name].get("hash")
    }


def generate_test_file(
    layer: str,
    group: str,
    obligations: list,
    cfg: dict,
    preserved: dict,
) -> str:
    """Generate one small test file for one obligation group."""
    lines = [
        f'"""',
        f'Auto-generated test skeletons from Allium spec obligations.',
        f'Layer: {layer}',
        f'Group: {group}',
        f'Generated by plan_to_tests.py — do not edit obligation mapping manually.',
        f'Implement the TODO bodies, then remove the pytest.skip().',
        f'"""',
        f'import pytest',
        f'',
    ]

    lines.append("")
    lines.append(f"class {class_name(group)}:")
    for ob in obligations:
        test_name = obligation_to_test_name(ob)
        prior = preserved.get(test_name, {})
        header = prior.get("header") or f"def {test_name}(self):"
        body = prior.get("body") or obligation_to_test_body(ob)
        lines.append("")
        for decorator in prior.get("decorators", []):
            lines.extend(_indent(f"@{decorator}", 4))
        lines.append(f"    @pytest.mark.{obligation_tier(ob, cfg)}")
        lines.extend(_indent(header, 4))
        lines.append(f"        {obligation_to_docstring(ob)}")
        lines.extend(_indent(body, 8))

    return "\n".join(lines) + "\n"


def build_test_outputs(e2e_obs: list, cfg: dict, preserved: dict) -> dict[Path, str]:
    grouped = defaultdict(list)
    for ob in e2e_obs:
        grouped[(obligation_layer(ob, cfg), obligation_group(ob))].append(ob)
    outputs = {}
    for (layer, group), obligations in grouped.items():
        path = cfg["tests_dir"] / generated_test_filename(layer, group)
        if path in outputs:
            sys.exit(f"Generated test filename collision: {path.name}")
        outputs[path] = generate_test_file(layer, group, obligations, cfg, preserved)
    return outputs


def write_test_outputs(tests_dir: Path, outputs: dict[Path, str]) -> list[Path]:
    stale = set(generated_test_paths(tests_dir)) - outputs.keys()
    for path, content in outputs.items():
        path.write_text(content)
    for path in stale:
        path.unlink()
    return sorted(stale)


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

    new_manifest = build_manifest(e2e_obs)

    if write_mode:
        cfg["tests_dir"].mkdir(parents=True, exist_ok=True)
        old_manifest = load_manifest(manifest_path)
        existing = load_preserved_tests(cfg["tests_dir"])
        preserved = preservable_tests(old_manifest, new_manifest, existing)
        outputs = build_test_outputs(e2e_obs, cfg, preserved)
        stale = write_test_outputs(cfg["tests_dir"], outputs)
        manifest_path.write_text(json.dumps(new_manifest, indent=2) + "\n")
        print(
            f"Wrote {len(outputs)} generated test files for {len(e2e_obs)} obligations; "
            f"preserved {len(preserved)} bodies; removed {len(stale)} stale files"
        )
        print(f"Wrote {manifest_path}")
        write_readme(build_readme_block(all_obs, e2e_obs, cfg), cfg)
    elif readme_mode:
        write_readme(build_readme_block(all_obs, e2e_obs, cfg), cfg)
    elif diff_mode:
        old_manifest = load_manifest(manifest_path)
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
        outputs = build_test_outputs(e2e_obs, cfg, {})
        print("Would generate:")
        print(f"  {len(outputs)} grouped test files: {len(e2e_obs)} test functions")
        print()
        print("Run with --write to generate files, --diff to compare with existing.")


if __name__ == "__main__":
    main()
