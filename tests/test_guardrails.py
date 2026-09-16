"""The template repo tests its own guardrails.

If these fail, the template is broken and should not be copied.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------------
# License
# ---------------------------------------------------------------------------

def test_license_exists() -> None:
    assert (REPO_ROOT / "LICENSE.md").exists(), "LICENSE.md must exist"


def test_license_has_mit_grant() -> None:
    """The MIT grant and warranty disclaimer must be intact."""
    text = (REPO_ROOT / "LICENSE.md").read_text()
    assert "Permission is hereby granted" in text, "MIT permission grant missing"
    assert "WITHOUT WARRANTY OF ANY KIND" in text, "MIT warranty disclaimer missing"


def test_license_names_copyright_holder() -> None:
    """MIT requires the copyright notice to be preserved."""
    text = (REPO_ROOT / "LICENSE.md").read_text()
    assert "Copyright (c) 2026 Andrew Kingdom" in text, (
        "copyright line missing or altered — MIT requires it to be preserved"
    )


def test_license_links_to_original() -> None:
    """The best-practices section asks redistributors to link back."""
    text = (REPO_ROOT / "LICENSE.md").read_text()
    assert "github.com/akingdom/python-agent-guardrails" in text, (
        "LICENSE.md must point readers to the original repository"
    )


# ---------------------------------------------------------------------------
# Structure
# ---------------------------------------------------------------------------

def test_agents_md_exists() -> None:
    assert (REPO_ROOT / "AGENTS.md").exists(), "AGENTS.md must exist at the repo root"


def test_agents_md_is_short() -> None:
    """Keep the always-loaded context small.

    This is a sanity bound, not a rule. The principle is "minimum necessary",
    but an AGENTS.md that grows without limit has stopped being a guardrail.
    """
    agents_md = REPO_ROOT / "AGENTS.md"
    lines = agents_md.read_text().splitlines()
    assert len(lines) < 120, f"AGENTS.md is {len(lines)} lines; consider trimming."


def test_skills_have_frontmatter() -> None:
    skills_dir = REPO_ROOT / ".agents" / "skills"
    skill_files = sorted(skills_dir.glob("*/SKILL.md"))
    assert skill_files, "at least one skill is expected"
    for skill_md in skill_files:
        text = skill_md.read_text()
        assert text.startswith("---"), f"{skill_md} must start with YAML frontmatter"
        assert "name:" in text, f"{skill_md} must declare a name"
        assert "description:" in text, f"{skill_md} must declare a description"