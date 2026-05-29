#!/usr/bin/env bash
# Resolve typos CLI config flags for the current repository.
# Sets TYPOS_CLI_ARGS to an array name you can expand: typos "${TYPOS_CLI_ARGS[@]}" …
# Optional: QC_TYPOS_CONFIG env var (or workflow input) for a custom config path.
set -euo pipefail

TYPOS_CLI_ARGS=()

if [[ -n "${QC_TYPOS_CONFIG:-}" ]]; then
	if [[ -f "${QC_TYPOS_CONFIG}" ]]; then
		TYPOS_CLI_ARGS=(--config "${QC_TYPOS_CONFIG}")
	else
		echo "typos config not found: ${QC_TYPOS_CONFIG}" >&2
		exit 1
	fi
elif [[ -f typos.toml ]]; then
	TYPOS_CLI_ARGS=(--config typos.toml)
elif [[ -f _typos.toml ]]; then
	TYPOS_CLI_ARGS=(--config _typos.toml)
elif [[ -f .typos.toml ]]; then
	TYPOS_CLI_ARGS=(--config .typos.toml)
fi

export TYPOS_CLI_ARGS
