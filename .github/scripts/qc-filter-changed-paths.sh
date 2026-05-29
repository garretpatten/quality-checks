#!/usr/bin/env bash
# Drop dependency and build-output paths from PR-scoped changed-file lists.
# Reads paths from stdin; prints kept paths to stdout.
set -euo pipefail

qc_should_skip_changed_path() {
	local path="$1"
	case "${path}" in
	node_modules/* | */node_modules/*) return 0 ;;
	vendor/* | */vendor/*) return 0 ;;
	dist/* | */dist/*) return 0 ;;
	build/* | */build/*) return 0 ;;
	coverage/* | */coverage/*) return 0 ;;
	esac
	return 1
}

while IFS= read -r path || [[ -n "${path}" ]]; do
	[[ -z "${path}" ]] && continue
	qc_should_skip_changed_path "${path}" && continue
	printf '%s\n' "${path}"
done
