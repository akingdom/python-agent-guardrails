#!/usr/bin/env bash
#
# scripts/prep-release-pre-git.sh
#
# Maintainer-side release check. Verifies the repository is ready to tag.
#
# This is NOT install.py. That script copies the template into a user's
# project. This script checks whether the template repo itself is in a
# releasable state.
#
# Does not tag, commit, or push. Reports, then prints next steps.
#
# Usage:
#   bash scripts/prep-release.sh

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || perl -MCwd -e 'print Cwd::abs_path(shift)' "$0")")"
cd "$SCRIPT_DIR/.."

echo "Checking $(basename "$PWD") for release ..."
echo

FAIL=0
WARN=0

pass() { printf '  %-52s PASS\n' "$1"; }
fail() { printf '  %-52s FAIL\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  %-52s WARN\n' "$1"; WARN=$((WARN + 1)); }

run() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        pass "$label"
    else
        fail "$label"
        echo "    ── output ──"
        "$@" 2>&1 | sed 's/^/    /' | tail -20
        echo "    ────────────"
    fi
}

# ---------------------------------------------------------------------
# 1. Git state
# ---------------------------------------------------------------------

echo "Git state:"

if [ -z "$(git status --porcelain)" ]; then
    pass "working tree is clean"
else
    fail "working tree has uncommitted changes"
    git status --short | sed 's/^/    /'
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH" = "main" ]; then
    pass "on main"
else
    warn "on branch '$BRANCH' (releases usually come from main)"
fi

# ---------------------------------------------------------------------
# 2. Template invariants
#
# These are the things that make this a template rather than a package.
# If any of them flips, the tree has drifted from its purpose.
# ---------------------------------------------------------------------

echo
echo "Template invariants:"

if grep -q '^\[tool\.uv\]' pyproject.toml && grep -q '^package = false' pyproject.toml; then
    pass "[tool.uv] package = false is set"
else
    fail "[tool.uv] package = false is missing"
fi

if [ -f install.py ]; then
    pass "install.py is present"
else
    fail "install.py is missing"
fi

if [ -f uv.lock ]; then
    pass "uv.lock is committed (CI uses --locked)"
else
    fail "uv.lock is missing"
fi

if [ -f AGENTS.md ] && [ -f README.md ] && [ -f LICENSE.md ]; then
    pass "AGENTS.md, README.md, LICENSE.md present"
else
    fail "one or more root markdown files are missing"
fi

# ---------------------------------------------------------------------
# 3. Local CI checks
#
# Runs the same commands .github/workflows/verify.yml runs. If these
# pass locally, CI should pass. If they don't, CI will repeat the
# failure in a less convenient environment.
# ---------------------------------------------------------------------

echo
echo "Local CI checks (same as .github/workflows/verify.yml):"

run "uv sync --locked" uv sync --locked --all-extras --dev
run "ruff check" uv run ruff check .
run "ruff format --check" uv run ruff format --check .
run "mypy" uv run mypy .
run "pytest" uv run pytest -q

# ---------------------------------------------------------------------
# 4. Version vs. latest tag
# ---------------------------------------------------------------------

echo
echo "Version:"

PKG_VERSION="$(grep -m1 '^version' pyproject.toml | sed -E 's/version *= *"([^"]*)".*/\1/')"
LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo '')"

printf '  pyproject.toml version:  %s\n' "${PKG_VERSION:-<unknown>}"
printf '  latest git tag:          %s\n' "${LAST_TAG:-<none>}"

if [ -z "$LAST_TAG" ]; then
    warn "no git tags yet (first release)"
elif [ "v$PKG_VERSION" = "$LAST_TAG" ]; then
    warn "version matches last tag (nothing new to release)"
fi

# ---------------------------------------------------------------------
# 5. Changes since last tag — the release notes draft
# ---------------------------------------------------------------------

if [ -n "$LAST_TAG" ]; then
    echo
    echo "Commits since $LAST_TAG:"
    git log --oneline "$LAST_TAG..HEAD" | sed 's/^/    /'
fi

# ---------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------

echo
if [ "$FAIL" -gt 0 ]; then
    printf 'Result: %d FAIL, %d WARN\n' "$FAIL" "$WARN"
    echo
    echo "Fix the failures above, then re-run."
    exit 1
fi

printf 'Result: PASS (%d warning%s)\n' "$WARN" "$([ "$WARN" -eq 1 ] && echo '' || echo 's')"
echo
echo "Next steps:"
echo "  1. Bump version in pyproject.toml if this is a release."
echo "  2. git add -A && git commit -m \"Release v$PKG_VERSION\""
echo "  3. git tag v$PKG_VERSION"
echo "  4. git push && git push --tags"
echo "  5. Optionally mark a GitHub Release from the tag."