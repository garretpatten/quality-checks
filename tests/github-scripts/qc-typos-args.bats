#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-typos-args.sh.
# shellcheck disable=SC2016,SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	cd "${SANDBOX}" || return
}

teardown() {
	common_teardown
}

# Source typo-args in a clean subshell and print TYPOS_CLI_ARGS, one per line.
source_typos_args() {
	run --separate-stderr bash -c '
		set -euo pipefail
		# shellcheck source=../../.github/scripts/qc-typos-args.sh
		source "$1"
		if [[ ${#TYPOS_CLI_ARGS[@]} -eq 0 ]]; then
			exit 0
		fi
		printf "%s\n" "${TYPOS_CLI_ARGS[@]}"
	' bash "${REPO_ROOT}/.github/scripts/qc-typos-args.sh"
}

@test "qc-typos-args uses QC_TYPOS_CONFIG when the file exists" {
	printf '[default]\n' >"${SANDBOX}/custom.toml"
	export QC_TYPOS_CONFIG="${SANDBOX}/custom.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
${SANDBOX}/custom.toml
EOF
}

@test "qc-typos-args fails when QC_TYPOS_CONFIG is missing" {
	export QC_TYPOS_CONFIG="${SANDBOX}/missing.toml"
	source_typos_args
	assert_failure 1
	# shellcheck disable=SC2154 # $stderr is set by run --separate-stderr
	assert_equal "${stderr}" "typos config not found: ${SANDBOX}/missing.toml"
}

@test "qc-typos-args prefers typos.toml in the current repository" {
	cp "${FIXTURES_DIR}/typos.toml" "${SANDBOX}/typos.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
typos.toml
EOF
}

@test "qc-typos-args falls back to _typos.toml" {
	printf '[default]\n' >"${SANDBOX}/_typos.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
_typos.toml
EOF
}

@test "qc-typos-args falls back to .typos.toml" {
	printf '[default]\n' >"${SANDBOX}/.typos.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
.typos.toml
EOF
}

@test "qc-typos-args leaves TYPOS_CLI_ARGS empty when no config exists" {
	source_typos_args
	assert_success
	assert_output ""
}

@test "qc-typos-args prefers typos.toml over _typos.toml and .typos.toml" {
	printf '[default]\n' >"${SANDBOX}/typos.toml"
	printf '[default]\n' >"${SANDBOX}/_typos.toml"
	printf '[default]\n' >"${SANDBOX}/.typos.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
typos.toml
EOF
}

@test "qc-typos-args prefers QC_TYPOS_CONFIG over typos.toml" {
	printf '[default]\n' >"${SANDBOX}/typos.toml"
	printf '[default]\n' >"${SANDBOX}/custom.toml"
	export QC_TYPOS_CONFIG="${SANDBOX}/custom.toml"
	source_typos_args
	assert_success
	assert_output --stdin <<EOF
--config
${SANDBOX}/custom.toml
EOF
}
