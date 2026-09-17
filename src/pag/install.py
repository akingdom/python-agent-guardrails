#!/usr/bin/env python3
"""install.py — copy the guardrails template into a Python project.

This is the implementation behind the ``pag`` console script.

Usage:
    pag <target-dir> [--force]
    pag -h

The target directory must be given explicitly. Installing into an
unspecified location is the kind of surprise this template exists to
prevent.

By default, refuses to overwrite anything that already exists. If files
are found, it reports them and lists options. Use --force to overwrite.
"""

import os
import shutil
import sys
from importlib.resources import files
from pathlib import Path
from typing import TextIO

FILES = [
    ("AGENTS.md", "AGENTS.md"),
    (".agents", ".agents"),
    (".github", ".github"),
    (".pre-commit-config.yaml", ".pre-commit-config.yaml"),
    ("LICENSE.md", "LICENSE-python-agent-guardrails.md"),
]


def template_root() -> Path:
    """Return the on-disk path to the bundled template files.

    Works for wheels, editable installs, and zipped distributions.
    """
    return Path(str(files("pag").joinpath("template")))


def print_usage(stream: TextIO = sys.stdout) -> None:
    print(__doc__.strip(), file=stream)


def open_command(path: Path) -> str:
    """Return a shell command that opens `path` in an editor or the OS default."""
    quoted = f'"{path}"'
    if editor := os.environ.get("EDITOR"):
        return f"{editor} {quoted}"
    if sys.platform == "darwin":
        return f"open {quoted}"
    if sys.platform == "win32":
        return f'start "" {quoted}'
    return f"xdg-open {quoted}"


def report_conflicts(conflicts: list[str], source: Path, target: Path) -> None:
    print(
        f"Found {len(conflicts)} of {len(FILES)} template files already present in:\n  {target}\n"
    )
    for name in conflicts:
        print(f"  {name}")
    print()
    print("Nothing was copied. Options:\n")
    print("  1. Move the existing files aside, then re-run.")
    print("  2. Copy the template files by hand from the source repo.")
    print("  3. Re-run with --force to overwrite them.\n")
    print("To see what differs between your copy and the template:\n")
    for src_name, dest_name in FILES:
        if dest_name in conflicts:
            src = source / src_name
            dest = target / dest_name
            if src.is_dir():
                print(f'  diff -ru "{src}" "{dest}"')
            else:
                print(f'  diff -u "{src}" "{dest}"')


def main() -> int:
    args = sys.argv[1:]

    if not args:
        print_usage(sys.stderr)
        return 2

    if args[0] in ("-h", "--help"):
        print_usage()
        return 0

    force = "--force" in args
    positional = [a for a in args if a != "--force"]

    if len(positional) != 1:
        print(f"Error: expected one target directory, got {len(positional)}.", file=sys.stderr)
        print(file=sys.stderr)
        print_usage(sys.stderr)
        return 2

    target = Path(positional[0]).resolve()
    source = template_root()

    if not target.is_dir():
        print(f"Error: '{target}' is not a directory.", file=sys.stderr)
        return 1

    conflicts = [dest_name for _, dest_name in FILES if (target / dest_name).exists()]

    if conflicts and not force:
        report_conflicts(conflicts, source, target)
        return 1

    for src_name, dest_name in FILES:
        src = source / src_name
        dest = target / dest_name
        if src.is_dir():
            shutil.copytree(src, dest, dirs_exist_ok=force)
        else:
            shutil.copy2(src, dest)

    agents_md = target / "AGENTS.md"

    if conflicts:
        print(f"Overwrote {len(conflicts)} existing file(s) in:\n  {target}\n")
    else:
        print(f"Installed to:\n  {target}\n")

    for _, dest_name in FILES:
        print(f"  {dest_name}")
    print()
    print("Next: edit the Project section of AGENTS.md for your stack.\n")
    print(f"  {open_command(agents_md)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
