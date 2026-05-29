#!/usr/bin/env bash
# Install a pinned actionlint binary via the upstream download script.
# Sets ACTIONLINT_BIN and prepends the install dir to PATH (GitHub Actions).
set -euo pipefail

ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-1.7.12}"
install_dir="${ACTIONLINT_INSTALL_DIR:-${RUNNER_TEMP:-/tmp}/actionlint}"

mkdir -p "${install_dir}"
script_url="https://raw.githubusercontent.com/rhysd/actionlint/v${ACTIONLINT_VERSION}/scripts/download-actionlint.bash"
bash <(curl -fsSL "${script_url}") "${ACTIONLINT_VERSION}" "${install_dir}"

ACTIONLINT_BIN="${install_dir}/actionlint"
export ACTIONLINT_BIN

if [[ -n "${GITHUB_PATH:-}" ]]; then
	echo "${install_dir}" >>"${GITHUB_PATH}"
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
	echo "ACTIONLINT_BIN=${ACTIONLINT_BIN}" >>"${GITHUB_ENV}"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
	echo "executable=${ACTIONLINT_BIN}" >>"${GITHUB_OUTPUT}"
fi

"${ACTIONLINT_BIN}" -version
