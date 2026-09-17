#!/usr/bin/env bash
#
# scripts/sync-template.sh
#
# Copy the canonical template files from the repository root into
# src/pag/template/, so the wheel ships what the repo shows.
#
# Run after editing any of: AGENTS.md, LICENSE.md, .pre-commit-config.yaml,
# .agents/, .github/
#
# The reverse direction is never needed. The repo root is canonical.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || perl -MCwd -e 'print Cwd::abs_path(shift)' "$0")")"
cd "$SCRIPT_DIR/.."

TEMPLATE="src/pag/template"

rm -rf "$TEMPLATE"
mkdir -p "$TEMPLATE"

cp AGENTS.md "$TEMPLATE/"
cp LICENSE.md "$TEMPLATE/"
cp .pre-commit-config.yaml "$TEMPLATE/"
cp -R .agents "$TEMPLATE/"
cp -R .github "$TEMPLATE/"

# Strip cruft that cp -R carries over but that doesn't belong in the wheel.
find "$TEMPLATE" -name '.DS_Store' -delete
find "$TEMPLATE" -name '__pycache__' -type d -prune -exec rm -rf {} +

echo "Synced template files into $TEMPLATE:"
find "$TEMPLATE" -type f | sort | sed "s|^$TEMPLATE/|  |"