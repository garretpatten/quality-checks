#!/usr/bin/env bats
# Unit tests for scripts/lint-changed.sh.
# shellcheck disable=SC2030,SC2031,SC2153

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../scripts/lint-changed.sh
	source "${REPO_ROOT}/scripts/lint-changed.sh"
}

teardown() {
	common_teardown
}

# --- resolve_base ----------------------------------------------------------

@test "resolve_base prefers LINT_BASE when it is set" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	LINT_BASE="custom-base"
	run resolve_base
	assert_success
	assert_output "custom-base"
}

@test "resolve_base uses origin/main when LINT_BASE is unset" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	unset LINT_BASE
	run resolve_base
	assert_success
	assert_output "origin/main"
}

@test "resolve_base uses origin/master when main is missing" {
	init_git_repo "${SANDBOX}/repo" master origin
	cd "${SANDBOX}/repo"
	unset LINT_BASE
	run resolve_base
	assert_success
	assert_output "origin/master"
}

@test "resolve_base falls back to HEAD~1 when no default remote branch exists" {
	init_git_repo "${SANDBOX}/repo" develop
	cd "${SANDBOX}/repo"
	unset LINT_BASE
	run resolve_base
	assert_success
	assert_output "HEAD~1"
}

# --- has_pattern -----------------------------------------------------------

@test "has_pattern matches a changed YAML file" {
	changed=("src/index.js" ".github/workflows/quality-checks.yaml")
	run has_pattern '\.(ya?ml)$'
	assert_success
}

@test "has_pattern matches a path under .github/" {
	changed=("README.md" ".github/scripts/qc-resolve-base.sh")
	run has_pattern '^\.github/'
	assert_success
}

@test "has_pattern fails when no changed file matches" {
	changed=("src/index.js" "README.md")
	run has_pattern '\.(ya?ml)$'
	assert_failure
}

# --- filter_existing -------------------------------------------------------

@test "filter_existing prints only files that exist" {
	printf 'keep\n' >"${SANDBOX}/keep.txt"
	mkdir -p "${SANDBOX}/dir"
	run filter_existing \
		"${SANDBOX}/keep.txt" \
		"${SANDBOX}/missing.txt" \
		"${SANDBOX}/dir"
	assert_success
	assert_output "${SANDBOX}/keep.txt"
}

@test "filter_existing prints nothing for an empty argument list" {
	run filter_existing
	assert_success
	assert_output ""
}

# --- run_shfmt / run_shellcheck --------------------------------------------

@test "run_shfmt is a no-op when no changed .sh files exist" {
	changed=("README.md" "package.json")
	run run_shfmt
	assert_success
	assert_output ""
	refute_stub_call '^shfmt '
}

@test "run_shfmt checks existing changed shell files" {
	printf '#!/bin/bash\n' >"${SANDBOX}/foo.sh"
	cd "${SANDBOX}"
	changed=("foo.sh" "missing.sh" "README.md")
	run run_shfmt
	assert_success
	assert_output --partial "→ shfmt"
	assert_stub_calls "shfmt -d foo.sh"
}

@test "run_shfmt skips when shfmt is not installed" {
	printf '#!/bin/bash\n' >"${SANDBOX}/foo.sh"
	cd "${SANDBOX}"
	changed=("foo.sh")
	mkdir -p "${SANDBOX}/empty-bin"
	# Isolate PATH only for this run so the real shfmt is hidden.
	PATH="${SANDBOX}/empty-bin" run run_shfmt
	assert_success
	assert_output --partial "shfmt (skipped"
}

@test "run_shfmt fails when the shfmt stub exits non-zero" {
	printf '#!/bin/bash\n' >"${SANDBOX}/foo.sh"
	cd "${SANDBOX}"
	changed=("foo.sh")
	export STUB_FAIL=shfmt
	run run_shfmt
	assert_failure 1
}

@test "run_shellcheck checks existing changed shell files" {
	printf '#!/bin/bash\n' >"${SANDBOX}/foo.sh"
	cd "${SANDBOX}"
	changed=("foo.sh" "README.md")
	run run_shellcheck
	assert_success
	assert_output --partial "→ shellcheck"
	assert_stub_calls "shellcheck -x foo.sh"
}

@test "run_shellcheck skips when shellcheck is not installed" {
	printf '#!/bin/bash\n' >"${SANDBOX}/foo.sh"
	cd "${SANDBOX}"
	changed=("foo.sh")
	mkdir -p "${SANDBOX}/empty-bin"
	PATH="${SANDBOX}/empty-bin" run run_shellcheck
	assert_success
	assert_output --partial "shellcheck (skipped"
}

# --- run_typos / run_yamllint / run_docs_gate / others ---------------------

@test "run_typos invokes typos with auto-detected typos.toml" {
	cd "${SANDBOX}"
	mkdir -p .github/scripts
	cp "${REPO_ROOT}/.github/scripts/qc-typos-args.sh" .github/scripts/
	printf '[default]\n' >typos.toml
	printf 'hello\n' >NOTES.md
	changed=("NOTES.md" "foo.sh")
	run run_typos
	assert_success
	assert_output --partial "→ typos"
	assert_output --partial "config: typos.toml"
	assert_stub_call '^typos --config typos.toml NOTES.md$'
}

@test "run_typos is a no-op when no prose files changed" {
	changed=("foo.sh" "package.json")
	run run_typos
	assert_success
	assert_output ""
	refute_stub_call '^typos '
}

@test "run_yamllint runs when a workflow YAML file changed" {
	changed=(".github/workflows/quality-checks.yaml")
	run run_yamllint
	assert_success
	assert_output --partial "→ yamllint"
	assert_stub_calls "npm run lint:yaml"
}

@test "run_yamllint is a no-op when no YAML or .github paths changed" {
	changed=("README.md" "scripts/lint-changed.sh")
	run run_yamllint
	assert_success
	assert_output ""
	refute_stub_call '^npm '
}

@test "run_docs_gate always runs prettier then markdownlint" {
	run run_docs_gate
	assert_success
	assert_output --partial "prettier (all Markdown)"
	assert_output --partial "markdownlint-cli2 (all Markdown)"
	assert_stub_calls \
		"npx prettier --check **/*.md" \
		"npm run lint:md"
}

@test "run_prettier_other checks changed JSON and JS files" {
	printf '{}\n' >"${SANDBOX}/package.json"
	printf 'void 0;\n' >"${SANDBOX}/app.js"
	cd "${SANDBOX}"
	changed=("package.json" "app.js" "README.md")
	run run_prettier_other
	assert_success
	assert_output --partial "→ prettier"
	assert_stub_call '^npx prettier --check package.json app.js$'
}

@test "run_editorconfig checks existing changed files" {
	printf 'x\n' >"${SANDBOX}/README.md"
	cd "${SANDBOX}"
	changed=("README.md" "missing.txt")
	run run_editorconfig
	assert_success
	assert_output --partial "editorconfig-checker"
	assert_stub_calls "ec README.md"
}

@test "run_axe_fixture constructs the axe command for local HTML" {
	printf '<html></html>\n' >"${SANDBOX}/page.html"
	cd "${SANDBOX}"
	changed=("page.html")
	export CHROMEDRIVER_PATH="${SANDBOX}/chromedriver"
	run run_axe_fixture
	assert_success
	assert_output --partial "axe-core (local HTML via static server)"
	assert_stub_call '^npx --yes serve@14.2.6 -l 8765 --no-clipboard \.$'
	assert_stub_call '^sleep 2$'
	assert_stub_call '^axe --chromedriver-path '"${SANDBOX}"'/chromedriver http://127.0.0.1:8765/page.html --exit$'
}

@test "run_axe_fixture is a no-op when no HTML files changed" {
	changed=("README.md")
	run run_axe_fixture
	assert_success
	assert_output ""
	refute_stub_call '^axe '
}

# --- main / collect_changed_files ------------------------------------------

@test "collect_changed_files drops skipped paths from the git diff" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	mkdir -p src node_modules/pkg .github/scripts
	cp "${REPO_ROOT}/.github/scripts/qc-filter-changed-paths.sh" \
		.github/scripts/
	printf 'src\n' >src/app.js
	printf 'skip\n' >node_modules/pkg/index.js
	git add src/app.js node_modules/pkg/index.js
	git commit -q -m "add files"
	# origin/main still points at the earlier commits from init_git_repo,
	# so origin/main...HEAD includes the new files.
	export LINT_BASE="origin/main"
	collect_changed_files
	assert_equal "${BASE_REF}" "origin/main"
	assert_equal "${changed[*]}" "src/app.js"
}

@test "main exits 0 when no files changed" {
	init_git_repo "${SANDBOX}/repo" main origin
	cd "${SANDBOX}/repo"
	mkdir -p scripts .github/scripts
	cp "${REPO_ROOT}/scripts/lint-changed.sh" scripts/
	cp "${REPO_ROOT}/.github/scripts/qc-filter-changed-paths.sh" \
		.github/scripts/
	# Work tree matches HEAD and origin, so the diff is empty.
	run scripts/lint-changed.sh
	assert_success
	assert_output --partial "No changed files detected (base: origin/main)."
}

@test "sourcing lint-changed.sh does not run main" {
	# setup() already sourced the script; if main had run it would have
	# changed directory to the real repo and printed a changed-files report.
	assert_dir_exists "${SANDBOX}"
	# The functions are defined and callable.
	changed=("README.md")
	run has_pattern 'README'
	assert_success
}
