#!/usr/bin/env bash
# Shared setup for the bats unit tests. Load with: load ../helpers/setup

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"
FIXTURES_DIR="${TESTS_DIR}/fixtures"
# Snapshot the real home before tests redirect HOME into the sandbox.
REAL_HOME="${HOME}"
export TESTS_DIR REPO_ROOT FIXTURES_DIR

# bats-support, bats-assert and bats-file live in different places depending on
# how they were installed (bats-action, scripts/install-bats.sh, ~/.local).
BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${REPO_ROOT}/.tools:/usr/lib:/usr/local/lib:/usr/lib/bats:/opt/homebrew/lib:${REAL_HOME}/.local/lib"
export BATS_LIB_PATH

common_setup() {
	# run --separate-stderr needs bats >= 1.5.0.
	bats_require_minimum_version 1.5.0
	bats_load_library bats-support
	bats_load_library bats-assert
	bats_load_library bats-file

	SANDBOX="$(mktemp -d "${BATS_TMPDIR:-/tmp}/quality-checks-tests.XXXXXX")"
	export SANDBOX
	export HOME="${SANDBOX}/home"
	mkdir -p "${HOME}"

	# Isolated git config so fixture repos do not use host signing settings.
	export GIT_CONFIG_GLOBAL="${SANDBOX}/gitconfig"
	export GIT_CONFIG_SYSTEM=/dev/null
	git config --file "${GIT_CONFIG_GLOBAL}" user.email "test@example.com"
	git config --file "${GIT_CONFIG_GLOBAL}" user.name "Test"
	git config --file "${GIT_CONFIG_GLOBAL}" commit.gpgsign false
	git config --file "${GIT_CONFIG_GLOBAL}" tag.gpgsign false
	git config --file "${GIT_CONFIG_GLOBAL}" init.defaultBranch main

	# Fake binaries shadow the real ones so tests never touch the network.
	export PATH="${TESTS_DIR}/stubs:${PATH}"
	export STUB_CALL_LOG="${SANDBOX}/stub-calls.log"
	: >"${STUB_CALL_LOG}"
	unset CURL_STUB_MODE CURL_STUB_BODY STUB_FAIL QC_DIFF_BASE LINT_BASE \
		QC_TYPOS_CONFIG CHROMEDRIVER_PATH GITHUB_ENV GITHUB_WORKSPACE \
		TYPOS_CLI_ARGS
}

common_teardown() {
	if [[ -n "${SANDBOX:-}" && -d "${SANDBOX}" ]]; then
		rm -rf "${SANDBOX}"
	fi
}

# Print the recorded stub calls (one per line).
stub_calls() {
	cat "${STUB_CALL_LOG}"
}

# Assert the recorded stub calls equal the given lines, in order.
assert_stub_calls() {
	local expected=""
	if [[ $# -gt 0 ]]; then
		expected="$(printf '%s\n' "$@")"
	fi
	assert_equal "$(stub_calls)" "${expected}"
}

# Assert some recorded stub call matches the given extended regex.
assert_stub_call() {
	if ! grep -Eq -- "$1" "${STUB_CALL_LOG}"; then
		fail "no stub call matching '$1':"$'\n'"$(stub_calls)"
	fi
}

# Assert no recorded stub call matches the given extended regex.
refute_stub_call() {
	if grep -Eq -- "$1" "${STUB_CALL_LOG}"; then
		fail "unexpected stub call matching '$1':"$'\n'"$(stub_calls)"
	fi
}

# Create a git repo at $1 with two commits. Optional $2 is the branch name
# (default: main). If $3 is "origin", add a local bare remote and fetch it
# so refs/remotes/origin/<branch> exists.
init_git_repo() {
	local work="$1"
	local branch="${2:-main}"
	local with_origin="${3:-}"
	mkdir -p "${work}"
	git init -q "${work}"
	printf 'first\n' >"${work}/README"
	git -C "${work}" add README
	git -C "${work}" commit -q -m "first"
	git -C "${work}" branch -q -M "${branch}"
	printf 'second\n' >"${work}/README"
	git -C "${work}" add README
	git -C "${work}" commit -q -m "second"

	if [[ "${with_origin}" == "origin" ]]; then
		local bare="${work}.git"
		git clone -q --bare "${work}" "${bare}"
		git -C "${work}" remote add origin "${bare}"
		git -C "${work}" fetch -q origin
	fi
}
