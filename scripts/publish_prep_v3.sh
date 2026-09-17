#!/usr/bin/env bash
# scripts/publish_prep_v3.sh
#
# Prepare a Python project for release. Runs from anywhere inside the repo.
#
# Does NOT commit, tag, push, or upload. The git step is a human action
# performed via GitHub Desktop by design. This script's job ends by
# telling you the tree is ready for that step.
#
# Adapts to the project's existing tools:
#   - package manager from lockfile (uv, poetry, pipenv, pip)
#   - linters / type checkers / tests from pyproject.toml sections
#   - tools run inside the project's own environment, not the system one
#
# Usage:
#   bash scripts/publish_prep_v3.sh

set -euo pipefail

# ---------------------------------------------------------------------
# Locate the repo root
# ---------------------------------------------------------------------

resolve_repo_root() {
    local dir
    dir="$(dirname "$(readlink -f "$0" 2>/dev/null || perl -MCwd -e 'print Cwd::abs_path(shift)' "$0")")"

    if [ "$(basename "$dir")" = "scripts" ] && [ -f "$dir/../pyproject.toml" ]; then
        dir="$dir/.."
    fi

    if [ ! -f "$dir/pyproject.toml" ]; then
        echo "Error: cannot find pyproject.toml from $dir" >&2
        echo "Run this script from inside a Python project." >&2
        return 1
    fi

    cd "$dir" && pwd
}
REPO_ROOT="$(resolve_repo_root)" || exit 1
cd "$REPO_ROOT"
echo "Repo root: $REPO_ROOT"

# ---------------------------------------------------------------------
# Detect the package manager from the lockfile
# ---------------------------------------------------------------------

if [ -f uv.lock ]; then
    command -v uv >/dev/null 2>&1 || { echo "Error: uv.lock present but 'uv' not on PATH." >&2; exit 1; }
    MANAGER=uv
elif [ -f poetry.lock ]; then
    command -v poetry >/dev/null 2>&1 || { echo "Error: poetry.lock present but 'poetry' not on PATH." >&2; exit 1; }
    MANAGER=poetry
elif [ -f Pipfile.lock ]; then
    command -v pipenv >/dev/null 2>&1 || { echo "Error: Pipfile.lock present but 'pipenv' not on PATH." >&2; exit 1; }
    MANAGER=pipenv
else
    MANAGER=pip
fi
echo "Package manager: $MANAGER"

# ---------------------------------------------------------------------
# Tool runner — every tool invocation goes through this.
#
# `uv sync` and `poetry install` put tools into the project's own
# environment. Calling `python3 -m ruff` from the system Python will not
# find them. This adapter routes each call into the correct environment.
# ---------------------------------------------------------------------

run_in_env() {
    case "$MANAGER" in
        uv)     uv run "$@" ;;
        poetry) poetry run "$@" ;;
        pipenv) pipenv run "$@" ;;
        pip)    python3 "$@" ;;
    esac
}

# For tools that may not be in the project's dependency list (build,
# twine), run them ephemerally inside the project's environment.
run_ephemeral() {
    local tool="$1"; shift
    case "$MANAGER" in
        uv)     uv run --with "$tool" python -m "$tool" "$@" ;;
        poetry) poetry run python -m "$tool" "$@" ;;
        pipenv) pipenv run python -m "$tool" "$@" ;;
        pip)    python3 -m "$tool" "$@" ;;
    esac
}

# ---------------------------------------------------------------------
# Extract the first optional-dependency group, if any
# ---------------------------------------------------------------------

EXTRA_NAME=$(sed -n '/^\[project\.optional-dependencies\]/,/^\[/p' pyproject.toml \
    | grep -E '^[a-zA-Z0-9_-]+ *=' \
    | head -1 \
    | sed -E 's/ *=.*//' \
    | tr -d ' ' || true)

if [ -z "$EXTRA_NAME" ]; then
    echo "No optional-dependency group found."
    EXTRA_NAME=""
else
    echo "Using extra group: '${EXTRA_NAME}'"
fi

# ---------------------------------------------------------------------
# Detect configured tools
# ---------------------------------------------------------------------

has_section() { grep -q "^\[tool\.$1" pyproject.toml; }

LINTERS=()
has_section ruff   && LINTERS+=("ruff check ." "ruff format --check .")
has_section black  && LINTERS+=("black --check .")
has_section flake8 && LINTERS+=("flake8 .")

TYPECHECKERS=()
{ has_section mypy || [ -f mypy.ini ] || [ -f .mypy.ini ]; } && TYPECHECKERS+=("mypy .")

HAS_TESTS=0
{ [ -d tests ] || has_section pytest || [ -f pytest.ini ]; } && HAS_TESTS=1

# ---------------------------------------------------------------------
# Pre-flight: git state (checks only, never acts)
# ---------------------------------------------------------------------

echo
echo "=== 0. Git State ==="

if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    echo "  working tree: clean"
else
    echo "  working tree: has uncommitted changes"
    git status --short | sed 's/^/    /'
    echo "  → Commit and push via GitHub Desktop when ready."
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
echo "  branch:       $BRANCH"

LAST_TAG="$(git describe --tags --abbrev=0 2>/dev/null || echo '')"
PKG_VERSION="$(grep -m1 '^version' pyproject.toml | sed -E 's/version *= *"([^"]*)".*/\1/')"
echo "  version:      ${PKG_VERSION:-<unknown>}"
echo "  latest tag:   ${LAST_TAG:-<none>}"

# ---------------------------------------------------------------------
echo
echo "=== 1. Cleaning Old Build Artifacts ==="
rm -rf build/ dist/ *.egg-info src/*.egg-info

# ---------------------------------------------------------------------
echo
echo "=== 2. Installing Into Project Environment ==="

case "$MANAGER" in
    uv)
        echo "  uv sync --all-extras --dev"
        uv sync --all-extras --dev --quiet
        ;;
    poetry)
        echo "  poetry install --all-extras"
        poetry install --all-extras --quiet
        ;;
    pipenv)
        echo "  pipenv install --dev"
        pipenv install --dev --quiet
        ;;
    pip)
        echo "  pip install --upgrade build twine pytest"
        python3 -m pip install --upgrade --quiet build twine pytest
        if [ -n "$EXTRA_NAME" ]; then
            echo "  pip install -e .[${EXTRA_NAME}]"
            python3 -m pip install -e ".[${EXTRA_NAME}]" --quiet
        else
            echo "  pip install -e ."
            python3 -m pip install -e . --quiet
        fi
        ;;
esac

if ! run_in_env python -c "import pytest_cov" 2>/dev/null; then
    echo "  WARNING: pytest-cov not in project environment – coverage will not be generated."
fi

MODULE_NAME=$(grep -m 1 "^name *=" pyproject.toml | sed -E 's/name *= *"([^"]*)".*/\1/' | tr '-' '_')

# ---------------------------------------------------------------------
echo
echo "=== 3. Running Linters / Formatters ==="
if [ "${#LINTERS[@]}" -eq 0 ]; then
    echo "  No configured linters found. Skipping."
else
    for cmd in "${LINTERS[@]}"; do
        echo "  → $cmd"
        # shellcheck disable=SC2086
        run_in_env $cmd
    done
fi

# ---------------------------------------------------------------------
echo
echo "=== 4. Running Type Checkers ==="
if [ "${#TYPECHECKERS[@]}" -eq 0 ]; then
    echo "  No configured type checkers found. Skipping."
else
    for cmd in "${TYPECHECKERS[@]}"; do
        echo "  → $cmd"
        # shellcheck disable=SC2086
        run_in_env $cmd
    done
fi

# ---------------------------------------------------------------------
echo
echo "=== 5. Executing Test Suite ==="
if [ "$HAS_TESTS" -eq 1 ]; then
    run_in_env pytest tests/
else
    echo "  No 'tests/' directory found. Running import smoke test..."
    run_in_env python -c "import ${MODULE_NAME}; print('Module import successful.')"
fi

# ---------------------------------------------------------------------
echo
echo "=== 6. Packaging Wheel & Source Distribution ==="
case "$MANAGER" in
    uv)     uv build ;;
    poetry) poetry build ;;
    *)      python3 -m build ;;
esac

# ---------------------------------------------------------------------
echo
echo "=== 7. Checking Package Integrity with Twine ==="
run_ephemeral twine check dist/*

# ---------------------------------------------------------------------
echo
echo "========================================================"
echo " BUILD & VERIFICATION SUCCESSFUL"
echo "========================================================"
echo
echo "The git history is untouched. The tree is ready for review."
echo
echo "  → Open GitHub Desktop"
echo "  → Review the diff"
echo "  → Commit and push"
echo
echo "After the push, if publishing to PyPI:"
echo "    uv run twine upload --repository testpypi dist/*   # test first"
echo "    uv run twine upload dist/*                         # production"
echo