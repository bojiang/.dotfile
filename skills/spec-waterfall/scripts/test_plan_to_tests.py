import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest import mock

import plan_to_tests as subject


def obligation(ob_id="rule-success.Register", description="Register succeeds"):
    return {
        "id": ob_id,
        "category": "rule_success",
        "description": description,
    }


def config(tests_dir):
    return {
        "tests_dir": tests_dir,
        "layers": {
            "default": "api",
            "surfaces": "browser",
            "rules": {},
            "entities": {},
        },
        "tiers": {"entities": {}},
        "e2e": {"exclude_ids": []},
    }


class PlanToTestsTest(unittest.TestCase):
    def test_outputs_one_small_file_per_group(self):
        with tempfile.TemporaryDirectory() as directory:
            cfg = config(Path(directory))
            obligations = [
                obligation(),
                obligation("rule-success.Login", "Login succeeds"),
            ]

            outputs = subject.build_test_outputs(obligations, cfg, {})

            self.assertEqual(
                {path.name for path in outputs},
                {"test_gen_api_register.py", "test_gen_api_login.py"},
            )

    def test_surface_guarantees_get_one_file_per_surface_and_guarantee(self):
        with tempfile.TemporaryDirectory() as directory:
            cfg = config(Path(directory))
            obligations = [
                {
                    "id": "surface-guarantee.Console.SetupProgress",
                    "category": "surface_guarantee",
                    "description": "Console reports setup progress",
                },
                {
                    "id": "surface-guarantee.Console.NoExistenceLeak",
                    "category": "surface_guarantee",
                    "description": "Console does not leak existence",
                },
            ]

            outputs = subject.build_test_outputs(obligations, cfg, {})

            self.assertEqual(
                {path.name for path in outputs},
                {
                    "test_gen_browser_console_no_existence_leak.py",
                    "test_gen_browser_console_setup_progress.py",
                },
            )

    def test_e2e_exclude_ids_removes_only_exact_obligation(self):
        cfg = config(Path("tests"))
        cfg["e2e"]["exclude_ids"] = ["surface-guarantee.Console.InternalOnly"]
        obligations = [
            obligation(),
            {
                "id": "surface-guarantee.Console.InternalOnly",
                "category": "surface_guarantee",
                "description": "Not publicly observable",
            },
            {
                "id": "surface-guarantee.Console.PublicResult",
                "category": "surface_guarantee",
                "description": "Publicly observable",
            },
        ]

        selected = subject.e2e_obligations(obligations, cfg)

        self.assertEqual(
            [ob["id"] for ob in selected],
            ["rule-success.Register", "surface-guarantee.Console.PublicResult"],
        )

    def test_e2e_exclude_ids_rejects_unknown_obligation(self):
        cfg = config(Path("tests"))
        cfg["e2e"]["exclude_ids"] = ["surface-guarantee.Console.Misspelled"]

        with self.assertRaises(SystemExit) as raised:
            subject.e2e_obligations([obligation()], cfg)

        self.assertIn("unknown obligation IDs", str(raised.exception))

    def test_preserves_unchanged_body_signature_and_custom_decorator(self):
        with tempfile.TemporaryDirectory() as directory:
            tests_dir = Path(directory)
            source = '''"""
Auto-generated test skeletons from Allium spec obligations.
"""
import pytest

class TestRegister:
    @pytest.mark.custom
    @pytest.mark.seconds
    def test_rule_success_register(self, api_client):
        """old generated description"""
        response = api_client.post("/register")
        assert response.status_code == 201
'''
            (tests_dir / "test_gen_api.py").write_text(source)
            ob = obligation()
            manifest = subject.build_manifest([ob])

            existing = subject.load_preserved_tests(tests_dir)
            preserved = subject.preservable_tests(manifest, manifest, existing)
            output = next(iter(subject.build_test_outputs([ob], config(tests_dir), preserved).values()))

            self.assertIn("@pytest.mark.custom", output)
            self.assertEqual(output.count("@pytest.mark.seconds"), 1)
            self.assertIn("def test_rule_success_register(self, api_client):", output)
            self.assertIn('response = api_client.post("/register")', output)
            self.assertIn("Register succeeds", output)
            self.assertNotIn("old generated description", output)

    def test_changed_obligation_returns_to_skeleton(self):
        old = obligation(description="old")
        new = obligation(description="new")
        name = subject.obligation_to_test_name(old)
        existing = {
            name: {
                "header": f"def {name}(self, api_client):",
                "body": "assert api_client",
                "decorators": [],
            }
        }

        preserved = subject.preservable_tests(
            subject.build_manifest([old]),
            subject.build_manifest([new]),
            existing,
        )

        self.assertEqual(preserved, {})

    def test_removes_only_stale_generator_owned_files(self):
        with tempfile.TemporaryDirectory() as directory:
            tests_dir = Path(directory)
            generated = tests_dir / "test_gen_api_old.py"
            generated.write_text(
                '"""Auto-generated test skeletons from Allium spec obligations."""\n'
            )
            handwritten = tests_dir / "test_gen_custom.py"
            handwritten.write_text("def test_custom(): pass\n")
            desired = tests_dir / "test_gen_api_register.py"

            stale = subject.write_test_outputs(tests_dir, {desired: "new\n"})

            self.assertEqual(stale, [generated])
            self.assertFalse(generated.exists())
            self.assertTrue(handwritten.exists())
            self.assertEqual(desired.read_text(), "new\n")

    def test_write_migrates_legacy_file_and_preserves_unchanged_body(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tests_dir = root / "tests"
            tests_dir.mkdir()
            (root / "kernel.allium").write_text("-- spec\n")
            (root / "spec-waterfall.json").write_text(json.dumps({
                "spec": "kernel.allium",
                "tests_dir": "tests",
                "layers": {"default": "api", "surfaces": "browser"},
            }))
            ob = obligation()
            (tests_dir / ".obligation_manifest.json").write_text(
                json.dumps(subject.build_manifest([ob]))
            )
            (tests_dir / "test_gen_api.py").write_text('''"""
Auto-generated test skeletons from Allium spec obligations.
"""
import pytest

class TestRegister:
    @pytest.mark.seconds
    def test_rule_success_register(self, api_client):
        """old description"""
        assert api_client
''')

            previous_cwd = Path.cwd()
            try:
                os.chdir(root)
                with mock.patch.object(subject, "run_plan", return_value={"obligations": [ob]}):
                    with mock.patch.object(sys, "argv", ["plan_to_tests.py", "--write"]):
                        with redirect_stdout(StringIO()):
                            subject.main()
            finally:
                os.chdir(previous_cwd)

            migrated = tests_dir / "test_gen_api_register.py"
            self.assertTrue(migrated.exists())
            self.assertIn("assert api_client", migrated.read_text())
            self.assertFalse((tests_dir / "test_gen_api.py").exists())


if __name__ == "__main__":
    unittest.main()
