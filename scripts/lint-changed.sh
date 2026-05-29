#!/usr/bin/env bash
# Run linters that match files changed in the working tree or vs the default branch.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

resolve_base() {
	if [[ -n "${LINT_BASE:-}" ]]; then
		echo "${LINT_BASE}"
		return
	fi
	git fetch origin main master 2>/dev/null || true
	if git show-ref --verify --quiet refs/remotes/origin/main; then
		echo 'origin/main'
	elif git show-ref --verify --quiet refs/remotes/origin/master; then
		echo 'origin/master'
	else
		echo 'HEAD~1'
	fi
}

BASE_REF="$(resolve_base)"

mapfile -t changed < <(
	{
		git diff --name-only --diff-filter=ACMR "${BASE_REF}"...HEAD 2>/dev/null || true
		git diff --name-only
		git diff --cached --name-only
	} | sed '/^$/d' | sort -u
)

if [[ ${#changed[@]} -eq 0 ]]; then
	echo "No changed files detected (base: ${BASE_REF})."
	exit 0
fi

echo "Changed files (base: ${BASE_REF}):"
printf '  %s\n' "${changed[@]}"

has_pattern() {
	local pattern="$1"
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" =~ ${pattern} ]] && return 0
	done
	return 1
}

filter_existing() {
	local file
	for file in "$@"; do
		[[ -f "${file}" ]] && printf '%s\n' "${file}"
	done
}

# Required on every run: Prettier then markdownlint on all Markdown (CI parity).
run_docs_gate() {
	echo '→ prettier (all Markdown)'
	npx prettier --check "**/*.md"
	echo '→ markdownlint-cli2 (all Markdown)'
	npm run lint:md
}

run_yamllint() {
	has_pattern '\.(ya?ml)$' || has_pattern '^\.github/' || return 0
	echo '→ yamllint'
	npm run lint:yaml
}

run_actionlint() {
	has_pattern '^\.github/workflows/.*\.ya?ml$' || return 0
	echo '→ actionlint'
	npm run lint:workflows
}

run_shfmt() {
	local -a files=()
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" == *.sh ]] && files+=("${file}")
	done
	mapfile -t files < <(filter_existing "${files[@]}")
	[[ ${#files[@]} -eq 0 ]] && return 0
	if ! command -v shfmt >/dev/null 2>&1; then
		echo '→ shfmt (skipped — install: brew install shfmt)'
		return 0
	fi
	echo '→ shfmt'
	shfmt -d "${files[@]}"
}

run_shellcheck() {
	local -a files=()
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" == *.sh ]] && files+=("${file}")
	done
	mapfile -t files < <(filter_existing "${files[@]}")
	[[ ${#files[@]} -eq 0 ]] && return 0
	if ! command -v shellcheck >/dev/null 2>&1; then
		echo '→ shellcheck (skipped — install: brew install shellcheck)'
		return 0
	fi
	echo '→ shellcheck'
	shellcheck "${files[@]}"
}

run_typos() {
	local -a files=()
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" =~ \.(md|markdown|txt|text|rst|adoc|asciidoc|html)$ ]] && files+=("${file}")
		[[ "${file}" =~ (^|/)(LICENSE|COPYING|NOTICE)(\.[^/]+)?$ ]] && files+=("${file}")
	done
	mapfile -t files < <(filter_existing "${files[@]}" | sort -u)
	[[ ${#files[@]} -eq 0 ]] && return 0
	if ! command -v typos >/dev/null 2>&1; then
		echo '→ typos (skipped — install: brew install typos-cli)'
		return 0
	fi
	echo '→ typos'
	# shellcheck source=.github/scripts/qc-typos-args.sh
	source .github/scripts/qc-typos-args.sh
	if [[ ${#TYPOS_CLI_ARGS[@]} -gt 0 ]]; then
		echo "  config: ${TYPOS_CLI_ARGS[1]}"
	fi
	typos "${TYPOS_CLI_ARGS[@]}" "${files[@]}"
}

run_editorconfig() {
	if ! command -v ec >/dev/null 2>&1; then
		echo '→ editorconfig-checker (skipped — install ec from editorconfig-checker releases)'
		return 0
	fi
	local -a files=()
	mapfile -t files < <(filter_existing "${changed[@]}")
	[[ ${#files[@]} -eq 0 ]] && return 0
	echo '→ editorconfig-checker'
	ec "${files[@]}"
}

run_axe_fixture() {
	local -a files=()
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" == *.html ]] && files+=("${file}")
	done
	[[ ${#files[@]} -eq 0 ]] && return 0
	if ! command -v axe >/dev/null 2>&1; then
		echo '→ axe-core (skipped — install: npm install -g @axe-core/cli)'
		return 0
	fi
	if [[ -z "${CHROMEDRIVER_PATH:-}" ]]; then
		if [[ -f .github/scripts/qc-axe-setup.sh ]]; then
			# shellcheck source=.github/scripts/qc-axe-setup.sh
			source .github/scripts/qc-axe-setup.sh
		else
			echo '→ axe-core (skipped — run: npx browser-driver-manager install chrome)'
			return 0
		fi
	fi
	echo '→ axe-core (local HTML via static server)'
	npx --yes serve@14.2.6 -l 8765 --no-clipboard . &
	server_pid=$!
	trap 'kill "${server_pid}" 2>/dev/null || true' EXIT
	sleep 2
	local path
	for path in "${files[@]}"; do
		[[ -f "${path}" ]] || continue
		axe --chromedriver-path "${CHROMEDRIVER_PATH}" \
			"http://127.0.0.1:8765/${path}" --exit
	done
}

# Prettier on non-markdown files it supports (workflows are YAML — yamllint handles those)
run_prettier_other() {
	local -a files=()
	local file
	for file in "${changed[@]}"; do
		[[ "${file}" =~ \.(json|css|scss|js|jsx|ts|tsx)$ ]] && files+=("${file}")
	done
	mapfile -t files < <(filter_existing "${files[@]}")
	[[ ${#files[@]} -eq 0 ]] && return 0
	echo '→ prettier'
	npx prettier --check "${files[@]}"
}

main() {
	if [[ ! -d node_modules ]]; then
		echo '→ npm install'
		npm install
	fi

	run_prettier_other
	run_yamllint
	run_actionlint
	run_shfmt
	run_shellcheck
	run_typos
	run_editorconfig
	run_axe_fixture
	run_docs_gate

	echo 'All applicable linters passed.'
}

main "$@"
