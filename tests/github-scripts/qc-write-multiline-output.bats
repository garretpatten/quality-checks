#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-write-multiline-output.sh.
# shellcheck disable=SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../.github/scripts/qc-write-multiline-output.sh
	source "${REPO_ROOT}/.github/scripts/qc-write-multiline-output.sh"
	export GITHUB_OUTPUT="${SANDBOX}/github-output"
	: >"${GITHUB_OUTPUT}"
}

teardown() {
	common_teardown
}

# --- qc_multiline_delimiter ------------------------------------------------

@test "qc_multiline_delimiter emits QC_EOF_ followed by 16 hex characters" {
	run qc_multiline_delimiter
	assert_success
	assert_output --regexp '^QC_EOF_[0-9a-f]{16}$'
}

@test "qc_multiline_delimiter returns a different value on each call" {
	run qc_multiline_delimiter
	assert_success
	local first="${output}"
	run qc_multiline_delimiter
	assert_success
	refute_output "${first}"
}

# --- qc_write_multiline_output ---------------------------------------------

@test "qc_write_multiline_output writes a QC_EOF_<hex> delimited block" {
	qc_write_multiline_output files "src/a.js" "src/b.js"
	local delim
	delim="$(sed -n 's/^files<<//p;q' "${GITHUB_OUTPUT}")"
	[[ "${delim}" =~ ^QC_EOF_[0-9a-f]{16}$ ]]
	assert_equal "$(cat "${GITHUB_OUTPUT}")" "$(printf 'files<<%s\nsrc/a.js\nsrc/b.js\n%s\n' "${delim}" "${delim}")"
}

@test "qc_write_multiline_output keeps a path literally named EOF inside the block" {
	qc_write_multiline_output files "EOF" "src/a.js"
	local delim
	delim="$(sed -n 's/^files<<//p;q' "${GITHUB_OUTPUT}")"
	[[ "${delim}" != "EOF" ]]
	assert_equal "$(cat "${GITHUB_OUTPUT}")" "$(printf 'files<<%s\nEOF\nsrc/a.js\n%s\n' "${delim}" "${delim}")"
}

@test "qc_write_multiline_output writes an empty block when there are no values" {
	qc_write_multiline_output files
	local delim
	delim="$(sed -n 's/^files<<//p;q' "${GITHUB_OUTPUT}")"
	[[ "${delim}" =~ ^QC_EOF_[0-9a-f]{16}$ ]]
	assert_equal "$(cat "${GITHUB_OUTPUT}")" "$(printf 'files<<%s\n%s\n' "${delim}" "${delim}")"
}

@test "qc_write_multiline_output uses a fresh delimiter for each name" {
	qc_write_multiline_output remote_urls "https://example.com"
	qc_write_multiline_output html_paths "index.html"
	local delim1 delim2
	delim1="$(sed -n 's/^remote_urls<<//p;q' "${GITHUB_OUTPUT}")"
	delim2="$(sed -n 's/^html_paths<<//p' "${GITHUB_OUTPUT}" | tail -n1)"
	[[ "${delim1}" != "${delim2}" ]]
	assert_equal "$(cat "${GITHUB_OUTPUT}")" "$(printf 'remote_urls<<%s\nhttps://example.com\n%s\nhtml_paths<<%s\nindex.html\n%s\n' "${delim1}" "${delim1}" "${delim2}" "${delim2}")"
}

@test "qc_write_multiline_output regenerates a delimiter that matches a value" {
	local stub_dir="${SANDBOX}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/openssl" <<'SH'
#!/usr/bin/env bash
# First call collides with a value; later calls are unique.
count_file="${STUB_OPENSSL_COUNT}"
n=0
[[ -f "${count_file}" ]] && n="$(cat "${count_file}")"
n=$((n + 1))
printf '%s\n' "${n}" >"${count_file}"
if [[ "${n}" -eq 1 ]]; then
	printf 'deadbeefdeadbeef\n'
else
	printf 'cafebabecafebabe\n'
fi
SH
	chmod +x "${stub_dir}/openssl"
	export STUB_OPENSSL_COUNT="${SANDBOX}/openssl-count"
	# Prepend so this stub wins over the real openssl.
	export PATH="${stub_dir}:${PATH}"

	qc_write_multiline_output files "QC_EOF_deadbeefdeadbeef" "ok.json"

	assert_equal "$(cat "${STUB_OPENSSL_COUNT}")" "2"
	assert_equal "$(cat "${GITHUB_OUTPUT}")" "$(printf 'files<<QC_EOF_cafebabecafebabe\nQC_EOF_deadbeefdeadbeef\nok.json\nQC_EOF_cafebabecafebabe\n')"
}

@test "qc_write_multiline_output fails when GITHUB_OUTPUT is unset" {
	unset GITHUB_OUTPUT
	run qc_write_multiline_output files "src/a.js"
	assert_failure
	assert_output --partial "GITHUB_OUTPUT is not set"
}
