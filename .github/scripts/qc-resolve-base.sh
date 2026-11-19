#!/usr/bin/env bash
# Resolve diff base ref for quality-checks workflows.
# Sets BASE_REF in the caller's environment.
set -euo pipefail

qc_resolve_base() {
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
}

# Workflows source this file and expect BASE_REF to be set immediately.
# When executed as a script, or sourced outside of bats, cd to
# GITHUB_WORKSPACE first. bats tests source the file and call
# qc_resolve_base from a sandbox repo, so skip the automatic run there.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	cd "${GITHUB_WORKSPACE:?}"
	qc_resolve_base
elif [[ -z "${BATS_VERSION:-}" ]]; then
	cd "${GITHUB_WORKSPACE:?}"
	qc_resolve_base
fi
