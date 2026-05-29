#!/usr/bin/env bash
# Install @axe-core/cli and a ChromeDriver that matches the runner's Chrome.
# Sets CHROMEDRIVER_PATH (and appends to GITHUB_ENV when set).
set -euo pipefail

npm install -g @axe-core/cli

echo 'Syncing ChromeDriver with installed Chrome (browser-driver-manager)…'
npx --yes browser-driver-manager@2.0.1 install chrome

resolve_chromedriver() {
	local path=""
	path="$(command -v chromedriver 2>/dev/null || true)"
	if [[ -n "${path}" && -x "${path}" ]]; then
		printf '%s' "${path}"
		return
	fi
	path="$(
		find "${HOME}/.browser-driver-manager" /tmp -name chromedriver -type f \
			-perm -111 2>/dev/null | head -1 || true
	)"
	if [[ -n "${path}" && -x "${path}" ]]; then
		printf '%s' "${path}"
		return
	fi
	return 1
}

CHROMEDRIVER_PATH="$(resolve_chromedriver)" || {
	echo 'chromedriver not found after browser-driver-manager install' >&2
	exit 1
}

echo "Chrome: $(google-chrome --version 2>/dev/null || true)"
echo "ChromeDriver: $("${CHROMEDRIVER_PATH}" --version 2>/dev/null || true)"
echo "CHROMEDRIVER_PATH=${CHROMEDRIVER_PATH}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
	echo "CHROMEDRIVER_PATH=${CHROMEDRIVER_PATH}" >>"${GITHUB_ENV}"
fi

export CHROMEDRIVER_PATH
