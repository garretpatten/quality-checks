#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-classify-changed.sh.
# shellcheck disable=SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../.github/scripts/qc-classify-changed.sh
	source "${REPO_ROOT}/.github/scripts/qc-classify-changed.sh"
}

teardown() {
	common_teardown
}

classify_logged() {
	local log="$1"
	shift
	qc_classify_changed "$@" >"${log}"
}

assert_count() {
	local log="$1"
	local list="$2"
	local expected="$3"
	local actual
	actual="$(grep -E "^${list}_count=" "${log}" | cut -d= -f2)"
	assert_equal "${actual}" "${expected}"
}

@test "qc_classify_changed emits zero counts and no heredocs for no paths" {
	local log="${SANDBOX}/out.log"
	classify_logged "${log}"
	assert_equal "$(wc -l <"${log}")" 14
	assert_count "${log}" eslint 0
	assert_count "${log}" actionlint 0
	assert_count "${log}" editorconfig 0
	if grep -q '_files<<' "${log}"; then
		fail 'no paths should emit no heredoc blocks'
	fi
}

@test "qc_classify_changed routes JavaScript to eslint and prettier" {
	local log="${SANDBOX}/out.log"
	classify_logged "${log}" src/app.ts src/lib.mjs
	assert_count "${log}" eslint 2
	assert_count "${log}" prettier 2
	assert_count "${log}" editorconfig 2
	assert_file_contains "${log}" 'src/app.ts'
	assert_file_contains "${log}" 'src/lib.mjs'
	assert_count "${log}" yaml 0
	assert_count "${log}" shell 0
	assert_count "${log}" ruff 0
	assert_count "${log}" toml 0
	assert_count "${log}" docker 0
	assert_count "${log}" go 0
	assert_count "${log}" actionlint 0
	assert_count "${log}" stylua 0
	assert_count "${log}" jq 0
	assert_count "${log}" prose 0
}

@test "qc_classify_changed routes each language to its tools" {
	local log="${SANDBOX}/out.log"
	classify_logged "${log}" \
		README.md \
		notes.markdown \
		.github/workflows/ci.yaml \
		dep.yml \
		run.sh \
		main.py \
		app.toml \
		Dockerfile \
		api/Dockerfile.dev \
		graphql.dockerfile \
		cmd/main.go \
		init.lua \
		package.json \
		styles.scss \
		docs/guide.html \
		notes.txt \
		docs/manual.rst \
		LICENSE \
		vendor/lib/COPYING \
		NOTICE \
		slides.adoc
	assert_count "${log}" eslint 0
	assert_count "${log}" prettier 4 # md, markdown, json, scss
	assert_count "${log}" markdownlint 2
	assert_count "${log}" yaml 2
	assert_count "${log}" actionlint 1
	assert_count "${log}" shell 1
	assert_count "${log}" ruff 1
	assert_count "${log}" toml 1
	assert_count "${log}" docker 3
	assert_count "${log}" go 1
	assert_count "${log}" stylua 1
	assert_count "${log}" jq 1
	assert_count "${log}" prose 9 # md, markdown, html, txt, rst, LICENSE, COPYING, NOTICE, adoc
	assert_count "${log}" editorconfig 21
}

@test "qc_classify_changed detects extensionless scripts by shebang" {
	mkdir -p "${SANDBOX}/bin"
	printf '#!/usr/bin/env bash\nset -euo pipefail\n' \
		>"${SANDBOX}/bin/build"
	printf '#!/bin/sh\necho hi\n' >"${SANDBOX}/hook"
	printf 'plain text\n' >"${SANDBOX}/README"
	local log="${SANDBOX}/out.log"
	cd "${SANDBOX}"
	classify_logged "${log}" bin/build hook README
	assert_count "${log}" shell 2
	assert_file_contains "${log}" 'bin/build'
	assert_file_contains "${log}" 'hook'
}

@test "qc_classify_changed emits one heredoc per non-empty list" {
	local log="${SANDBOX}/out.log"
	classify_logged "${log}" main.py README.md
	local heredocs
	heredocs="$(grep -c '_files<<' "${log}")"
	# ruff (main.py); markdownlint, prettier, prose, editorconfig (README.md)
	assert_equal "${heredocs}" 5
}
