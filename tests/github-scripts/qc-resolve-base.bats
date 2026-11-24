#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-resolve-base.sh.
# shellcheck disable=SC2016,SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../.github/scripts/qc-resolve-base.sh
	source "${REPO_ROOT}/.github/scripts/qc-resolve-base.sh"
}

teardown() {
	common_teardown
}

# qc_resolve_base must be called directly (not via run) so BASE_REF
# propagates. Output (warning annotations) is captured to a log file.
qc_resolve_base_logged() {
	local log="$1"
	qc_resolve_base >"${log}" 2>&1
}

refute_warning_logged() {
	if grep -q '::warning::' "$1"; then
		fail "unexpected ::warning:: in $1: $(cat "$1")"
	fi
}

@test "qc_resolve_base prefers QC_DIFF_BASE over origin/main" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	export QC_DIFF_BASE="abc123"
	qc_resolve_base_logged "${SANDBOX}/out.log"
	refute_warning_logged "${SANDBOX}/out.log"
	assert_equal "${BASE_REF}" "abc123"
}

@test "qc_resolve_base auto-detects origin/main when QC_DIFF_BASE is empty" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	unset QC_DIFF_BASE
	qc_resolve_base_logged "${SANDBOX}/out.log"
	refute_warning_logged "${SANDBOX}/out.log"
	assert_equal "${BASE_REF}" "origin/main"
}

@test "qc_resolve_base auto-detects origin/master when main is missing" {
	init_git_repo "${SANDBOX}/repo" master origin
	cd "${SANDBOX}/repo"
	unset QC_DIFF_BASE
	qc_resolve_base_logged "${SANDBOX}/out.log"
	refute_warning_logged "${SANDBOX}/out.log"
	assert_equal "${BASE_REF}" "origin/master"
}

@test "qc_resolve_base auto-detects non-main/master default branches" {
	init_git_repo "${SANDBOX}/repo" develop origin
	cd "${SANDBOX}/repo"
	unset QC_DIFF_BASE
	qc_resolve_base_logged "${SANDBOX}/out.log"
	refute_warning_logged "${SANDBOX}/out.log"
	assert_equal "${BASE_REF}" "origin/develop"
}

@test "qc_resolve_base falls back to HEAD~1 with a warning when no remote default exists" {
	init_git_repo "${SANDBOX}/repo" develop
	cd "${SANDBOX}/repo"
	unset QC_DIFF_BASE
	qc_resolve_base_logged "${SANDBOX}/out.log"
	assert_file_contains "${SANDBOX}/out.log" '::warning::'
	assert_equal "${BASE_REF}" "HEAD~1"
}

@test "sourcing the script without bats runs immediately under GITHUB_WORKSPACE" {
	init_git_repo "${SANDBOX}/repo" main origin
	export GITHUB_WORKSPACE="${SANDBOX}/repo"
	# Simulate a workflow caller: no BATS_VERSION, source sets BASE_REF.
	run --separate-stderr bash -c '
		unset BATS_VERSION
		set -euo pipefail
		# shellcheck source=../../.github/scripts/qc-resolve-base.sh
		source "$1"
		printf "%s\n" "${BASE_REF}"
	' bash "${REPO_ROOT}/.github/scripts/qc-resolve-base.sh"
	assert_success
	assert_output "origin/main"
}
