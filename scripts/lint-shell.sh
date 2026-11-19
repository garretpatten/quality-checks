#!/usr/bin/env bash
# Format-check and ShellCheck every shell script in this repository,
# including bats tests, helpers, and stubs.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

shopt -s globstar nullglob

files=(.github/scripts/*.sh scripts/*.sh)
if [[ -d tests ]]; then
	files+=(tests/**/*.bats tests/**/*.bash tests/**/*.sh)
	if [[ -d tests/stubs ]]; then
		for stub in tests/stubs/*; do
			[[ -f "${stub}" ]] && files+=("${stub}")
		done
	fi
fi

if [[ ${#files[@]} -eq 0 ]]; then
	echo 'No shell files to lint.'
	exit 0
fi

shfmt -d "${files[@]}"
shellcheck -x "${files[@]}"
