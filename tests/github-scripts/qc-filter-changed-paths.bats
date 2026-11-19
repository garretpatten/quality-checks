#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-filter-changed-paths.sh.
# shellcheck disable=SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../.github/scripts/qc-filter-changed-paths.sh
	source "${REPO_ROOT}/.github/scripts/qc-filter-changed-paths.sh"
}

teardown() {
	common_teardown
}

# --- qc_should_skip_changed_path -------------------------------------------

@test "qc_should_skip_changed_path skips a prefixed node_modules path" {
	run qc_should_skip_changed_path "node_modules/left-pad/index.js"
	assert_success
}

@test "qc_should_skip_changed_path skips a nested node_modules path" {
	run qc_should_skip_changed_path "packages/app/node_modules/lib/index.js"
	assert_success
}

@test "qc_should_skip_changed_path skips prefixed and nested vendor paths" {
	run qc_should_skip_changed_path "vendor/lib/util.js"
	assert_success
	run qc_should_skip_changed_path "pkg/vendor/dep.js"
	assert_success
}

@test "qc_should_skip_changed_path skips prefixed and nested dist paths" {
	run qc_should_skip_changed_path "dist/bundle.js"
	assert_success
	run qc_should_skip_changed_path "apps/web/dist/bundle.js"
	assert_success
}

@test "qc_should_skip_changed_path skips prefixed and nested build paths" {
	run qc_should_skip_changed_path "build/out.js"
	assert_success
	run qc_should_skip_changed_path "docs/site/build/index.html"
	assert_success
}

@test "qc_should_skip_changed_path skips prefixed and nested coverage paths" {
	run qc_should_skip_changed_path "coverage/lcov.info"
	assert_success
	run qc_should_skip_changed_path "packages/app/coverage/index.html"
	assert_success
}

@test "qc_should_skip_changed_path keeps source, scripts, and workflow paths" {
	run qc_should_skip_changed_path "src/index.js"
	assert_failure
	run qc_should_skip_changed_path "scripts/lint-changed.sh"
	assert_failure
	run qc_should_skip_changed_path ".github/workflows/quality-checks.yaml"
	assert_failure
	run qc_should_skip_changed_path "docs/readme.md"
	assert_failure
}

@test "qc_should_skip_changed_path keeps directory names that only look similar" {
	run qc_should_skip_changed_path "node_modules"
	assert_failure
	run qc_should_skip_changed_path "vendor"
	assert_failure
	run qc_should_skip_changed_path "coverage.txt"
	assert_failure
	run qc_should_skip_changed_path "node_modules_backup/foo.js"
	assert_failure
}

# --- stdin to stdout loop --------------------------------------------------

@test "the script filters a fixture list including blank lines and no trailing newline" {
	run "${REPO_ROOT}/.github/scripts/qc-filter-changed-paths.sh" \
		<"${FIXTURES_DIR}/changed-paths.txt"
	assert_success
	assert_output "src/index.js
scripts/lint-changed.sh
.github/workflows/quality-checks.yaml
docs/readme.md"
}

@test "the script keeps an empty stdin empty" {
	run bash -c "${REPO_ROOT}/.github/scripts/qc-filter-changed-paths.sh" </dev/null
	assert_success
	assert_output ""
}
