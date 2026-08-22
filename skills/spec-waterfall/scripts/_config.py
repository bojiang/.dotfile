"""Per-project configuration for the spec-waterfall pipeline scripts."""
import json
import sys
from pathlib import Path

DEFAULT_CONFIG_NAME = "spec-waterfall.json"


def positional_args(argv: list) -> list:
    """argv minus the program name, flags, and the --config value."""
    args = argv[1:]
    if "--config" in args:
        i = args.index("--config")
        args = args[:i] + args[i + 2:]
    return [a for a in args if not a.startswith("-")]

DEFAULTS = {
    "layers": {"default": "api", "surfaces": "browser", "rules": {}, "entities": {}},
    "tiers": {"entities": {}},
}


def load_config(argv: list) -> dict:
    """Load spec-waterfall.json; resolve paths relative to the config file.

    --config <path> selects the file; default is ./spec-waterfall.json.
    Returns the config dict with resolved `spec` / `tests_dir` Paths and a
    `root` Path (the config file's directory, used as cwd for allium).
    """
    path = Path(DEFAULT_CONFIG_NAME)
    if "--config" in argv:
        path = Path(argv[argv.index("--config") + 1])
    if not path.exists():
        sys.exit(
            f"Config not found: {path.resolve()}\n"
            f"Run from the project root or pass --config <path/to/{DEFAULT_CONFIG_NAME}>"
        )
    cfg = json.loads(path.read_text())
    for key in ("spec", "tests_dir"):
        if key not in cfg:
            sys.exit(f"Config {path} missing required key: {key}")

    root = path.resolve().parent
    cfg["root"] = root
    cfg["spec"] = (root / cfg["spec"]).resolve()
    cfg["tests_dir"] = (root / cfg["tests_dir"]).resolve()

    layers = {**DEFAULTS["layers"], **cfg.get("layers", {})}
    cfg["layers"] = layers
    cfg["tiers"] = {**DEFAULTS["tiers"], **cfg.get("tiers", {})}

    names = {layers["default"], layers["surfaces"]}
    names.update(layers["rules"].values())
    names.update(layers["entities"].values())
    cfg["layer_names"] = sorted(names)
    return cfg
