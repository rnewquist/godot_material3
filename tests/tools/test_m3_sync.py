#!/usr/bin/env python3
"""
test_m3_sync.py
Unit and Integration Test Suite for Material 3 Godot Universal Sync Tooling (tools/m3_sync.py).
"""

import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path

# Add tools directory to Python path
ROOT_DIR = Path(__file__).resolve().parent.parent.parent
sys_path_tools = ROOT_DIR / "tools"
import sys
sys.path.insert(0, str(sys_path_tools))

from m3_sync import (
    ProjectRegistry,
    check_git_dirty,
    ensure_git_exclude,
    sync_project
)


class TestProjectRegistry(unittest.TestCase):
    """Tests project registry loading, environment expansion, and fallback resolution."""

    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp(prefix="m3_test_registry_"))
        self.config_file = self.temp_dir / ".m3_projects.json"

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_load_default_projects_when_no_file(self):
        registry = ProjectRegistry(workspace_root=self.temp_dir, registry_file="nonexistent.json")
        self.assertIn("material3", registry.projects_dict)
        self.assertIn("guildmaster", registry.projects_dict)

    def test_load_custom_config_file(self):
        custom_data = {
            "version": "1.0",
            "canonical_source": "addons/material3",
            "projects": {
                "custom_app": {
                    "path": str(self.temp_dir / "custom_app"),
                    "description": "Custom Test App"
                }
            }
        }
        self.config_file.write_text(json.dumps(custom_data), encoding="utf-8")
        registry = ProjectRegistry(workspace_root=self.temp_dir, registry_file=".m3_projects.json")
        self.assertIn("custom_app", registry.projects_dict)
        self.assertEqual(registry.canonical_source_str, "addons/material3")

    def test_path_resolution_with_env_vars_and_home(self):
        os.environ["M3_TEST_VAR"] = str(self.temp_dir)
        registry = ProjectRegistry(workspace_root=self.temp_dir)
        
        resolved = registry.resolve_raw_path("$M3_TEST_VAR/subfolder")
        expected = (self.temp_dir / "subfolder").resolve()
        self.assertEqual(resolved.resolve(), expected.resolve())

        resolved_home = registry.resolve_raw_path("~/m3_test_unique_path_12345")
        self.assertTrue(str(resolved_home).startswith(str(Path.home())))

    def test_path_resolution_fallbacks(self):
        existing_fallback = self.temp_dir / "fallback_dir"
        existing_fallback.mkdir()
        
        registry = ProjectRegistry(workspace_root=self.temp_dir)
        resolved = registry.resolve_raw_path(
            "/nonexistent/primary/path",
            fallbacks=["/another/nonexistent", str(existing_fallback)]
        )
        self.assertEqual(resolved.resolve(), existing_fallback.resolve())


class TestGitSafetyAndExclude(unittest.TestCase):
    """Tests git exclude registration and dirty working tree checks."""

    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp(prefix="m3_test_git_"))
        self.git_dir = self.temp_dir / ".git"
        self.git_dir.mkdir()

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_ensure_git_exclude_creation_and_idempotency(self):
        exclude_file = self.git_dir / "info" / "exclude"
        
        # 1. First addition
        added = ensure_git_exclude(self.temp_dir, "addons/material3", dry_run=False)
        self.assertTrue(added)
        self.assertTrue(exclude_file.exists())
        content = exclude_file.read_text(encoding="utf-8")
        self.assertIn("addons/material3", content)

        # 2. Second addition should be no-op
        added_again = ensure_git_exclude(self.temp_dir, "addons/material3", dry_run=False)
        self.assertFalse(added_again)

    def test_ensure_git_exclude_dry_run_does_not_modify(self):
        exclude_file = self.git_dir / "info" / "exclude"
        added = ensure_git_exclude(self.temp_dir, "addons/material3", dry_run=True)
        self.assertTrue(added)
        self.assertFalse(exclude_file.exists())

    def test_check_git_dirty_on_non_git_project(self):
        non_git = self.temp_dir / "non_git_subproject"
        non_git.mkdir()
        is_dirty, output = check_git_dirty(non_git, "addons/material3")
        self.assertFalse(is_dirty)
        self.assertEqual(output, "")


class TestSyncProject(unittest.TestCase):
    """Tests sync_project in copy, link, unlink, and dry-run modes."""

    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp(prefix="m3_test_sync_"))
        
        # Create canonical source
        self.canonical_source = self.temp_dir / "canonical_addons" / "material3"
        self.canonical_source.mkdir(parents=True)
        (self.canonical_source / "plugin.cfg").write_text("[plugin]\nname=\"Material3\"\n", encoding="utf-8")
        (self.canonical_source / "m3_core.gd").write_text("# Core Material3\n", encoding="utf-8")

        # Create target consumer project
        self.consumer_project = self.temp_dir / "consumer_project"
        self.consumer_project.mkdir()
        (self.consumer_project / ".git").mkdir()

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_sync_copy_mode(self):
        ok = sync_project(
            project_name="consumer",
            project_path=self.consumer_project,
            canonical_source=self.canonical_source,
            mode="copy",
            dry_run=False
        )
        self.assertTrue(ok)
        target_addon = self.consumer_project / "addons" / "material3"
        self.assertTrue(target_addon.exists())
        self.assertFalse(target_addon.is_symlink())
        self.assertTrue((target_addon / "plugin.cfg").exists())
        self.assertTrue((target_addon / "m3_core.gd").exists())

    def test_sync_link_and_unlink_mode(self):
        # 1. Link Mode
        ok_link = sync_project(
            project_name="consumer",
            project_path=self.consumer_project,
            canonical_source=self.canonical_source,
            mode="link",
            dry_run=False
        )
        self.assertTrue(ok_link)
        target_addon = self.consumer_project / "addons" / "material3"
        self.assertTrue(target_addon.exists())
        self.assertTrue(target_addon.is_symlink())
        self.assertEqual(target_addon.resolve(), self.canonical_source.resolve())

        # 2. Unlink Mode
        ok_unlink = sync_project(
            project_name="consumer",
            project_path=self.consumer_project,
            canonical_source=self.canonical_source,
            mode="unlink",
            dry_run=False
        )
        self.assertTrue(ok_unlink)
        self.assertTrue(target_addon.exists())
        self.assertFalse(target_addon.is_symlink())
        self.assertTrue((target_addon / "plugin.cfg").exists())

    def test_sync_dry_run_mode_creates_no_files(self):
        ok = sync_project(
            project_name="consumer",
            project_path=self.consumer_project,
            canonical_source=self.canonical_source,
            mode="copy",
            dry_run=True
        )
        self.assertTrue(ok)
        target_addon = self.consumer_project / "addons" / "material3"
        self.assertFalse(target_addon.exists())

    def test_sync_self_skip(self):
        # When project target is the canonical source itself
        ok = sync_project(
            project_name="self",
            project_path=self.canonical_source.parent.parent,
            canonical_source=self.canonical_source,
            mode="copy",
            dry_run=False
        )
        self.assertTrue(ok)


if __name__ == "__main__":
    unittest.main()
