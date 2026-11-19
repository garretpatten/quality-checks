#!/usr/bin/env bats
# Unit tests for .github/scripts/qc-axe-setup.sh.
# shellcheck disable=SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	# shellcheck source=../../.github/scripts/qc-axe-setup.sh
	source "${REPO_ROOT}/.github/scripts/qc-axe-setup.sh"
	# Keep the template off the name "chromedriver" so find /tmp does not
	# pick it up (SANDBOX lives under /tmp).
	CHROMEDRIVER_STUB="${SANDBOX}/chromedriver.stub"
	printf '#!/usr/bin/env bash\nprintf "ChromeDriver 1.0 (stub)\\n"\n' \
		>"${CHROMEDRIVER_STUB}"
	chmod +x "${CHROMEDRIVER_STUB}"
	TMP_CHROMEDRIVER_DIR=""
}

teardown() {
	if [[ -n "${TMP_CHROMEDRIVER_DIR:-}" && -d "${TMP_CHROMEDRIVER_DIR}" ]]; then
		rm -rf "${TMP_CHROMEDRIVER_DIR}"
	fi
	common_teardown
}

host_tmp_has_chromedriver() {
	# Ignore leftover trees from this suite; they are cleaned in teardown.
	find /tmp -name chromedriver -type f -perm -111 2>/dev/null |
		grep -v '/qc-chromedriver\.' |
		grep -q .
}

@test "resolve_chromedriver returns a chromedriver on PATH" {
	mkdir -p "${SANDBOX}/bin"
	cp "${CHROMEDRIVER_STUB}" "${SANDBOX}/bin/chromedriver"
	PATH="${SANDBOX}/bin:${PATH}"
	run resolve_chromedriver
	assert_success
	# PATH should win even though the file also sits under /tmp (SANDBOX).
	assert_output "${SANDBOX}/bin/chromedriver"
}

@test "resolve_chromedriver falls back to ~/.browser-driver-manager" {
	mkdir -p "${HOME}/.browser-driver-manager/drivers"
	cp "${CHROMEDRIVER_STUB}" \
		"${HOME}/.browser-driver-manager/drivers/chromedriver"
	PATH="$(path_without_command chromedriver)"
	run resolve_chromedriver
	assert_success
	assert_output "${HOME}/.browser-driver-manager/drivers/chromedriver"
}

@test "resolve_chromedriver falls back to a chromedriver under /tmp" {
	TMP_CHROMEDRIVER_DIR="$(mktemp -d /tmp/qc-chromedriver.XXXXXX)"
	cp "${CHROMEDRIVER_STUB}" "${TMP_CHROMEDRIVER_DIR}/chromedriver"
	chmod +x "${TMP_CHROMEDRIVER_DIR}/chromedriver"
	PATH="$(path_without_command chromedriver)"
	run resolve_chromedriver
	assert_success
	assert_file_executable "${output}"
	assert_equal "$(basename "${output}")" "chromedriver"
}

@test "resolve_chromedriver fails when no chromedriver exists in known locations" {
	if host_tmp_has_chromedriver; then
		skip "host /tmp already has a chromedriver"
	fi
	PATH="$(path_without_command chromedriver)"
	run resolve_chromedriver
	assert_failure
	assert_output ""
}

@test "qc_axe_setup installs axe, syncs ChromeDriver, and writes GITHUB_ENV" {
	mkdir -p "${SANDBOX}/bin"
	cp "${CHROMEDRIVER_STUB}" "${SANDBOX}/bin/chromedriver"
	PATH="${SANDBOX}/bin:${PATH}"
	export GITHUB_ENV="${SANDBOX}/github.env"
	: >"${GITHUB_ENV}"

	run qc_axe_setup
	assert_success
	assert_output --partial "CHROMEDRIVER_PATH=${SANDBOX}/bin/chromedriver"
	assert_file_contains "${GITHUB_ENV}" \
		"CHROMEDRIVER_PATH=${SANDBOX}/bin/chromedriver"
	assert_stub_call '^npm install -g @axe-core/cli$'
	assert_stub_call '^npx --yes browser-driver-manager@2.0.1 install chrome$'
	assert_stub_call '^google-chrome '
}

@test "qc_axe_setup fails when chromedriver is still missing after install" {
	if host_tmp_has_chromedriver; then
		skip "host /tmp already has a chromedriver"
	fi
	PATH="$(path_without_command chromedriver)"
	run --separate-stderr qc_axe_setup
	assert_failure 1
	# shellcheck disable=SC2154 # $stderr is set by run --separate-stderr
	assert_equal "${stderr}" \
		"chromedriver not found after browser-driver-manager install"
}
