#!/usr/bin/env bash
# Resolve diff base ref for quality-checks workflows.
# Sets BASE_REF in the caller's environment. When QC_DIFF_BASE is empty,
# the default branch of origin is auto-detected (any name, not just
# main/master); every silent-capability fallback emits a ::warning::
# annotation so under-linting is never silent (issue #37 H3/S6).
set -euo pipefail

qc_resolve_base() {
	if [[ -n "${QC_DIFF_BASE:-}" ]]; then
		BASE_REF="${QC_DIFF_BASE}"
		export BASE_REF
		return
	fi

	# Ask origin which branch its HEAD points at. Works for any default
	# branch name (develop, trunk, mainline, ...), not just main/master.
	if git remote set-head origin --auto >/dev/null 2>&1; then
		local head_ref
		head_ref="$(
			git symbolic-ref --quiet --short refs/remotes/origin/HEAD \
				2>/dev/null || true
		)"
		if [[ -n "${head_ref}" ]] &&
			git show-ref --verify --quiet "refs/remotes/${head_ref}"; then
			BASE_REF="${head_ref}"
			export BASE_REF
			return
		fi
	fi

	# Fallbacks: legacy main/master names, then the last commit. Each is
	# announced so consumers know coverage may be partial.
	git fetch origin main master 2>/dev/null || true

	if git show-ref --verify --quiet refs/remotes/origin/main; then
		BASE_REF="origin/main"
		echo '::warning::Could not auto-detect the default branch of' \
			'origin; falling back to origin/main.'
	elif git show-ref --verify --quiet refs/remotes/origin/master; then
		BASE_REF="origin/master"
		echo '::warning::Could not auto-detect the default branch of' \
			'origin; falling back to origin/master.'
	else
		BASE_REF="HEAD~1"
		echo '::warning::No default branch detected on origin; diffing' \
			'against HEAD~1, which covers only the last commit. Pass' \
			'diff_base for full pull-request coverage.'
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
