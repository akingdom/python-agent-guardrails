"""The template files must exist in exactly two places.

Source of truth: the repository root (for agents working on this repo).
Shipped copy: src/pag/template/ (bundled into the wheel).

This test asserts byte-for-byte equality. If it fails, one copy has been
edited without the other. Run scripts/sync-template.sh to reconcile.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATE_ROOT = REPO_ROOT / "src" / "pag" / "template"

SYNCED = [
    "AGENTS.md",
    "LICENSE.md",
    ".pre-commit-config.yaml",
    ".agents/skills/debug-first/SKILL.md",
    ".agents/skills/verify-first/SKILL.md",
    ".github/workflows/verify.yml",
]


def test_template_files_are_in_sync() -> None:
    mismatches: list[str] = []
    for rel in SYNCED:
        root_file = REPO_ROOT / rel
        copy_file = TEMPLATE_ROOT / rel
        if not root_file.exists():
            mismatches.append(f"root missing: {rel}")
            continue
        if not copy_file.exists():
            mismatches.append(f"copy missing: src/pag/template/{rel}")
            continue
        if root_file.read_bytes() != copy_file.read_bytes():
            mismatches.append(f"content differs: {rel}")
    assert not mismatches, (
        "Template files have drifted between the repository root and "
        "src/pag/template/. Run scripts/sync-template.sh.\n"
        + "\n".join(f"  - {m}" for m in mismatches)
    )
