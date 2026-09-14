"""The template repo tests its own guardrails.

If these fail, the template is broken and should not be copied.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


def test_license_exists() -> None:
    assert (REPO_ROOT / "LICENSE").exists(), "LICENSE must exist (copying is the use case)"


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
