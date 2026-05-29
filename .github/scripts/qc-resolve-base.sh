#!/usr/bin/env bash
# Resolve diff base ref for quality-checks workflows.
# Sets BASE_REF in the caller's environment.
set -euo pipefail

cd "${GITHUB_WORKSPACE:?}"

git fetch origin main master 2>/dev/null || true

if [[ -n "${QC_DIFF_BASE:-}" ]]; then
	BASE_REF="${QC_DIFF_BASE}"
elif git show-ref --verify --quiet refs/remotes/origin/main; then
	BASE_REF="origin/main"
elif git show-ref --verify --quiet refs/remotes/origin/master; then
	BASE_REF="origin/master"
else
	BASE_REF="HEAD~1"
fi

export BASE_REF
