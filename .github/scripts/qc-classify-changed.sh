#!/usr/bin/env bash
# Classify changed paths into per-tool lists for the detect job
# (issue #37 S1). Prints GITHUB_OUTPUT fragments to stdout — one
# "<list>_count=n" line per list plus a heredoc block for "<list>_files"
# when the list is non-empty. The caller redirects stdout into
# $GITHUB_OUTPUT.
#
# Usage: qc_classify_changed [changed-path...]
# Lists (consumers in parentheses):
#   eslint_files        ESLint
#   prettier_files      Prettier
#   markdownlint_files  markdownlint-cli2
#   yaml_files          yamllint
#   shell_files         ShellCheck and shfmt (extensions + shebang detect)
#   ruff_files          Ruff
#   toml_files          Taplo
#   docker_files        Hadolint
#   go_files            golangci-lint
#   actionlint_files    actionlint (.github/workflows YAML)
#   stylua_files        StyLua
#   jq_files            jq
#   prose_files         typos (prose + LICENSE/COPYING/NOTICE)
#   editorconfig_files  editorconfig-checker (every changed file)
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=qc-write-multiline-output.sh
source "${script_dir}/qc-write-multiline-output.sh"

qc_classify_changed() {
	local -a changed=("$@")

	local -a eslint_files=() prettier_files=() markdownlint_files=()
	local -a yaml_files=() shell_files=() ruff_files=() toml_files=()
	local -a docker_files=() go_files=() actionlint_files=()
	local -a stylua_files=() jq_files=()
	local -a prose_files=() editorconfig_files=()

	local file
	for file in ${changed[@]+"${changed[@]}"}; do
		editorconfig_files+=("${file}")
		case "${file}" in
		*.js | *.jsx | *.ts | *.tsx | *.mjs | *.cjs | *.mts | *.cts)
			eslint_files+=("${file}")
			prettier_files+=("${file}")
			;;
		*.json)
			jq_files+=("${file}")
			prettier_files+=("${file}")
			;;
		*.md | *.markdown)
			markdownlint_files+=("${file}")
			prettier_files+=("${file}")
			prose_files+=("${file}")
			;;
		*.yaml | *.yml) yaml_files+=("${file}") ;;
		*.sh | *.bash | *.zsh) shell_files+=("${file}") ;;
		*.py | *.pyw) ruff_files+=("${file}") ;;
		*.toml) toml_files+=("${file}") ;;
		*.go) go_files+=("${file}") ;;
		*.lua) stylua_files+=("${file}") ;;
		*.css | *.scss) prettier_files+=("${file}") ;;
		*.html | *.htm | *.txt | *.text | *.rst | *.adoc | *.asciidoc)
			prose_files+=("${file}")
			;;
		*.dockerfile | *.Dockerfile) docker_files+=("${file}") ;;
		[Dd]ockerfile | */[Dd]ockerfile | [Dd]ockerfile.* | \
			*/[Dd]ockerfile.*) docker_files+=("${file}") ;;
		LICENSE | LICENSE.* | */LICENSE | */LICENSE.* | \
			COPYING | COPYING.* | */COPYING | */COPYING.* | \
			NOTICE | NOTICE.* | */NOTICE | */NOTICE.*)
			prose_files+=("${file}")
			;;
		esac
	done

	# Extensionless scripts (bin/*, git hooks, ...) are detected by their
	# shebang so ShellCheck and shfmt cover them too (issue #37 L1).
	for file in ${changed[@]+"${changed[@]}"}; do
		case "${file}" in
		*.sh | *.bash | *.zsh) continue ;;
		esac
		local first_line
		first_line="$(head -n 1 -- "${file}" 2>/dev/null || true)"
		case "${first_line}" in
		'#!'*'bash'* | '#!'*'zsh'* | '#!'*'/sh'* | '#!'*'env sh'*)
			shell_files+=("${file}")
			;;
		esac
	done

	# Workflow YAML gets both actionlint (schema/expressions) and yamllint
	# (style), matching the detection mapping in README.
	for file in ${changed[@]+"${changed[@]}"}; do
		case "${file}" in
		.github/workflows/*.yaml | .github/workflows/*.yml)
			actionlint_files+=("${file}")
			;;
		esac
	done

	local tool delim
	for tool in eslint prettier markdownlint yaml shell ruff toml docker \
		go actionlint stylua jq prose editorconfig; do
		local -n files="${tool}_files"
		printf '%s_count=%s\n' "${tool}" "${#files[@]}"
		if [[ ${#files[@]} -gt 0 ]]; then
			delim="$(qc_multiline_delimiter)"
			printf '%s_files<<%s\n' "${tool}" "${delim}"
			printf '%s\n' "${files[@]}"
			printf '%s\n' "${delim}"
		fi
		unset -n files
	done
}

# Executed directly: classify paths given as arguments.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	qc_classify_changed "$@"
fi
