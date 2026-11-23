#!/usr/bin/env sh
# Flags requirement and use-case ids that are defined but never referenced elsewhere.
# Usage: scripts/check-trace.sh   (run from the repo root). Exit 1 if anything is orphaned.
set -eu
cd "$(dirname "$0")/.."
status=0
check() {
  file="$1"; pattern="$2"; shift 2
  for id in $(grep -oE "^#+ +$pattern" "$file" | grep -oE "$pattern" | sort -u); do
    if ! grep -rqE "\b$id\b" "$@"; then
      echo "orphan: $id (defined in $file, referenced in none of: $*)"
      status=1
    fi
  done
}
# Use cases must be cited by at least one requirement.
check docs/use-cases.md 'UC-[0-9]+' docs/requirements.md
# Requirements must be cited by architecture or verification.
check docs/requirements.md '(FR|PR|RR|POR|SR|DR|SC)-[0-9]+' docs/architecture.md docs/verification.md docs/implementation-plan.md
exit $status
