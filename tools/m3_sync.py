#!/usr/bin/env python3
"""
m3_sync.py
Universal Synchronization & Dev-Link Tooling for the Material 3 Godot Library.
Synchronizes and live-links canonical 'addons/material3/' across consumer Godot projects.

Supported Modes:
  --copy    (Default) Fast, concrete file mirror from canonical source to target projects.
  --link    Cross-platform live symbolic link (POSIX os.symlink on macOS/Linux,
            Directory Junction mklink /J on Windows) for zero-latency local development.
            Automatically adds 'addons/material3' to .git/info/exclude so consumer repos stay clean.
  --unlink  Cleanly restores concrete files from symbolic links before git commits/packaging.
  --git     Executes 'git submodule update --init --remote --merge addons/material3' across projects.
  --dry-run Previews all synchronization actions without modifying the filesystem.
  --force   Bypasses uncommitted Git working tree safety checks.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
CANONICAL_DEFAULT_ADDON = WORKSPACE_ROOT / "addons" / "material3"

# Terminal ANSI color formatting
COLOR_RESET = "\033[0m"
COLOR_BOLD = "\033[1m"
COLOR_RED = "\033[31m"
COLOR_GREEN = "\033[32m"
COLOR_YELLOW = "\033[33m"
COLOR_BLUE = "\033[34m"
COLOR_MAGENTA = "\033[35m"
COLOR_CYAN = "\033[36m"


# ==============================================================================
# PROJECT REGISTRY & PATH RESOLUTION
# ==============================================================================

class ProjectRegistry:
    """Manages project configurations and flexible path resolution with environment expansion."""

    DEFAULT_PROJECTS: Dict[str, Dict[str, Any]] = {
        "material3": {
            "path": str(WORKSPACE_ROOT),
            "fallbacks": [
                "~/Documents/Godot/material3",
                "$HOME/Documents/Godot/material3",
                "../material3",
                "./material3"
            ],
            "description": "Material 3 Design System UI Component Library for Godot 4"
        },
        "guildmaster": {
            "path": str(WORKSPACE_ROOT.parent / "GuildMaster"),
            "fallbacks": [
                "~/Documents/Godot/GuildMaster",
                "$HOME/Documents/Godot/GuildMaster",
                "../GuildMaster",
                "./GuildMaster"
            ],
            "description": "GuildMaster RPG Game Project"
        },
        "tester": {
            "path": str(WORKSPACE_ROOT.parent / "tester"),
            "fallbacks": [
                "~/Documents/Godot/tester",
                "$HOME/Documents/Godot/tester",
                "../tester",
                "./tester"
            ],
            "description": "GDTest 3.0 Test Harness Project"
        },
        "package_material3": {
            "path": "packages/material3",
            "fallbacks": [
                "./packages/material3",
                "packages/material3"
            ],
            "description": "Standalone godot-material3 GitHub Distribution Repository"
        }
    }

    def __init__(self, workspace_root: Optional[Path] = None, registry_file: Optional[str] = None):
        self.workspace_root = (workspace_root or WORKSPACE_ROOT).resolve()
        self.registry_file = registry_file or ".m3_projects.json"
        self.raw_data: Dict[str, Any] = {}
        self.canonical_source_str: str = "addons/material3"
        self.projects_dict: Dict[str, Dict[str, Any]] = {}
        self.load()

    def load(self) -> None:
        """Loads configuration from .m3_projects.json or falls back to built-ins."""
        candidate_paths = [
            self.workspace_root / self.registry_file,
            Path.cwd() / self.registry_file,
            Path.home() / self.registry_file
        ]
        
        found_file = None
        for p in candidate_paths:
            if p.exists() and p.is_file():
                found_file = p
                break
                
        if found_file:
            try:
                with open(found_file, "r", encoding="utf-8") as f:
                    self.raw_data = json.load(f)
                self.canonical_source_str = self.raw_data.get("canonical_source", "addons/material3")
                self.projects_dict = self.raw_data.get("projects", {})
            except Exception as e:
                print(f"{COLOR_YELLOW}⚠️  Warning: Failed to parse {found_file}: {e}. Using defaults.{COLOR_RESET}")
                self.projects_dict = self.DEFAULT_PROJECTS
        else:
            self.projects_dict = self.DEFAULT_PROJECTS

    def resolve_raw_path(self, raw_path: str, fallbacks: Optional[List[str]] = None) -> Path:
        """Resolves path supporting ~, $ENV_VARS, and relative fallbacks."""
        def _expand(p_str: str) -> Path:
            expanded = os.path.expanduser(os.path.expandvars(p_str.strip()))
            p = Path(expanded)
            if not p.is_absolute():
                p = (self.workspace_root / p).resolve()
            return p

        primary = _expand(raw_path)
        if primary.exists():
            return primary
            
        if fallbacks:
            for fb in fallbacks:
                fb_path = _expand(fb)
                if fb_path.exists():
                    return fb_path
                    
        return primary

    def get_canonical_source(self) -> Path:
        """Resolves the canonical Material 3 addon directory."""
        canonical_fallbacks = self.raw_data.get("canonical_source_fallbacks", [
            "./addons/material3",
            "addons/material3",
            "packages/material3/addons/material3"
        ])
        resolved = self.resolve_raw_path(self.canonical_source_str, canonical_fallbacks)
        if not resolved.exists():
            return CANONICAL_DEFAULT_ADDON.resolve()
        return resolved.resolve()

    def get_project_info(self, identifier: str) -> Optional[Tuple[str, Path, Dict[str, Any]]]:
        """Looks up project by name or direct filesystem path."""
        id_lower = identifier.lower().strip()
        for name, config in self.projects_dict.items():
            if name.lower() == id_lower:
                raw_path = config if isinstance(config, str) else config.get("path", name)
                fallbacks = [] if isinstance(config, str) else config.get("fallbacks", [])
                resolved_path = self.resolve_raw_path(raw_path, fallbacks)
                cfg_dict = {"path": str(resolved_path)} if isinstance(config, str) else config
                return (name, resolved_path, cfg_dict)

        direct_path = self.resolve_raw_path(identifier)
        if direct_path.exists():
            return (direct_path.name, direct_path, {"path": str(direct_path)})

        return None

    def get_all_projects(self) -> List[Tuple[str, Path, Dict[str, Any]]]:
        """Returns all registered projects resolved to filesystem paths."""
        results = []
        for name, config in self.projects_dict.items():
            raw_path = config if isinstance(config, str) else config.get("path", name)
            fallbacks = [] if isinstance(config, str) else config.get("fallbacks", [])
            resolved_path = self.resolve_raw_path(raw_path, fallbacks)
            cfg_dict = {"path": str(resolved_path)} if isinstance(config, str) else config
            results.append((name, resolved_path, cfg_dict))
        return results


# ==============================================================================
# GIT SAFETY & EXCLUDE ENGINE
# ==============================================================================

def check_git_dirty(project_path: Path, subpath: str = "addons/material3") -> Tuple[bool, str]:
    """Checks if subpath in git repo has uncommitted modifications."""
    git_dir = project_path / ".git"
    if not git_dir.exists() and not (project_path / ".gitmodules").exists():
        return False, ""
        
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain", subpath],
            cwd=project_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=5
        )
        output = proc.stdout.strip()
        return (len(output) > 0), output
    except Exception:
        return False, ""


def ensure_git_exclude(project_path: Path, pattern: str = "addons/material3", dry_run: bool = False) -> bool:
    """Ensures pattern is present in .git/info/exclude so symlinked addons do not pollute Git."""
    git_dir = project_path / ".git"
    if not git_dir.exists():
        return False

    info_dir = git_dir / "info" if git_dir.is_dir() else None
    if not info_dir:
        try:
            res = subprocess.run(
                ["git", "rev-parse", "--git-path", "info/exclude"],
                cwd=project_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=3
            )
            exclude_path = Path(res.stdout.strip())
            if not exclude_path.is_absolute():
                exclude_path = project_path / exclude_path
        except Exception:
            return False
    else:
        exclude_path = info_dir / "exclude"

    try:
        exclude_path.parent.mkdir(parents=True, exist_ok=True)
        current_content = exclude_path.read_text(encoding="utf-8") if exclude_path.exists() else ""
        lines = [l.strip() for l in current_content.splitlines()]
        
        normalized_pattern = pattern.rstrip("/")
        if normalized_pattern not in lines and f"{normalized_pattern}/" not in lines:
            if not dry_run:
                with open(exclude_path, "a", encoding="utf-8") as f:
                    if current_content and not current_content.endswith("\n"):
                        f.write("\n")
                    f.write(f"\n# Material 3 canonical symlink exclusion\n{pattern}\n")
            return True
    except Exception as e:
        print(f"  {COLOR_YELLOW}⚠️  Could not update .git/info/exclude: {e}{COLOR_RESET}")
        
    return False


# ==============================================================================
# SYNCHRONIZATION ENGINE
# ==============================================================================

def sync_project(
    project_name: str,
    project_path: Path,
    canonical_source: Path,
    mode: str = "copy",
    dry_run: bool = False,
    force: bool = False,
    config: Optional[Dict[str, Any]] = None
) -> bool:
    """Synchronizes Material 3 UI library to a single target project."""
    print(f"\n{COLOR_CYAN}{COLOR_BOLD}▶ Syncing Project: {project_name}{COLOR_RESET} ({project_path})")
    
    if not project_path.exists():
        print(f"  {COLOR_RED}❌ Error: Project path does not exist: {project_path}{COLOR_RESET}")
        return False

    if not canonical_source.exists():
        print(f"  {COLOR_RED}❌ Error: Canonical Material 3 source not found: {canonical_source}{COLOR_RESET}")
        return False

    # Prevent recursive self-sync
    target_addon = project_path / "addons" / "material3"
    target_addon_parent = target_addon.parent
    canonical_resolved = canonical_source.resolve()

    if not target_addon.is_symlink() and target_addon.exists() and target_addon.resolve() == canonical_resolved:
        print(f"  {COLOR_GREEN}✓ Project is the canonical source itself ({target_addon}). Skipped.{COLOR_RESET}")
        return True

    # 1. Dirty Git check (unless --force)
    if not force:
        is_dirty, dirty_output = check_git_dirty(project_path, "addons/material3")
        if is_dirty:
            print(f"  {COLOR_RED}❌ Uncommitted git changes detected in {target_addon}:{COLOR_RESET}")
            for line in dirty_output.splitlines()[:5]:
                print(f"    {line}")
            print(f"  {COLOR_YELLOW}Use --force to bypass this safety check or commit your changes.{COLOR_RESET}")
            return False

    # 2. Execute Sync Mode
    if mode == "link":
        print(f"  {COLOR_BLUE}🔗 Mode: Symbolic Link (Live Canonical Mirror){COLOR_RESET}")
        if target_addon.is_symlink():
            current_target = target_addon.resolve()
            if current_target == canonical_resolved:
                print(f"  {COLOR_GREEN}✓ Already symlinked to canonical source.{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would re-link {target_addon} -> {canonical_source}{COLOR_RESET}")
                else:
                    target_addon.unlink()
                    os.symlink(canonical_resolved, target_addon, target_is_directory=True)
                    print(f"  {COLOR_GREEN}✓ Updated symlink -> {canonical_source}{COLOR_RESET}")
        else:
            if target_addon.exists():
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would replace concrete directory {target_addon} with symlink -> {canonical_source}{COLOR_RESET}")
                else:
                    shutil.rmtree(target_addon)
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    try:
                        os.symlink(canonical_resolved, target_addon, target_is_directory=True)
                    except OSError:
                        subprocess.run(["cmd", "/c", "mklink", "/J", str(target_addon), str(canonical_resolved)], check=True)
                    print(f"  {COLOR_GREEN}✓ Replaced concrete directory with symlink -> {canonical_source}{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would create symlink {target_addon} -> {canonical_source}{COLOR_RESET}")
                else:
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    try:
                        os.symlink(canonical_resolved, target_addon, target_is_directory=True)
                    except OSError:
                        subprocess.run(["cmd", "/c", "mklink", "/J", str(target_addon), str(canonical_resolved)], check=True)
                    print(f"  {COLOR_GREEN}✓ Created symlink -> {canonical_source}{COLOR_RESET}")

        # Ensure .git/info/exclude safety
        excluded = ensure_git_exclude(project_path, "addons/material3", dry_run=dry_run)
        if excluded:
            tag = "[DRY-RUN] Would add" if dry_run else "Added"
            print(f"  {COLOR_GREEN}✓ {tag} 'addons/material3' to .git/info/exclude for safety.{COLOR_RESET}")

    elif mode == "unlink":
        print(f"  {COLOR_BLUE}🔓 Mode: Unlink (Replace symlink with concrete files){COLOR_RESET}")
        if target_addon.is_symlink():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would remove symlink at {target_addon} and copy concrete canonical files.{COLOR_RESET}")
            else:
                target_addon.unlink()
                shutil.copytree(canonical_source, target_addon)
                print(f"  {COLOR_GREEN}✓ Removed symlink and wrote concrete canonical files.{COLOR_RESET}")
        else:
            if target_addon.exists():
                print(f"  {COLOR_GREEN}✓ addons/material3 is already a concrete directory.{COLOR_RESET}")
            else:
                if dry_run:
                    print(f"  {COLOR_MAGENTA}[DRY-RUN] Would copy canonical files to {target_addon}{COLOR_RESET}")
                else:
                    target_addon_parent.mkdir(parents=True, exist_ok=True)
                    shutil.copytree(canonical_source, target_addon)
                    print(f"  {COLOR_GREEN}✓ Copied canonical files to {target_addon}{COLOR_RESET}")

    elif mode == "git":
        print(f"  {COLOR_BLUE}📦 Mode: Git Submodule Update{COLOR_RESET}")
        if dry_run:
            print(f"  {COLOR_MAGENTA}[DRY-RUN] Would execute: git submodule update --init --remote --merge addons/material3 in {project_path}{COLOR_RESET}")
        else:
            try:
                cmd = ["git", "submodule", "update", "--init", "--remote", "--merge", "addons/material3"]
                proc = subprocess.run(cmd, cwd=project_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if proc.returncode == 0:
                    print(f"  {COLOR_GREEN}✓ Submodule update succeeded.{COLOR_RESET}")
                    if proc.stdout.strip():
                        print(f"    {proc.stdout.strip()}")
                else:
                    cmd_fallback = ["git", "submodule", "update", "--init", "--recursive", "addons/material3"]
                    proc2 = subprocess.run(cmd_fallback, cwd=project_path, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    if proc2.returncode == 0:
                        print(f"  {COLOR_GREEN}✓ Submodule update (--recursive) succeeded.{COLOR_RESET}")
                    else:
                        print(f"  {COLOR_RED}❌ Submodule update failed: {proc.stderr.strip()}{COLOR_RESET}")
            except Exception as e:
                print(f"  {COLOR_RED}❌ Submodule execution error: {e}{COLOR_RESET}")

    else:  # Default: copy
        print(f"  {COLOR_BLUE}📁 Mode: Copy / Mirror (Concrete Files){COLOR_RESET}")
        if target_addon.is_symlink():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would remove symlink at {target_addon} and copy canonical files.{COLOR_RESET}")
            else:
                target_addon.unlink()
                shutil.copytree(canonical_source, target_addon, copy_function=shutil.copy)
                print(f"  {COLOR_GREEN}✓ Removed symlink and copied canonical files.{COLOR_RESET}")
        elif target_addon.exists():
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would mirror canonical files from {canonical_source} to {target_addon}{COLOR_RESET}")
            else:
                shutil.copytree(canonical_source, target_addon, copy_function=shutil.copy, dirs_exist_ok=True)
                print(f"  {COLOR_GREEN}✓ Mirrored canonical files to {target_addon}{COLOR_RESET}")
        else:
            if dry_run:
                print(f"  {COLOR_MAGENTA}[DRY-RUN] Would copy canonical files to {target_addon}{COLOR_RESET}")
            else:
                target_addon_parent.mkdir(parents=True, exist_ok=True)
                shutil.copytree(canonical_source, target_addon, copy_function=shutil.copy)
                print(f"  {COLOR_GREEN}✓ Copied canonical files to {target_addon}{COLOR_RESET}")

    return True


# ==============================================================================
# CLI COMMAND DISPATCHER
# ==============================================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Material 3 Godot Universal Synchronization & Dev-Link CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 tools/m3_sync.py --all
  python3 tools/m3_sync.py --link --project guildmaster
  python3 tools/m3_sync.py --copy --project /path/to/custom_game
  python3 tools/m3_sync.py list-projects
  python3 tools/m3_sync.py install /path/to/my_game --link
        """
    )

    parser.add_argument("projects", nargs="*", default=[], help="Target project name(s) or paths to sync.")
    parser.add_argument("--project", "-p", help="Target project name or directory.")
    parser.add_argument("--all", "-a", action="store_true", help="Sync across all registered projects in .m3_projects.json.")
    parser.add_argument("--copy", action="store_true", help="Mirror concrete files from canonical source (default mode).")
    parser.add_argument("--link", "-l", action="store_true", help="Create cross-platform symlink for live multi-project dev.")
    parser.add_argument("--unlink", "-u", action="store_true", help="Replace symlinks with concrete canonical copies.")
    parser.add_argument("--git", "-g", action="store_true", help="Run 'git submodule update --init --remote --merge addons/material3'.")
    parser.add_argument("--dry-run", "-n", action="store_true", help="Preview synchronization without writing changes.")
    parser.add_argument("--force", "-f", action="store_true", help="Force sync bypassing uncommitted Git checks.")
    parser.add_argument("--list-projects", action="store_true", help="List all registered projects.")

    args = parser.parse_args()

    registry = ProjectRegistry()
    canonical_source = registry.get_canonical_source()

    if args.list_projects or (args.projects and args.projects[0] == "list-projects"):
        print(f"\n{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")
        print(f"{COLOR_CYAN}{COLOR_BOLD}📋 REGISTERED MATERIAL 3 GODOT PROJECTS{COLOR_RESET}")
        print(f"  Canonical Source: {canonical_source}")
        print(f"{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}\n")
        for name, path, cfg in registry.get_all_projects():
            exists_mark = f"{COLOR_GREEN}✓ Found{COLOR_RESET}" if path.exists() else f"{COLOR_RED}✗ Not found{COLOR_RESET}"
            desc = cfg.get("description", "")
            print(f"• {COLOR_BOLD}{name}{COLOR_RESET} [{exists_mark}]")
            print(f"  Path: {path}")
            if desc:
                print(f"  Info: {desc}")
            print("")
        return 0

    if args.projects and args.projects[0] == "install":
        if len(args.projects) < 2:
            print(f"{COLOR_RED}Error: 'install' requires a target project path argument.{COLOR_RESET}")
            return 1
        target_path = Path(args.projects[1]).resolve()
        mode = "link" if args.link else "copy"
        ok = sync_project(
            project_name=target_path.name,
            project_path=target_path,
            canonical_source=canonical_source,
            mode=mode,
            dry_run=args.dry_run,
            force=args.force
        )
        return 0 if ok else 1

    # Normal Sync Flow
    print(f"\n{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}🔄 MATERIAL 3 GODOT UNIVERSAL SYNCHRONIZATION ENGINE{COLOR_RESET}")
    print(f"  Canonical Source: {canonical_source}")
    if args.dry_run:
        print(f"  {COLOR_MAGENTA}Execution Mode:   DRY-RUN (Preview Only){COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")

    if args.link:
        mode = "link"
    elif args.unlink:
        mode = "unlink"
    elif args.git:
        mode = "git"
    else:
        mode = "copy"

    targets = []
    projects_input = list(args.projects)
    if args.project:
        projects_input.append(args.project)

    if args.all or not projects_input or "all" in [p.lower() for p in projects_input]:
        if not projects_input and not args.all:
            print(f"\n{COLOR_YELLOW}No project specified. Syncing ALL registered projects (--all)...{COLOR_RESET}")
        targets = registry.get_all_projects()
    else:
        for proj_id in projects_input:
            matched = registry.get_project_info(proj_id)
            if matched:
                if matched not in targets:
                    targets.append(matched)
            else:
                print(f"\n{COLOR_RED}❌ Error: Unknown project '{proj_id}'.{COLOR_RESET}")
                print("\nAvailable registered projects in .m3_projects.json:")
                for p_name, p_path, _ in registry.get_all_projects():
                    print(f"  • {COLOR_BOLD}{p_name}{COLOR_RESET}: {p_path}")
                return 1

    success_count = 0
    fail_count = 0

    for name, path, cfg in targets:
        ok = sync_project(
            project_name=name,
            project_path=path,
            canonical_source=canonical_source,
            mode=mode,
            dry_run=args.dry_run,
            force=args.force,
            config=cfg
        )
        if ok:
            success_count += 1
        else:
            fail_count += 1

    print(f"\n{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}")
    print(f"📊 Sync Complete: {COLOR_GREEN}{success_count} Succeeded{COLOR_RESET}, {COLOR_RED if fail_count > 0 else ''}{fail_count} Failed{COLOR_RESET}")
    print(f"{COLOR_CYAN}{COLOR_BOLD}========================================================{COLOR_RESET}\n")

    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
