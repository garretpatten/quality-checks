#!/usr/bin/env bash
# Write a multiline value to $GITHUB_OUTPUT with a unique heredoc delimiter
# so a path literally named EOF cannot close the block early (issue #37 M3).
set -euo pipefail

qc_multiline_delimiter() {
	printf 'QC_EOF_%s\n' "$(openssl rand -hex 8)"
}

# Usage: qc_write_multiline_output <name> [values...]
# Appends a GitHub Actions multiline output to $GITHUB_OUTPUT.
qc_write_multiline_output() {
	local name="${1:?output name is required}"
	shift
	local delim collision value

	while true; do
		delim="$(qc_multiline_delimiter)"
		collision=0
		for value in "$@"; do
			if [[ "${value}" == "${delim}" ]]; then
				collision=1
				break
			fi
		done
		[[ "${collision}" -eq 0 ]] && break
	done

	{
		printf '%s<<%s\n' "${name}" "${delim}"
		if [[ $# -gt 0 ]]; then
			printf '%s\n' "$@"
		fi
		printf '%s\n' "${delim}"
	} >>"${GITHUB_OUTPUT:?GITHUB_OUTPUT is not set}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	qc_write_multiline_output "$@"
fi
